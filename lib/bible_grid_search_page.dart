import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_leaderboard_page.dart';

class BibleGridSearchPage extends StatefulWidget {
  const BibleGridSearchPage({super.key});
  @override
  State<BibleGridSearchPage> createState() => _BibleGridSearchPageState();
}

class _Puzzle {
  const _Puzzle(this.theme, this.words, this.grid, this.paths, this.number);
  final String theme;
  final List<String> words;
  final List<List<String>> grid;
  final Map<String, List<int>> paths;
  final int number;
}

class _BibleGridSearchPageState extends State<BibleGridSearchPage> {
  static const int size = 12;
  static const blue = Color(0xFF0757C8);
  static const gold = Color(0xFFFFC928);
  static const levelKey = 'ngn_bible_grid_search_level';
  static const bestKey = 'ngn_bible_grid_search_best';
  static const queueKey = 'ngn_game_score_queue';

  static const themes = <(String, String)>[
    ('Creation','LIGHT EARTH WATER STARS TREES BEAST SUN MOON SEAS SEED'),
    ('Eden','ADAM EVE EDEN SNAKE FRUIT DUST GARDEN TREE LIFE RIVER'),
    ('Noah','NOAH ARK DOVE RAVEN RAIN BOW FLOOD FAITH ALTAR COVENANT'),
    ('Abraham','ABRAM SARAH ISAAC ALTAR FAITH PROMISE LOT HAGAR BLESS COVENANT'),
    ('Jacob','JACOB ESAU LEAH RACHEL LADDER ISRAEL BETHEL DREAM STONE ANGEL'),
    ('Joseph','JOSEPH DREAM COAT EGYPT PHARAOH GRAIN JUDAH BENJAMIN PRISON WISDOM'),
    ('Moses','MOSES BUSH STAFF AARON NILE EXODUS PLAGUE MANNA SINAI TABLETS'),
    ('Wilderness','MANNA QUAIL ROCK CLOUD FIRE SINAI MOSES JOSHUA CALEB TENT'),
    ('Jericho','JOSHUA JERICHO RAHAB SPIES WALLS TRUMPET JORDAN CANAAN PROMISE COURAGE'),
    ('Ruth','RUTH NAOMI BOAZ WHEAT FIELD LOYAL MOAB DAVID HARVEST KINSMAN'),
    ('David','DAVID SAUL SHEEP SLING STONE GIANT GOLIATH CROWN PSALM SHEPHERD'),
    ('Solomon','SOLOMON WISDOM TEMPLE QUEEN GOLD PROVERB THRONE KINGDOM PRAYER PEACE'),
    ('Psalms','PRAISE PSALM SING HEART JOY TRUST MERCY GLORY WORSHIP SONG'),
    ('Prophets','ELIJAH ELISHA FIRE RAIN MANTLE JORDAN PROPHET HEAVEN PRAYER ALTAR'),
    ('Daniel','DANIEL LIONS PRAY KING FAITH BABYLON DREAM ANGEL VISION WISDOM'),
    ('Jonah','JONAH FISH SHIP STORM NINEVEH PRAY MERCY SAILOR SEA PROPHET'),
    ('Jesus','JESUS MARY JOSEPH MANGER ANGEL STAR BETHLEHEM SHEPHERD MAGI SAVIOUR'),
    ('Jesus’ teachings','LOVE PRAY MERCY TRUTH SERVE GIVE FAITH GRACE PEACE KINGDOM'),
    ('Jesus’ miracles','WATER WINE BREAD FISH BLIND LEPER HEAL TOUCH MIRACLE POWER'),
    ('Disciples','PETER JOHN JAMES THOMAS ANDREW JUDAS PHILIP MATTHEW SIMON BARTHOLOMEW'),
  ];

  static final List<_Puzzle> levels = _makeLevels();
  static List<_Puzzle> _makeLevels() {
    final result = <_Puzzle>[];
    for (var t = 0; t < themes.length; t++) {
      final pair = themes[t];
      final sourceWords = pair.$2.split(' ');
      final combos = <List<String>>[];
      void pick(int start, List<String> chosen) {
        if (chosen.length == 6) { combos.add(List.of(chosen)); return; }
        for (var i = start; i <= sourceWords.length - (6 - chosen.length); i++) {
          chosen.add(sourceWords[i]); pick(i + 1, chosen); chosen.removeLast();
        }
      }
      pick(0, []);
      for (var v = 0; v < 50; v++) {
        result.add(_makePuzzle(t * 50 + v + 1, pair.$1, combos[(v * 3) % combos.length]));
      }
    }
    return result;
  }

  static _Puzzle _makePuzzle(int number, String theme, List<String> words) {
    final random = Random(number * 7919);
    final grid = List.generate(size, (_) => List.filled(size, ''));
    final paths = <String, List<int>>{};
    const dirs = <(int,int)>[(0,1),(1,0),(1,1),(1,-1),(0,-1),(-1,0),(-1,-1),(-1,1)];
    for (final word in words) {
      var done = false;
      final shuffled = List<(int,int)>.of(dirs)..shuffle(random);
      for (var attempt = 0; attempt < 1200 && !done; attempt++) {
        final d = shuffled[attempt % shuffled.length];
        final r = random.nextInt(size), c = random.nextInt(size);
        final er = r + d.$1 * (word.length - 1), ec = c + d.$2 * (word.length - 1);
        if (er < 0 || er >= size || ec < 0 || ec >= size) continue;
        var fits = true;
        for (var i = 0; i < word.length; i++) {
          final old = grid[r + d.$1 * i][c + d.$2 * i];
          if (old.isNotEmpty && old != word[i]) { fits = false; break; }
        }
        if (!fits) continue;
        final path = <int>[];
        for (var i = 0; i < word.length; i++) {
          final rr = r + d.$1 * i, cc = c + d.$2 * i;
          grid[rr][cc] = word[i]; path.add(rr * size + cc);
        }
        paths[word] = path; done = true;
      }
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c].isEmpty) grid[r][c] = alphabet[random.nextInt(alphabet.length)];
      }
    }
    return _Puzzle(theme, List.unmodifiable(words), grid, paths, number);
  }

  int index = 0, score = 0, best = 0;
  bool loading = true, submitted = false;
  String? message;
  late _Puzzle puzzle;
  int? dragStart;
  List<int> selection = [];
  final Set<String> found = {};
  final Set<int> foundCells = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    index = (p.getInt(levelKey) ?? 0).clamp(0, levels.length - 1).toInt();
    best = p.getInt(bestKey) ?? 0;
    _reset();
    if (mounted) setState(() => loading = false);
    _syncScores();
  }

  void _reset() {
    puzzle = levels[index]; found.clear(); foundCells.clear();
    selection = []; dragStart = null; message = null; submitted = false;
  }

  void _track(Offset pos, double cell) {
    final c = (pos.dx / cell).floor().clamp(0, size - 1).toInt();
    final r = (pos.dy / cell).floor().clamp(0, size - 1).toInt();
    final end = r * size + c;
    if (dragStart == null) { dragStart = end; selection = [end]; return; }
    final sr = dragStart! ~/ size, sc = dragStart! % size;
    final dr = r - sr, dc = c - sc;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return;
    final steps = max(dr.abs(), dc.abs());
    final vr = steps == 0 ? 0 : dr ~/ steps;
    final vc = steps == 0 ? 0 : dc ~/ steps;
    selection = List.generate(steps + 1, (i) => (sr + vr * i) * size + sc + vc * i);
  }

  String get selectedWord => selection.map((i) => puzzle.grid[i ~/ size][i % size]).join();

  void _finish() {
    if (selection.isEmpty) return;
    final word = selectedWord, reverse = selectedWord.split('').reversed.join();
    String? match;
    for (final candidate in puzzle.words) {
      if (!found.contains(candidate) && (candidate == word || candidate == reverse)) {
        match = candidate;
        break;
      }
    }
    if (match != null) {
      final foundWord = match;
      setState(() {
        found.add(foundWord); foundCells.addAll(puzzle.paths[foundWord] ?? selection);
        score += foundWord.length * 10; message = 'Great find: ' + foundWord + '  +' + (foundWord.length * 10).toString() + ' points';
      });
      if (found.length == puzzle.words.length) _complete();
    } else {
      setState(() => message = 'Not quite. Keep looking in another direction.');
    }
    setState(() { selection = []; dragStart = null; });
  }

  Future<void> _complete() async {
    final p = await SharedPreferences.getInstance();
    best = max(best, score);
    await p.setInt(bestKey, best);
    await _submitScore();
    if (mounted) setState(() => message = 'LEVEL COMPLETE! You found every word.');
  }

  Future<void> _next() async {
    if (index == levels.length - 1) { setState(() => message = 'You completed all 1,000 levels!'); return; }
    index++;
    final p = await SharedPreferences.getInstance();
    await p.setInt(levelKey, index);
    if (mounted) setState(_reset);
  }

  Future<void> _submitScore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || submitted) return;
    submitted = true;
    try {
      await Supabase.instance.client.from('game_scores').insert({'user_id': user.id, 'game_id': 'bible_grid_search', 'score': score});
    } catch (_) {
      final p = await SharedPreferences.getInstance();
      final q = p.getStringList(queueKey) ?? [];
      q.add('bible_grid_search|' + score.toString());
      await p.setStringList(queueKey, q);
    }
  }

  Future<void> _syncScores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final p = await SharedPreferences.getInstance();
    final q = p.getStringList(queueKey) ?? [];
    final keep = <String>[];
    for (final item in q) {
      final parts = item.split('|');
      if (parts.length != 2) continue;
      try {
        await Supabase.instance.client.from('game_scores').insert({'user_id': user.id, 'game_id': parts[0], 'score': int.parse(parts[1])});
      } catch (_) { keep.add(item); }
    }
    await p.setStringList(queueKey, keep);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final complete = found.length == puzzle.words.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Word Search Puzzle'), actions: [
        IconButton(tooltip: 'Leaderboard', icon: const Icon(Icons.leaderboard_rounded),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLeaderboardPage(gameId: 'bible_grid_search', gameTitle: 'Word Search Puzzle')))),
      ]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [blue, Color(0xFF12356D), Color(0xFF1684D8)]),
          borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.auto_awesome_rounded, color: gold), SizedBox(width: 8),
              Expanded(child: Text('SCRIPTURE WORD HUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16), SizedBox(width: 4),
              Text('OFFLINE', style: TextStyle(color: Colors.white70, fontSize: 10))]),
            const SizedBox(height: 12),
            Text('Level ' + puzzle.number.toString() + ' of 1,000', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
            Text(puzzle.theme + '  •  Score: ' + score.toString() + '  •  Best: ' + best.toString(), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
              value: found.length / puzzle.words.length, minHeight: 8, backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(gold))),
          ])),
        const SizedBox(height: 14),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(
          padding: const EdgeInsets.all(12), child: Column(children: [
            Row(children: [const Icon(Icons.touch_app_rounded, color: blue), const SizedBox(width: 8),
              const Expanded(child: Text('Find the hidden words', style: TextStyle(fontWeight: FontWeight.w900))),
              Text(found.length.toString() + '/' + puzzle.words.length.toString(), style: const TextStyle(color: blue, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 5),
            Text('Drag across a word in a straight line. Words can go forwards, backwards, vertically or diagonally.',
              style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final side = constraints.maxWidth, cell = side / size;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => setState(() { dragStart = null; _track(d.localPosition, cell); }),
                onPanUpdate: (d) => setState(() => _track(d.localPosition, cell)),
                onPanEnd: (_) => _finish(),
                child: Container(width: side, height: side, padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: dark ? const Color(0xFF0D1A2D) : const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(14), border: Border.all(color: blue.withValues(alpha: .25))),
                  child: Column(children: List.generate(size, (r) => Expanded(child: Row(children: List.generate(size, (c) {
                    final n = r * size + c, isFound = foundCells.contains(n), isSelected = selection.contains(n);
                    return Expanded(child: Container(margin: const EdgeInsets.all(1), alignment: Alignment.center,
                      decoration: BoxDecoration(color: isFound ? const Color(0xFF19A66A).withValues(alpha: .22)
                        : isSelected ? gold.withValues(alpha: .65) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4)),
                      child: FittedBox(child: Text(puzzle.grid[r][c], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                        color: isFound ? const Color(0xFF148451) : (dark ? Colors.white : const Color(0xFF12356D))))));
                  }))))),
                ),
              );
            }),
          ]))),
        const SizedBox(height: 14),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: Padding(
          padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('WORDS TO FIND', style: TextStyle(color: blue, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: puzzle.words.map((word) {
              final done = found.contains(word);
              return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: done ? const Color(0xFF19A66A).withValues(alpha: .13)
                  : (dark ? Colors.white10 : const Color(0xFFFFF6D9)),
                  borderRadius: BorderRadius.circular(30), border: Border.all(color: done ? const Color(0xFF19A66A) : gold)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (done) const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF19A66A)),
                  if (done) const SizedBox(width: 5),
                  Text(word, style: TextStyle(fontWeight: FontWeight.w900, decoration: done ? TextDecoration.lineThrough : null)),
                ]));
            }).toList()),
          ]))),
        if (message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(message!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800,
            color: complete ? const Color(0xFF19A66A) : blue))),
        if (complete) FilledButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(index == levels.length - 1 ? 'Finish all levels' : 'Next level')),
        const SizedBox(height: 8),
        Text('Progress is saved on this device. This game works offline.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : Colors.black54)),
      ])),
    );
  }
}
