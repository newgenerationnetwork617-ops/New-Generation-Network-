import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bible_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_leaderboard_page.dart';

class BibleGridSearchPage extends StatefulWidget {
  const BibleGridSearchPage({super.key});

  @override
  State<BibleGridSearchPage> createState() => _BibleGridSearchPageState();
}

class _PuzzlePack {
  const _PuzzlePack(this.category, this.theme, this.words, {this.prompt = '', this.reference = ''});
  final String category;
  final String theme;
  final String words;
  final String prompt;
  final String reference;
}

class _Puzzle {
  const _Puzzle({
    required this.category,
    required this.theme,
    required this.words,
    required this.grid,
    required this.paths,
    required this.prompt,
    required this.reference,
  });

  final String category;
  final String theme;
  final List<String> words;
  final List<List<String>> grid;
  final Map<String, List<int>> paths;
  final String prompt;
  final String reference;
}

class _PuzzleCategory {
  const _PuzzleCategory(this.name, this.description, this.icon, this.tint);
  final String name;
  final String description;
  final IconData icon;
  final Color tint;
}

class _BibleGridSearchPageState extends State<BibleGridSearchPage> {
  static const int size = 12;
  static const blue = Color(0xFF073B8C);
  static const gold = Color(0xFFD4AF37);
  static const bestKey = 'ngn_bible_grid_search_best';
  static const queueKey = 'ngn_game_score_queue';
  static const cacheKey = 'ngn_word_search_downloaded_puzzles_v2';

  static const categories = <_PuzzleCategory>[
    _PuzzleCategory('Bible Names', 'Meet people and characters throughout Scripture.', Icons.people_alt_rounded, Color(0xFF4269B2)),
    _PuzzleCategory('Bible Cities', 'Explore important cities and places in the Bible.', Icons.location_city_rounded, Color(0xFF148A83)),
    _PuzzleCategory('Bible Kings', 'Discover kings and rulers from biblical history.', Icons.workspace_premium_rounded, Color(0xFFB88728)),
    _PuzzleCategory('Verses & Chapters', 'Find key words from well-known Bible passages.', Icons.menu_book_rounded, Color(0xFF7856B8)),
    _PuzzleCategory('Bible Events & Places', 'Search for words from important Bible moments.', Icons.auto_awesome_rounded, Color(0xFFB45F42)),
  ];

  static const packs = <_PuzzlePack>[
    _PuzzlePack('Bible Names', 'The Patriarchs', 'ABRAHAM SARAH ISAAC REBEKAH JACOB ESAU JOSEPH JUDAH LEVI BENJAMIN'),
    _PuzzlePack('Bible Names', 'Women of the Bible', 'EVE SARAH REBEKAH LEAH RACHEL MIRIAM RUTH NAOMI ESTHER DEBORAH'),
    _PuzzlePack('Bible Names', 'The Prophets', 'ISAIAH JEREMIAH EZEKIEL DANIEL HOSEA JOEL AMOS JONAH MICAH MALACHI'),
    _PuzzlePack('Bible Names', 'The Disciples', 'PETER ANDREW JAMES JOHN PHILIP THOMAS MATTHEW SIMON JUDAS BARTHOLOMEW'),
    _PuzzlePack('Bible Names', 'Early Church', 'PAUL BARNABAS SILAS TIMOTHY TITUS LUKE MARK STEPHEN PHOEBE PRISCILLA'),
    _PuzzlePack('Bible Names', 'People Around Jesus', 'MARY MARTHA LAZARUS JOSEPH NICODEMUS ZACCHAEUS HEROD PILATE CAIAPHAS'),
    _PuzzlePack('Bible Names', 'Leaders of Israel', 'MOSES AARON JOSHUA CALEB GIDEON SAMUEL SAUL DAVID SOLOMON ELIJAH'),
    _PuzzlePack('Bible Names', 'Faithful Servants', 'RUTH BOAZ ESTHER MORDECAI NEHEMIAH EZRA JOB ENOCH NOAH ABEL'),
    _PuzzlePack('Bible Names', 'Joseph and His Family', 'JOSEPH JACOB JUDAH REUBEN SIMEON LEVI ISSACHAR ZEBULUN DAN NAPHTALI'),
    _PuzzlePack('Bible Names', 'Kings and Queens', 'DAVID SAUL SOLOMON ESTHER VASHTI HEZEKIAH JOSIAH AHAB JEHU REHOBOAM'),

    _PuzzlePack('Bible Cities', 'Cities of the Gospels', 'JERUSALEM BETHLEHEM NAZARETH CAPERNAUM BETHANY CANA JERICHO'),
    _PuzzlePack('Bible Cities', 'Ancient Cities', 'NINEVEH BABYLON NIMROD UR URUK TYRE SIDON DAMASCUS'),
    _PuzzlePack('Bible Cities', 'Cities of Paul', 'CORINTH EPHESUS PHILIPPI THESSALONICA ATHENS ROME TROAS MILETUS'),
    _PuzzlePack('Bible Cities', 'Cities of Israel', 'SAMARIA HEBRON SHILOH GILGAL BETHEL BEERSHEBA JOPPA'),
    _PuzzlePack('Bible Cities', 'Cities and Regions', 'GOSHEN EGYPT CANAAN MOAB EDOM GILEAD GALILEE JUDEA'),
    _PuzzlePack('Bible Cities', 'The Seven Churches', 'EPHESUS SMYRNA PERGAMUM THYATIRA SARDIS PHILADELPHIA LAODICEA'),

    _PuzzlePack('Bible Kings', 'Kings of Israel', 'SAUL DAVID SOLOMON REHOBOAM JEROBOAM OMRI AHAB JEHU JOASH'),
    _PuzzlePack('Bible Kings', 'Righteous Kings', 'DAVID SOLOMON ASA JEHOSHAPHAT HEZEKIAH JOSIAH UZZIAH JOTHAM'),
    _PuzzlePack('Bible Kings', 'Kings of Judah', 'REHOBOAM ABIJAM ASA JEHOSHAPHAT JORAM AHAZ HEZEKIAH MANASSEH JOSIAH'),
    _PuzzlePack('Bible Kings', 'Kings of Israel and Judah', 'SAUL DAVID SOLOMON AHAB JEHU JOASH AMAZIAH UZZIAH AHAZ'),
    _PuzzlePack('Bible Kings', 'Foreign Rulers', 'PHARAOH CYRUS DARIUS NEBUCHADNEZZAR BELSHAZZAR HEROD PILATE'),
    _PuzzlePack('Bible Kings', 'Queens and Royalty', 'ESTHER VASHTI ATHALIAH JEZEBEL CANDACE BATHSHEBA ABIGAIL'),

    _PuzzlePack('Verses & Chapters', 'The Lord Is My Shepherd', 'SHEPHERD GREEN PASTURES STILL WATERS RESTORE RIGHTEOUSNESS VALLEY COMFORT GOODNESS MERCY', prompt: 'Find the key words from this well-known Psalm.', reference: 'Psalm 23'),
    _PuzzlePack('Verses & Chapters', 'The Love of God', 'LOVE WORLD GAVE SON BELIEVE LIFE ETERNAL PERISH', prompt: 'Find the key words from this Gospel passage.', reference: 'John 3:16'),
    _PuzzlePack('Verses & Chapters', 'The Armour of God', 'TRUTH RIGHTEOUSNESS PEACE FAITH SALVATION SPIRIT WORD PRAYER', prompt: 'Find the key words describing the armour of God.', reference: 'Ephesians 6:10–18'),
    _PuzzlePack('Verses & Chapters', 'The Fruit of the Spirit', 'LOVE JOY PEACE PATIENCE KINDNESS GOODNESS FAITHFULNESS GENTLENESS SELFCONTROL', prompt: 'Find the qualities listed in this passage.', reference: 'Galatians 5:22–23'),
    _PuzzlePack('Verses & Chapters', 'The Beatitudes', 'POOR MOURN MEEK RIGHTEOUS MERCY PURE PEACEMAKERS PERSECUTED', prompt: 'Find words from Jesus’ teaching on the mountain.', reference: 'Matthew 5:3–12'),
    _PuzzlePack('Verses & Chapters', 'The Great Commission', 'GO MAKE DISCIPLES NATIONS BAPTIZE TEACH COMMAND ALWAYS', prompt: 'Find words from Jesus’ final instruction to His disciples.', reference: 'Matthew 28:18–20'),
    _PuzzlePack('Verses & Chapters', 'Faith and Hope', 'FAITH HOPE LOVE SUBSTANCE EVIDENCE PROMISE TRUST', prompt: 'Find key words from the teaching about faith.', reference: 'Hebrews 11:1'),
    _PuzzlePack('Verses & Chapters', 'The Ten Commandments', 'WORSHIP HONOUR SABBATH PARENTS MURDER ADULTERY STEAL FALSE COVET', prompt: 'Find words connected with the commandments.', reference: 'Exodus 20:1–17'),
    _PuzzlePack('Verses & Chapters', 'A Psalm of Praise', 'PRAISE GLORY NAME THANKS GOOD MERCY FOREVER', prompt: 'Find key words from this psalm of praise.', reference: 'Psalm 100'),
    _PuzzlePack('Verses & Chapters', 'The Way of Love', 'PATIENT KIND ENVY BOAST PROUD HONOUR TRUTH PROTECT PERSEVERE', prompt: 'Find the qualities of love in this chapter.', reference: '1 Corinthians 13'),

    _PuzzlePack('Bible Events & Places', 'Creation', 'LIGHT EARTH WATER STARS TREES BEAST SUN MOON SEAS SEED'),
    _PuzzlePack('Bible Events & Places', 'The Garden of Eden', 'ADAM EVE EDEN SNAKE FRUIT DUST GARDEN TREE LIFE RIVER'),
    _PuzzlePack('Bible Events & Places', 'Noah and the Ark', 'NOAH ARK DOVE RAVEN RAIN FLOOD FAITH ALTAR COVENANT'),
    _PuzzlePack('Bible Events & Places', 'The Exodus', 'MOSES BUSH STAFF AARON NILE EXODUS PLAGUE MANNA SINAI TABLETS'),
    _PuzzlePack('Bible Events & Places', 'The Walls of Jericho', 'JOSHUA JERICHO RAHAB SPIES WALLS TRUMPET JORDAN CANAAN'),
    _PuzzlePack('Bible Events & Places', 'The Life of Jesus', 'JESUS MARY JOSEPH MANGER ANGEL STAR BETHLEHEM SHEPHERD MAGI'),
    _PuzzlePack('Bible Events & Places', 'Miracles of Jesus', 'WATER WINE BREAD FISH BLIND LEPER HEAL TOUCH MIRACLE POWER'),
    _PuzzlePack('Bible Events & Places', 'Jonah and Nineveh', 'JONAH FISH SHIP STORM NINEVEH PRAY MERCY SAILOR SEA PROPHET'),
    _PuzzlePack('Bible Events & Places', 'The Wilderness Journey', 'MANNA QUAIL ROCK CLOUD FIRE SINAI MOSES JOSHUA CALEB TENT'),
    _PuzzlePack('Bible Events & Places', 'David and Goliath', 'DAVID SAUL SLING STONE GIANT GOLIATH CROWN SHEPHERD COURAGE'),
  ];

  final _random = Random();
  int best = 0;
  int score = 0;
  bool loading = true;
  bool submitted = false;
  String? selectedCategory;
  String? message;
  _Puzzle? puzzle;
  int? dragStart;
  List<int> selection = [];
  final Set<String> found = {};
  final Set<int> foundCells = {};
  List<Map<String, dynamic>> downloaded = [];
  List<_PuzzlePack> offlineVersePacks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    best = prefs.getInt(bestKey) ?? 0;
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        downloaded = List<Map<String, dynamic>>.from(
          (jsonDecode(cached) as List).map((e) => Map<String, dynamic>.from(e)),
        );
      } catch (_) {
        downloaded = [];
      }
    }
    if (mounted) setState(() => loading = false);
    _syncScores();
    _loadOfflineVersePacks();
    _downloadPublishedPuzzles(prefs);
  }

  Future<void> _loadOfflineVersePacks() async {
    // Build a local verse-based puzzle bank from the Bible files bundled in
    // the APK. This never calls the network and works in airplane mode.
    try {
      final repository = BibleRepository();
      final candidates = <_PuzzlePack>[];
      const stopWords = {
        'THE', 'AND', 'FOR', 'YOU', 'YOUR', 'THAT', 'WAS', 'ARE', 'WITH',
        'HIS', 'HER', 'HIM', 'SHE', 'WHO', 'NOT', 'BUT', 'HAVE', 'HAS',
        'HATH', 'THIS', 'THEY', 'THEM', 'THEN', 'FROM', 'WILL', 'SHALL',
        'THERE', 'THEIR', 'THOU', 'THY', 'unto', 'unto'.toUpperCase(),
      };
      for (final bookName in repository.bookNames) {
        final raw = await rootBundle.loadString('assets/bible/books/$bookName.json');
        final book = BibleBook.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        for (final chapter in book.chapters) {
          for (final verse in chapter.verses) {
            final reference = '${book.name} ${chapter.number}:${verse.number}';
            final words = RegExp(r'[A-Za-z]{3,10}')
                .allMatches(verse.text)
                .map((match) => match.group(0)!.toUpperCase())
                .where((word) => !stopWords.contains(word))
                .toSet()
                .take(8)
                .toList();
            if (words.length < 3) continue;
            candidates.add(_PuzzlePack(
              'Verses & Chapters',
              reference,
              words.join(' '),
              prompt: verse.text,
              reference: reference,
            ));
          }
        }
      }
      if (candidates.length < 300) return;
      final step = candidates.length / 300;
      final selected = List.generate(
        300,
        (index) => candidates[(index * step).floor()],
      );
      if (mounted) setState(() => offlineVersePacks = selected);
    } catch (_) {
      // Keep the smaller hand-curated pack if a Bible asset is unavailable.
    }
  }

  Future<void> _downloadPublishedPuzzles(SharedPreferences prefs) async {
    try {
      final rows = await Supabase.instance.client
          .from('bible_word_searches')
          .select('id,category,theme,verse_text,bible_reference,words,explanation,difficulty,created_at')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(500)
          .timeout(const Duration(seconds: 3));
      final fresh = List<Map<String, dynamic>>.from(rows);
      await prefs.setString(cacheKey, jsonEncode(fresh));
      if (mounted) setState(() => downloaded = fresh);
    } catch (_) {
      // Keep the last downloaded puzzle pack for offline play.
    }
  }

  List<_PuzzlePack> _packsFor(String category) {
    final local = packs.where((p) => p.category == category).toList();
    final offlineVerses = offlineVersePacks.where((p) => p.category == category);
    final remote = downloaded.where((r) => r['category'] == category).map((r) {
      final words = List<String>.from(r['words'] as List)
          .map((w) => w.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), ''))
          .where((w) => w.length >= 2 && w.length <= size)
          .toSet()
          .join(' ');
      return _PuzzlePack(
        category,
        r['theme']?.toString().trim().isNotEmpty == true
            ? r['theme'].toString()
            : 'Bible Word Search',
        words,
        prompt: r['verse_text']?.toString() ?? '',
        reference: r['bible_reference']?.toString() ?? '',
      );
    }).where((p) => p.words.split(' ').where((w) => w.isNotEmpty).length >= 3);
    return [...local, ...offlineVerses, ...remote];
  }

  _Puzzle _makePuzzle(_PuzzlePack pack) {
    final words = pack.words.split(' ').where((w) => w.isNotEmpty).toList();
    final grid = List.generate(size, (_) => List.filled(size, ''));
    final paths = <String, List<int>>{};
    const dirs = <(int, int)>[
      (0, 1), (1, 0), (1, 1), (1, -1),
      (0, -1), (-1, 0), (-1, -1), (-1, 1),
    ];
    final shuffledWords = List<String>.from(words)..shuffle(_random);
    for (final word in shuffledWords) {
      var done = false;
      for (var attempt = 0; attempt < 1600 && !done; attempt++) {
        final d = dirs[_random.nextInt(dirs.length)];
        final row = _random.nextInt(size);
        final col = _random.nextInt(size);
        final endRow = row + d.$1 * (word.length - 1);
        final endCol = col + d.$2 * (word.length - 1);
        if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) continue;
        var fits = true;
        for (var i = 0; i < word.length; i++) {
          final old = grid[row + d.$1 * i][col + d.$2 * i];
          if (old.isNotEmpty && old != word[i]) {
            fits = false;
            break;
          }
        }
        if (!fits) continue;
        final path = <int>[];
        for (var i = 0; i < word.length; i++) {
          final rr = row + d.$1 * i;
          final cc = col + d.$2 * i;
          grid[rr][cc] = word[i];
          path.add(rr * size + cc);
        }
        paths[word] = path;
        done = true;
      }
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (grid[row][col].isEmpty) {
          grid[row][col] = alphabet[_random.nextInt(alphabet.length)];
        }
      }
    }
    return _Puzzle(
      category: pack.category,
      theme: pack.theme,
      words: List.unmodifiable(paths.keys),
      grid: grid,
      paths: paths,
      prompt: pack.prompt,
      reference: pack.reference,
    );
  }

  void _chooseCategory(String category) {
    final available = _packsFor(category);
    if (available.isEmpty) {
      setState(() => message = 'No puzzles are available in this category yet.');
      return;
    }
    final chosen = available[_random.nextInt(available.length)];
    setState(() {
      selectedCategory = category;
      puzzle = _makePuzzle(chosen);
      score = 0;
      message = null;
      found.clear();
      foundCells.clear();
      selection = [];
      dragStart = null;
      submitted = false;
    });
  }

  void _track(Offset pos, double cell) {
    final col = (pos.dx / cell).floor().clamp(0, size - 1).toInt();
    final row = (pos.dy / cell).floor().clamp(0, size - 1).toInt();
    final end = row * size + col;
    if (dragStart == null) {
      dragStart = end;
      selection = [end];
      return;
    }
    final startRow = dragStart! ~/ size;
    final startCol = dragStart! % size;
    final dr = row - startRow;
    final dc = col - startCol;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return;
    final steps = max(dr.abs(), dc.abs());
    final vr = steps == 0 ? 0 : dr ~/ steps;
    final vc = steps == 0 ? 0 : dc ~/ steps;
    selection = List.generate(steps + 1, (i) => (startRow + vr * i) * size + startCol + vc * i);
  }

  String get selectedWord =>
      selection.map((i) => puzzle!.grid[i ~/ size][i % size]).join();

  void _finish() {
    if (selection.isEmpty || puzzle == null) return;
    final word = selectedWord;
    final reverse = word.split('').reversed.join();
    String? match;
    for (final candidate in puzzle!.words) {
      if (!found.contains(candidate) && (candidate == word || candidate == reverse)) {
        match = candidate;
        break;
      }
    }
    if (match != null) {
      final foundWord = match;
      setState(() {
        found.add(foundWord);
        foundCells.addAll(puzzle!.paths[foundWord] ?? selection);
        score += foundWord.length * 10;
        message = 'Great find! +${foundWord.length * 10} points';
      });
      if (found.length == puzzle!.words.length) _complete();
    } else {
      setState(() => message = 'Not quite. Try another direction.');
    }
    setState(() {
      selection = [];
      dragStart = null;
    });
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    best = max(best, score);
    await prefs.setInt(bestKey, best);
    await _submitScore();
    if (mounted) setState(() => message = 'PUZZLE COMPLETE! Excellent work.');
  }

  Future<void> _nextPuzzle() async {
    if (selectedCategory == null) return;
    final available = _packsFor(selectedCategory!);
    if (available.isEmpty) return;
    var choices = available.where((p) => p.theme != puzzle?.theme).toList();
    if (choices.isEmpty) choices = available;
    final chosen = choices[_random.nextInt(choices.length)];
    setState(() {
      puzzle = _makePuzzle(chosen);
      found.clear();
      foundCells.clear();
      selection = [];
      dragStart = null;
      message = null;
      submitted = false;
    });
  }

  Future<void> _submitScore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || submitted) return;
    submitted = true;
    try {
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': user.id,
        'game_id': 'bible_grid_search',
        'score': score,
      }).timeout(const Duration(seconds: 3));
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(queueKey) ?? [];
      queue.add('bible_grid_search|$score');
      await prefs.setStringList(queueKey, queue);
    }
  }

  Future<void> _syncScores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(queueKey) ?? [];
    final keep = <String>[];
    for (final item in queue) {
      final parts = item.split('|');
      if (parts.length != 2) continue;
      try {
        await Supabase.instance.client.from('game_scores').insert({
          'user_id': user.id,
          'game_id': parts[0],
          'score': int.parse(parts[1]),
        }).timeout(const Duration(seconds: 2));
      } catch (_) {
        keep.add(item);
      }
    }
    await prefs.setStringList(queueKey, keep);
  }

  Widget _categoryScreen(bool dark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Search'),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const GameLeaderboardPage(
                gameId: 'bible_grid_search',
                gameTitle: 'Word Search Puzzle',
              ),
            )),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF123A82), Color(0xFF1764C0), Color(0xFF0D2D64)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gold.withValues(alpha: .45)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SEARCH THE WORD', style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                  SizedBox(height: 8),
                  Text('Choose a Bible category', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('Explore Scripture one puzzle at a time.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Material(
                  color: dark ? const Color(0xFF13233A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _chooseCategory(category.name),
                    child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: category.tint.withValues(alpha: .35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: category.tint.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(category.icon, color: category.tint, size: 27),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(category.description, style: TextStyle(fontSize: 12, height: 1.35, color: dark ? Colors.white70 : Colors.black54)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (puzzle == null) return _categoryScreen(dark);

    final complete = found.length == puzzle!.words.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(puzzle!.category),
        leading: IconButton(
          tooltip: 'Choose another category',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() {
            puzzle = null;
            selectedCategory = null;
            message = null;
          }),
        ),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const GameLeaderboardPage(
                gameId: 'bible_grid_search',
                gameTitle: 'Word Search Puzzle',
              ),
            )),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(puzzle!.theme, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: blue, fontWeight: FontWeight.w900, fontSize: 15)),
                        if (puzzle!.reference.isNotEmpty)
                          Text(puzzle!.reference, style: TextStyle(fontSize: 11, color: dark ? Colors.white70 : Colors.black54)),
                        if (puzzle!.prompt.isNotEmpty)
                          Text(puzzle!.prompt, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: dark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('SCORE  $score', style: const TextStyle(color: blue, fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('BEST  $best', style: TextStyle(color: dark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w700, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: puzzle!.words.isEmpty ? 0 : found.length / puzzle!.words.length,
                  minHeight: 6,
                  backgroundColor: dark ? Colors.white12 : blue.withValues(alpha: .10),
                  valueColor: const AlwaysStoppedAnimation<Color>(gold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = min(constraints.maxWidth, constraints.maxHeight);
                    final cell = side / size;
                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) => setState(() {
                            dragStart = null;
                            _track(d.localPosition, cell);
                          }),
                          onPanUpdate: (d) => setState(() => _track(d.localPosition, cell)),
                          onPanEnd: (_) => _finish(),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF0D1A2D) : const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: blue.withValues(alpha: .3)),
                            ),
                            child: Column(
                              children: List.generate(size, (r) => Expanded(
                                child: Row(
                                  children: List.generate(size, (c) {
                                    final n = r * size + c;
                                    final isFound = foundCells.contains(n);
                                    final isSelected = selection.contains(n);
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.all(1),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isFound
                                              ? const Color(0xFF19A66A).withValues(alpha: .22)
                                              : isSelected ? gold.withValues(alpha: .70) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: FittedBox(
                                          child: Text(
                                            puzzle!.grid[r][c],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: isFound ? const Color(0xFF148451)
                                                  : (dark ? Colors.white : const Color(0xFF12356D)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              )),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text('WORDS TO FIND',
                      style: TextStyle(color: blue, fontWeight: FontWeight.w900, letterSpacing: .5)),
                  ),
                  Text('Swipe across each word',
                    style: TextStyle(fontSize: 10, color: dark ? Colors.white60 : Colors.black54)),
                ],
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 126),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: puzzle!.words.map((word) {
                      final done = found.contains(word);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: done ? const Color(0xFF19A66A).withValues(alpha: .13)
                              : (dark ? Colors.white10 : const Color(0xFFFFF6D9)),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: done ? const Color(0xFF19A66A) : gold),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (done) const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF19A66A)),
                            if (done) const SizedBox(width: 4),
                            Text(word, style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              decoration: done ? TextDecoration.lineThrough : null,
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(message!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                      color: complete ? const Color(0xFF19A66A) : blue)),
                ),
              if (complete)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _nextPuzzle,
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Next puzzle'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
