import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_leaderboard_page.dart';

/// Offline-first Word Cookies-style Bible word-connect game.
class BibleWordPuzzlePage extends StatefulWidget {
  const BibleWordPuzzlePage({super.key});
  @override
  State<BibleWordPuzzlePage> createState() => _BibleWordPuzzlePageState();
}

class _CookiePuzzle {
  const _CookiePuzzle(this.reference, this.letters, this.words, this.clues, this.mode, this.level);
  final String reference;
  final String letters;
  final List<String> words;
  final List<String> clues;
  final String mode; // verse or theme
  final String level;
}

class _BibleWordPuzzlePageState extends State<BibleWordPuzzlePage> {
  static const _blue = Color(0xFF0B5ED7);
  static const _gold = Color(0xFFD4AF37);
  static const _bestKey = 'ngn_bible_word_cookies_best';
  static const _queueKey = 'ngn_game_score_queue';
  static final List<_CookiePuzzle> _bank = _buildFiveHundredLevels();

  static List<_CookiePuzzle> _buildFiveHundredLevels() {
    // 25 Bible themes × all 20 combinations of three words from six = 500 levels.
    // Each answer has its own Bible-centred clue; the wheel is built from the answers.
    const themes = <_ThemePack>[
      _ThemePack('Creation • Genesis 1', [
        _WordClue('LIGHT','God called this good when He separated it from darkness','Genesis 1:3-5'),
        _WordClue('EARTH','The dry land God gathered together','Genesis 1:10'),
        _WordClue('WATER','God gathered this under the heaven','Genesis 1:9'),
        _WordClue('STARS','Lights set in the sky to mark seasons','Genesis 1:16'),
        _WordClue('TREES','Plants bearing fruit and seed','Genesis 1:11-12'),
        _WordClue('BEAST','A living creature made on the sixth day','Genesis 1:24-25'),
      ]),
      _ThemePack('The Garden of Eden • Genesis 2–3', [
        _WordClue('ADAM','The first man','Genesis 2:7'),
        _WordClue('EVE','The first woman','Genesis 3:20'),
        _WordClue('EDEN','The garden where the first humans lived','Genesis 2:8'),
        _WordClue('SNAKE','The creature that tempted Eve','Genesis 3:1'),
        _WordClue('FRUIT','What the woman took and ate','Genesis 3:6'),
        _WordClue('DUST','What man was formed from','Genesis 2:7'),
      ]),
      _ThemePack('Noah and the Flood • Genesis 6–9', [
        _WordClue('NOAH','The righteous man who built an ark','Genesis 6:9'),
        _WordClue('ARK','The vessel built to survive the flood','Genesis 6:14'),
        _WordClue('DOVE','The bird Noah sent out','Genesis 8:8'),
        _WordClue('RAVEN','The first bird Noah sent out','Genesis 8:7'),
        _WordClue('RAIN','Water that fell for forty days and nights','Genesis 7:12'),
        _WordClue('BOW','The sign of God’s covenant after the flood','Genesis 9:13'),
      ]),
      _ThemePack('Abraham’s Journey • Genesis 12–22', [
        _WordClue('ABRAM','Abraham’s name before God changed it','Genesis 17:5'),
        _WordClue('SARAH','Abraham’s wife and Isaac’s mother','Genesis 17:15-16'),
        _WordClue('ISAAC','The promised son of Abraham','Genesis 21:3'),
        _WordClue('ALTAR','A place Abraham built to worship God','Genesis 12:7'),
        _WordClue('FAITH','Abraham believed God and it was counted for righteousness','Genesis 15:6'),
        _WordClue('COVENANT','God’s solemn promise to Abraham','Genesis 17:2'),
      ]),
      _ThemePack('Jacob and Esau • Genesis 25–35', [
        _WordClue('JACOB','The younger twin who received the blessing','Genesis 27:36'),
        _WordClue('ESAU','Jacob’s elder twin brother','Genesis 25:25'),
        _WordClue('LEAH','Jacob’s wife and mother of several sons','Genesis 29:23'),
        _WordClue('RACHEL','Jacob’s beloved wife','Genesis 29:18'),
        _WordClue('LADDER','Jacob saw this reaching to heaven in a dream','Genesis 28:12'),
        _WordClue('ISRAEL','The new name given to Jacob','Genesis 32:28'),
      ]),
      _ThemePack('Joseph in Egypt • Genesis 37–50', [
        _WordClue('JOSEPH','Jacob’s son who became a ruler in Egypt','Genesis 41:41'),
        _WordClue('DREAM','Joseph interpreted these for others','Genesis 40:8'),
        _WordClue('COAT','The special garment given to Joseph by his father','Genesis 37:3'),
        _WordClue('EGYPT','The land where Joseph served Pharaoh','Genesis 41:46'),
        _WordClue('PHARAOH','The ruler whose dreams Joseph interpreted','Genesis 41:15'),
        _WordClue('GRAIN','Joseph stored this during the years of plenty','Genesis 41:49'),
      ]),
      _ThemePack('Moses • Exodus 1–4', [
        _WordClue('MOSES','The man called by God at the burning bush','Exodus 3:4'),
        _WordClue('BUSH','It burned without being consumed','Exodus 3:2'),
        _WordClue('STAFF','Moses carried this shepherd’s tool','Exodus 4:2'),
        _WordClue('AARON','Moses’ brother who spoke for him','Exodus 4:14-16'),
        _WordClue('NILE','The river where baby Moses was placed','Exodus 2:3'),
        _WordClue('CALL','God summoned Moses to lead Israel','Exodus 3:4'),
      ]),
      _ThemePack('The Exodus • Exodus 5–15', [
        _WordClue('PLAGUE','A judgement sent upon Egypt','Exodus 7–12'),
        _WordClue('BLOOD','The Passover sign placed on the doorposts','Exodus 12:7'),
        _WordClue('LAMB','The animal sacrificed at Passover','Exodus 12:3-6'),
        _WordClue('SEA','God divided this so Israel could cross','Exodus 14:21'),
        _WordClue('STAFF','Moses stretched this over the sea','Exodus 14:16'),
        _WordClue('SONG','Moses and Israel sang after deliverance','Exodus 15:1'),
      ]),
      _ThemePack('The Wilderness • Exodus–Numbers', [
        _WordClue('MANNA','The bread-like food God provided','Exodus 16:15'),
        _WordClue('QUAIL','Birds God sent for Israel to eat','Exodus 16:13'),
        _WordClue('ROCK','Moses struck this and water came out','Exodus 17:6'),
        _WordClue('CLOUD','This guided Israel by day','Exodus 13:21'),
        _WordClue('FIRE','This guided Israel by night','Exodus 13:21'),
        _WordClue('SINAI','The mountain where God gave the law','Exodus 19:20'),
      ]),
      _ThemePack('Joshua and Jericho • Joshua 1–6', [
        _WordClue('JOSHUA','Moses’ successor who led Israel into Canaan','Joshua 1:1-2'),
        _WordClue('JERICHO','The city whose walls fell after Israel obeyed God','Joshua 6:20'),
        _WordClue('RAHAB','The woman who hid the Israelite spies','Joshua 2:4'),
        _WordClue('SPIES','The men sent to view the land','Joshua 2:1'),
        _WordClue('WALLS','These fell after Israel shouted','Joshua 6:20'),
        _WordClue('TRUMPET','The priests blew this at Jericho','Joshua 6:20'),
      ]),
      _ThemePack('Ruth and Naomi • Book of Ruth', [
        _WordClue('RUTH','The Moabite woman who stayed with Naomi','Ruth 1:16'),
        _WordClue('NAOMI','Ruth’s mother-in-law','Ruth 1:2'),
        _WordClue('BOAZ','The kinsman who married Ruth','Ruth 4:13'),
        _WordClue('WHEAT','Ruth gleaned this in Boaz’s field','Ruth 2:23'),
        _WordClue('FIELD','Where Ruth gathered leftover grain','Ruth 2:3'),
        _WordClue('LOYAL','A word describing Ruth’s faithful devotion','Ruth 1:16-17'),
      ]),
      _ThemePack('David the Shepherd • 1 Samuel 16–17', [
        _WordClue('DAVID','The shepherd who defeated Goliath','1 Samuel 17:50'),
        _WordClue('SAUL','Israel’s first king','1 Samuel 10:24'),
        _WordClue('SHEEP','The animals David cared for','1 Samuel 17:34'),
        _WordClue('SLING','David used this against Goliath','1 Samuel 17:40'),
        _WordClue('STONE','David chose five of these from the brook','1 Samuel 17:40'),
        _WordClue('GIANT','Goliath was a Philistine of great size','1 Samuel 17:4'),
      ]),
      _ThemePack('King Solomon • 1 Kings 3–10', [
        _WordClue('SOLOMON','David’s son who asked God for wisdom','1 Kings 3:9'),
        _WordClue('WISDOM','What Solomon asked God to give him','1 Kings 3:9-12'),
        _WordClue('TEMPLE','The house Solomon built for the Lord','1 Kings 6:1'),
        _WordClue('QUEEN','The ruler of Sheba who visited Solomon','1 Kings 10:1'),
        _WordClue('GOLD','A precious metal used in the temple','1 Kings 6:20-22'),
        _WordClue('PROVERB','A short wise saying; Solomon spoke many','1 Kings 4:32'),
      ]),
      _ThemePack('Psalms of Worship • Psalms', [
        _WordClue('PRAISE','To express honour and worship to God','Psalm 150:1-6'),
        _WordClue('PSALM','A sacred song or poem','Psalm 23:1'),
        _WordClue('SING','The psalmist calls God’s people to do this','Psalm 96:1'),
        _WordClue('HEART','The inner person that trusts in the Lord','Psalm 28:7'),
        _WordClue('JOY','Gladness found in God’s presence','Psalm 16:11'),
        _WordClue('TRUST','Rely on the Lord rather than fear','Psalm 56:3'),
      ]),
      _ThemePack('Elijah and Elisha • 1–2 Kings', [
        _WordClue('ELIJAH','The prophet who challenged the prophets of Baal','1 Kings 18:21-39'),
        _WordClue('ELISHA','The prophet who received Elijah’s mantle','2 Kings 2:9-15'),
        _WordClue('FIRE','Fell from heaven at Elijah’s prayer','1 Kings 18:38'),
        _WordClue('RAIN','Returned after Elijah prayed','1 Kings 18:41-45'),
        _WordClue('MANTLE','Elijah’s garment that Elisha took up','2 Kings 2:13'),
        _WordClue('JORDAN','The river they crossed before Elijah was taken','2 Kings 2:6-8'),
      ]),
      _ThemePack('Daniel in Babylon • Daniel 1–6', [
        _WordClue('DANIEL','The servant of God who interpreted dreams','Daniel 2:19'),
        _WordClue('LIONS','The animals in the den where Daniel was placed','Daniel 6:16'),
        _WordClue('DEN','The place Daniel was thrown into','Daniel 6:16'),
        _WordClue('PRAY','What Daniel continued to do three times daily','Daniel 6:10'),
        _WordClue('KING','The ruler who signed the decree about prayer','Daniel 6:9'),
        _WordClue('FAITH','Daniel trusted God even when threatened','Daniel 6:23'),
      ]),
      _ThemePack('Jonah • Book of Jonah', [
        _WordClue('JONAH','The prophet sent to Nineveh','Jonah 1:1-2'),
        _WordClue('FISH','The great creature that swallowed Jonah','Jonah 1:17'),
        _WordClue('SHIP','Jonah boarded this to flee from the Lord','Jonah 1:3'),
        _WordClue('STORM','The sea became violent while Jonah sailed','Jonah 1:4'),
        _WordClue('NINEVEH','The city Jonah was told to warn','Jonah 1:2'),
        _WordClue('PRAY','Jonah called to God from the fish','Jonah 2:1'),
      ]),
      _ThemePack('The Birth of Jesus • Matthew 1–2; Luke 1–2', [
        _WordClue('JESUS','The name given to the promised Saviour','Matthew 1:21'),
        _WordClue('MARY','The mother of Jesus','Luke 1:30-31'),
        _WordClue('JOSEPH','Mary’s husband who cared for Jesus','Matthew 1:20-25'),
        _WordClue('MANGER','Where the baby Jesus was laid','Luke 2:7'),
        _WordClue('ANGEL','A messenger who announced the birth','Luke 2:9-11'),
        _WordClue('STAR','The sign that guided the wise men','Matthew 2:2'),
      ]),
      _ThemePack('The Teachings of Jesus • Gospels', [
        _WordClue('LOVE','Jesus taught His followers to love one another','John 13:34'),
        _WordClue('PRAY','Jesus taught His disciples to do this','Matthew 6:9'),
        _WordClue('MERCY','Blessed are those who show this','Matthew 5:7'),
        _WordClue('TRUTH','Jesus said God’s word is this','John 17:17'),
        _WordClue('SERVE','Jesus came not to be served but to do this','Mark 10:45'),
        _WordClue('GIVE','Jesus taught generosity','Luke 6:38'),
      ]),
      _ThemePack('Miracles of Jesus • Gospels', [
        _WordClue('WATER','Jesus turned this into wine','John 2:7-9'),
        _WordClue('WINE','The drink at the wedding in Cana','John 2:9'),
        _WordClue('BREAD','Jesus multiplied loaves to feed the crowd','John 6:9-13'),
        _WordClue('FISH','These were multiplied with the loaves','John 6:9-13'),
        _WordClue('BLIND','The people Jesus gave sight to','John 9:1-7'),
        _WordClue('LEPER','A man Jesus cleansed','Mark 1:40-42'),
      ]),
      _ThemePack('Parables of Jesus • Gospels', [
        _WordClue('SOWER','The farmer in Jesus’ parable','Matthew 13:3'),
        _WordClue('SEED','What the sower scattered','Matthew 13:4'),
        _WordClue('SOIL','The seed fell on different kinds of this','Matthew 13:8'),
        _WordClue('TALENT','A measure of money in a parable about stewardship','Matthew 25:14-30'),
        _WordClue('LAMP','The wise virgins carried this with oil','Matthew 25:1-4'),
        _WordClue('COINS','The woman searched carefully for one lost piece','Luke 15:8-9'),
      ]),
      _ThemePack('The Disciples • Gospels', [
        _WordClue('PETER','The disciple who denied Jesus three times','Luke 22:54-62'),
        _WordClue('JOHN','The disciple described as beloved','John 13:23'),
        _WordClue('JAMES','Brother of John and one of the twelve','Matthew 4:21'),
        _WordClue('THOMAS','The disciple who wanted to see before believing','John 20:24-29'),
        _WordClue('ANDREW','Peter’s brother who brought him to Jesus','John 1:40-42'),
        _WordClue('JUDAS','The disciple who betrayed Jesus','Matthew 26:14-16'),
      ]),
      _ThemePack('The Cross and Resurrection • Gospels', [
        _WordClue('CROSS','The instrument on which Jesus was crucified','John 19:17-18'),
        _WordClue('NAILS','Used by the soldiers during the crucifixion','John 20:25'),
        _WordClue('TOMB','The place where Jesus was laid','Matthew 27:59-60'),
        _WordClue('RISEN','The angel announced that Jesus had done this','Matthew 28:6'),
        _WordClue('STONE','This was rolled away from the tomb','Matthew 28:2'),
        _WordClue('GRACE','God’s undeserved favour made known through Christ','Ephesians 2:8'),
      ]),
      _ThemePack('The Early Church • Acts', [
        _WordClue('PETER','The apostle who preached at Pentecost','Acts 2:14'),
        _WordClue('PAUL','The apostle who travelled to preach Christ','Acts 13:2-3'),
        _WordClue('SAUL','The name Paul was known by before his mission','Acts 13:9'),
        _WordClue('PRAY','The believers continued steadfastly in this','Acts 2:42'),
        _WordClue('GIFT','The Holy Spirit was promised as this','Acts 2:38'),
        _WordClue('FAITH','The believers shared one trust in Christ','Acts 2:44'),
      ]),
      _ThemePack('The Fruit of the Spirit • Galatians 5:22–23', [
        _WordClue('LOVE','The first quality listed in the fruit of the Spirit','Galatians 5:22'),
        _WordClue('JOY','A deep gladness produced by the Spirit','Galatians 5:22'),
        _WordClue('PEACE','Calm confidence in God','Galatians 5:22'),
        _WordClue('FAITH','Trust and faithfulness are part of the Spirit’s fruit','Galatians 5:22'),
        _WordClue('KIND','A quality describing considerate goodness','Galatians 5:22'),
        _WordClue('GENTLE','Not harsh; a quality of Christlike character','Galatians 5:23'),
      ]),
    ];

    final levels = <_CookiePuzzle>[];
    for (final theme in themes) {
      for (var a = 0; a < 6; a++) {
        for (var b = a + 1; b < 6; b++) {
          for (var d = b + 1; d < 6; d++) {
            final chosen = [theme.words[a], theme.words[b], theme.words[d]];
            final number = levels.length + 1;
            final difficulty = number <= 150 ? 'Easy' : number <= 350 ? 'Medium' : 'Hard';
            levels.add(_CookiePuzzle(
              'Level $number • ${theme.title}',
              chosen.map((w) => w.word).join(),
              chosen.map((w) => w.word).toList(),
              chosen.map((w) => '${w.clue} (${w.reference})').toList(),
              'theme',
              difficulty,
            ));
          }
        }
      }
    }
    return levels.take(500).toList(growable: false);
  }

  final Random _random = Random();
  final Set<String> _found = {};
  final List<String> _formed = [];
  late _CookiePuzzle _puzzle;
  int _index = 0, _score = 0, _best = 0;
  String _difficulty = 'All';
  String? _message;
  bool _submitted = false;
  final Set<int> _dragVisited = {};

  List<_CookiePuzzle> get _pool => _difficulty == 'All' ? _bank : _bank.where((p) => p.level == _difficulty).toList();
  bool get _complete => _found.length == _puzzle.words.length;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _newPuzzle();
    _syncQueuedScores();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = p.getInt(_bestKey) ?? 0);
  }

  void _newPuzzle() {
    final pool = _pool;
    if (pool.isEmpty) return;
    _puzzle = pool[_index % pool.length];
    _index++;
    _found.clear();
    _formed.clear();
    _message = null;
    _submitted = false;
    if (mounted) setState(() {});
  }

  void _addLetter(String letter) {
    if (_complete || _formed.length >= _puzzle.letters.length) return;
    setState(() { _formed.add(letter); _message = null; });
  }

  void _dragLetter(int index, List<String> letters) {
    if (index < 0 || index >= letters.length || _dragVisited.contains(index)) return;
    _dragVisited.add(index);
    _addLetter(letters[index]);
  }

  Widget _letterWheel(List<String> letters) {
    return SizedBox(
      height: 230,
      child: LayoutBuilder(builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, 115);
        final radius = min(88.0, constraints.maxWidth / 2 - 28);
        int nearest(Offset point) {
          var bestIndex = -1;
          var bestDistance = double.infinity;
          for (var i = 0; i < letters.length; i++) {
            final angle = -pi / 2 + (2 * pi * i / letters.length);
            final target = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
            final distance = (point - target).distance;
            if (distance < bestDistance) { bestDistance = distance; bestIndex = i; }
          }
          return bestDistance < 34 ? bestIndex : -1;
        }
        return GestureDetector(
          onPanStart: (details) { _dragVisited.clear(); _dragLetter(nearest(details.localPosition), letters); },
          onPanUpdate: (details) => _dragLetter(nearest(details.localPosition), letters),
          onPanEnd: (_) { _submitWord(); _dragVisited.clear(); },
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _WheelGuidePainter(center: center, radius: radius))),
            for (var i = 0; i < letters.length; i++)
              Positioned(
                left: center.dx + radius * cos(-pi / 2 + 2 * pi * i / letters.length) - 22,
                top: center.dy + radius * sin(-pi / 2 + 2 * pi * i / letters.length) - 22,
                child: Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle), child: Text(letters[i], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 17))),
              ),
          ]),
        );
      }),
    );
  }

  void _removeLetter(int index) {
    if (index < 0 || index >= _formed.length) return;
    setState(() => _formed.removeAt(index));
  }

  void _submitWord() {
    if (_formed.isEmpty || _complete) return;
    final word = _formed.join();
    if (_puzzle.words.contains(word) && !_found.contains(word)) {
      setState(() {
        _found.add(word);
        _score += word.length * 10;
        _message = 'Correct! +${word.length * 10} points';
        _formed.clear();
      });
      if (_complete) _finishPuzzle();
    } else if (_found.contains(word)) {
      setState(() { _message = 'You have already found that word.'; _formed.clear(); });
    } else {
      setState(() { _message = 'Not one of the words in this puzzle. Try another combination.'; _formed.clear(); });
    }
  }

  Future<void> _finishPuzzle() async {
    final p = await SharedPreferences.getInstance();
    final nextBest = max(_best, _score);
    await p.setInt(_bestKey, nextBest);
    if (mounted) setState(() => _best = nextBest);
    await _submitScore();
  }

  Future<void> _submitScore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _submitted) return;
    _submitted = true;
    try {
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': user.id,
        'game_id': 'bible_word_search',
        'score': _score,
      });
    } catch (_) {
      final p = await SharedPreferences.getInstance();
      final queue = p.getStringList(_queueKey) ?? [];
      queue.add('bible_word_search|$_score');
      await p.setStringList(_queueKey, queue);
    }
  }

  Future<void> _syncQueuedScores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final p = await SharedPreferences.getInstance();
    final queue = p.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) return;
    final remaining = <String>[];
    for (final item in queue) {
      final parts = item.split('|');
      if (parts.length != 2) continue;
      try {
        await Supabase.instance.client.from('game_scores').insert({
          'user_id': user.id, 'game_id': parts[0], 'score': int.parse(parts[1]),
        });
      } catch (_) { remaining.add(item); }
    }
    await p.setStringList(_queueKey, remaining);
  }

  void _shuffleLetters() {
    setState(() { _puzzle = _CookiePuzzle(_puzzle.reference, String.fromCharCodes(_puzzle.letters.runes.toList()..shuffle(_random)), _puzzle.words, _puzzle.clues, _puzzle.mode, _puzzle.level); });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final letters = _puzzle.letters.split('');
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Word Cookies'), actions: [
        IconButton(tooltip: 'Leaderboard', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLeaderboardPage(gameId: 'bible_word_search', gameTitle: 'Bible Word Cookies'))), icon: const Icon(Icons.leaderboard_rounded)),
      ]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [_blue, Color(0xFF173E80)]), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.cookie_rounded, color: _gold), SizedBox(width: 8), Text('CONNECT THE BIBLE WORDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), Spacer(), Icon(Icons.wifi_off, color: Colors.white70, size: 16), SizedBox(width: 4), Text('OFFLINE', style: TextStyle(color: Colors.white70, fontSize: 10))]),
            const SizedBox(height: 10),
            Text('Score: $_score  •  Best: $_best', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButton<String>(value: _difficulty, dropdownColor: Colors.white, style: const TextStyle(color: Colors.black87), items: const ['All','Easy','Medium','Hard'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() { _difficulty = v; _index = 0; }); _newPuzzle(); }),
          ]),
        ),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_puzzle.mode == 'verse' ? 'BIBLE REFERENCE' : 'BIBLE WORD CHALLENGE', style: const TextStyle(color: _blue, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(_puzzle.reference, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(_puzzle.mode == 'verse' ? 'The verse is hidden. Use the letter wheel and clues to discover its key words.' : 'There is no displayed verse for this round. Use the clues to discover the Bible-related words.'),
        ]))),
        const SizedBox(height: 12),
        const Text('WORD BOXES', style: TextStyle(color: _blue, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...List.generate(_puzzle.words.length, (i) {
          final word = _puzzle.words[i];
          final done = _found.contains(word);
          return Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WORD ${i + 1}  •  ${word.length} LETTERS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _blue)),
            const SizedBox(height: 5),
            Wrap(spacing: 4, children: List.generate(word.length, (j) => Container(width: 25, height: 31, alignment: Alignment.center, decoration: BoxDecoration(color: done ? Colors.green.withValues(alpha: .15) : (dark ? Colors.white10 : Colors.blue.shade50), border: Border(bottom: BorderSide(color: done ? Colors.green : _blue, width: 2))), child: Text(done ? word[j] : '', style: const TextStyle(fontWeight: FontWeight.w900))))),
            const SizedBox(height: 5),
            Text(_puzzle.clues[i], style: TextStyle(color: dark ? Colors.white70 : Colors.black87)),
          ])));
        }),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          const Text('LETTER WHEEL', style: TextStyle(color: _blue, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_formed.isEmpty ? 'Swipe across the letters to form a word' : _formed.join(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 10),
          _letterWheel(letters),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(onPressed: _formed.isEmpty ? null : () => _removeLetter(_formed.length - 1), icon: const Icon(Icons.backspace_outlined)),
            Expanded(child: OutlinedButton(onPressed: _shuffleLetters, child: const Text('Shuffle letters'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: _submitWord, child: const Text('Submit word'))),
          ]),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]))),
        if (_complete) Card(color: Colors.green.withValues(alpha: .12), child: const Padding(padding: EdgeInsets.all(16), child: Text('LEVEL COMPLETE! Excellent work. Your score is saved on this device and will be submitted to the leaderboard when you are online and signed in.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green)))),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _complete ? _newPuzzle : null, icon: const Icon(Icons.arrow_forward), label: const Text('Next level')),
        Text('Find all the hidden words to complete each level. Your game remains playable offline.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : Colors.black54)),
      ])),
    );
  }
}


class _WheelGuidePainter extends CustomPainter {
  const _WheelGuidePainter({required this.center, required this.radius});
  final Offset center;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, paint);
  }
  @override
  bool shouldRepaint(covariant _WheelGuidePainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.radius != radius;
}


class _WordClue {
  const _WordClue(this.word, this.clue, this.reference);
  final String word;
  final String clue;
  final String reference;
}

class _ThemePack {
  const _ThemePack(this.title, this.words);
  final String title;
  final List<_WordClue> words;
}
