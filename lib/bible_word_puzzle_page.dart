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
  static const List<_CookiePuzzle> _bank = [
    _CookiePuzzle('John 3:16', 'GODLOVE', ['GOD','LOVE'], ['The One who gave His only begotten Son','The great gift God shows to the world'], 'verse', 'Easy'),
    _CookiePuzzle('Psalm 23:1', 'SHEPHERD', ['SHEEP','HERD','SHE','RED'], ['Animals cared for by a shepherd','A group of animals under a keeper','A pronoun found in SHEPHERD','A colour hidden in the letters'], 'verse', 'Easy'),
    _CookiePuzzle('Philippians 4:13', 'CHRISTGIVES', ['CHRIST','GIVES','GIVE','RISE'], ['The title of Jesus in this reference','What Christ does for strength','To present or offer','To get up or stand'], 'verse', 'Medium'),
    _CookiePuzzle('Proverbs 3:5', 'TRUSTHEART', ['TRUST','HEART','EARTH','TEAR'], ['Rely confidently on God','The inner centre of a person','The world we live on','A drop from the eye'], 'verse', 'Easy'),
    _CookiePuzzle('Matthew 5:14', 'LIGHTCITY', ['LIGHT','CITY','LIT','TIC'], ['What Jesus calls His followers','A populated place','Past tense of light','A small involuntary movement'], 'verse', 'Medium'),
    _CookiePuzzle('Galatians 5:22', 'SPIRITJOYLOVEPEACE', ['SPIRIT','JOY','LOVE','PEACE','RICE','LACE'], ['The Holy ___','A fruit of the Spirit','The greatest commandment','Freedom from conflict','A common grain','A cord or fine fabric'], 'verse', 'Hard'),
    _CookiePuzzle('Genesis 1:1', 'BEGINNING', ['BEGIN','GIN','INN','NINE'], ['To start','A spirit or liquor (short word)','A place to stay','The number after eight'], 'verse', 'Medium'),
    _CookiePuzzle('Psalm 119:105', 'WORDLAMPFEETPATH', ['WORD','LAMP','FEET','PATH','HEAT','WARM'], ['The message of God','A light source','Body parts used for walking','A way or route','High temperature','Comfortably warm'], 'verse', 'Hard'),
    _CookiePuzzle('1 Corinthians 13:13', 'FAITHHOPELOVE', ['FAITH','HOPE','LOVE','HEAL','PILE'], ['Trust in God','Confident expectation','Care and devotion','To make well','A stack of things'], 'verse', 'Medium'),
    _CookiePuzzle('Exodus 14:14', 'LORDFIGHTPEACE', ['LORD','FIGHT','PEACE','RIDE','GIFT'], ['A name used for God','A struggle or battle','Calm and harmony','Travel on a horse','Something freely given'], 'verse', 'Hard'),
    _CookiePuzzle('Bible places', 'JERUSALEMBETHLEHEM', ['JERUSALEM','BETHLEHEM','SALEM','THEME','REAL'], ['The city where Jesus was crucified and rose','The town where Jesus was born','A name associated with Jerusalem in Genesis 14','The subject of a lesson','Genuine, not imaginary'], 'theme', 'Hard'),
    _CookiePuzzle('People of faith', 'ABRAHAMMOSESRUTH', ['ABRAHAM','MOSES','RUTH','HAM','MARS'], ['The patriarch who left his homeland by faith','Led Israel out of Egypt','Stayed loyal to Naomi','A son of Noah','A planet (extra challenge word)'], 'theme', 'Medium'),
    _CookiePuzzle('Books of the Bible', 'MATTHEWMARKLUKEJOHN', ['MATTHEW','MARK','LUKE','JOHN','HARK'], ['First Gospel in the New Testament order','Second Gospel','Third Gospel','Fourth Gospel','Listen carefully'], 'theme', 'Hard'),
    _CookiePuzzle('Fruit of the Spirit', 'GOODNESSKINDNESS', ['GOODNESS','KINDNESS','GOOD','KIND','NEST'], ['A quality of moral goodness','Being considerate and caring','Opposite of bad','Caring and generous','A bird’s home'], 'theme', 'Medium'),
    _CookiePuzzle('Acts 1:8', 'POWERSPIRITWITNESS', ['POWER','SPIRIT','WITNESS','WRITE','TIRE'], ['Ability or strength','The Holy ___','One who testifies','Put words on paper','Become weary'], 'verse', 'Hard'),
  ];

  final Random _random = Random();
  final Set<String> _found = {};
  final List<String> _formed = [];
  late _CookiePuzzle _puzzle;
  int _index = 0, _score = 0, _best = 0;
  String _difficulty = 'All';
  String? _message;
  bool _submitted = false;

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
          Text(_formed.isEmpty ? 'Swipe across the letters or tap them to form a word' : _formed.join(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 10),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: List.generate(letters.length, (i) => SizedBox(width: 43, height: 43, child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black87, padding: EdgeInsets.zero, shape: const CircleBorder()),
            onPressed: () => _addLetter(letters[i]),
            child: Text(letters[i], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          )))),
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
