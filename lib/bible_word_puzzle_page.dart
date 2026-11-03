import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline Bible word puzzle using a bundled word bank.
class BibleWordPuzzlePage extends StatefulWidget {
  const BibleWordPuzzlePage({super.key});

  @override
  State<BibleWordPuzzlePage> createState() => _BibleWordPuzzlePageState();
}

class _BibleWordPuzzlePageState extends State<BibleWordPuzzlePage> {
  static const _blue = Color(0xFF0B5ED7);
  static const _gold = Color(0xFFD4AF37);
  static const _bestKey = 'ngn_bible_word_puzzle_best';

  static const List<_WordPuzzle> _bank = [
    _WordPuzzle('NOAH', 'The man who built an ark by God’s instruction.', 'Genesis 6:13–22', 'God instructed Noah to build an ark before the flood.'),
    _WordPuzzle('MOSES', 'God called this man to lead Israel out of Egypt.', 'Exodus 3:10', 'Moses led the Israelites out of Egypt.'),
    _WordPuzzle('DAVID', 'The young shepherd who defeated Goliath.', '1 Samuel 17:45–50', 'David trusted God when he faced Goliath.'),
    _WordPuzzle('ESTHER', 'The queen who showed courage to help her people.', 'Esther 4:14–16', 'Esther risked approaching the king to plead for her people.'),
    _WordPuzzle('RUTH', 'The woman who remained loyal to Naomi.', 'Ruth 1:16–17', 'Ruth chose to stay with Naomi and follow her God.'),
    _WordPuzzle('PETER', 'The disciple who stepped out of a boat toward Jesus.', 'Matthew 14:28–31', 'Peter walked on the water toward Jesus.'),
    _WordPuzzle('PAUL', 'The apostle who wrote many letters in the New Testament.', 'Romans 1:1; 2 Peter 3:15–16', 'Paul served as an apostle and wrote letters to early churches.'),
    _WordPuzzle('JONAH', 'The prophet who was sent to Nineveh.', 'Jonah 1:1–3', 'God sent Jonah to deliver a message to Nineveh.'),
    _WordPuzzle('MARY', 'The mother of Jesus.', 'Luke 1:26–31', 'Mary was chosen to be the mother of Jesus.'),
    _WordPuzzle('JOSEPH', 'The son of Jacob who became a leader in Egypt.', 'Genesis 41:39–41', 'Joseph interpreted Pharaoh’s dreams and was appointed over Egypt.'),
    _WordPuzzle('GOLIATH', 'The Philistine warrior defeated by David.', '1 Samuel 17:4–50', 'David defeated Goliath while trusting in the Lord.'),
    _WordPuzzle('JERICHO', 'The city whose walls fell after Israel obeyed God.', 'Joshua 6:1–20', 'The walls of Jericho fell after Israel followed God’s instructions.'),
    _WordPuzzle('BETHLEHEM', 'The town where Jesus was born.', 'Luke 2:4–7', 'Jesus was born in Bethlehem.'),
    _WordPuzzle('GALILEE', 'The region where Jesus carried out much of His ministry.', 'Matthew 4:23–25', 'Jesus taught and healed throughout Galilee.'),
    _WordPuzzle('SAMUEL', 'The prophet who anointed Israel’s first two kings.', '1 Samuel 10:1; 16:13', 'Samuel anointed Saul and later David.'),
    _WordPuzzle('ABRAHAM', 'The man God called to leave his country and whom He promised many descendants.', 'Genesis 12:1–3', 'God called Abraham and made a covenant promise to him.'),
    _WordPuzzle('ISAAC', 'The son promised to Abraham and Sarah.', 'Genesis 21:1–3', 'Sarah gave birth to Isaac as God had promised.'),
    _WordPuzzle('JACOB', 'The son of Isaac whose name was changed to Israel.', 'Genesis 32:27–28', 'God gave Jacob the name Israel.'),
    _WordPuzzle('ELIJAH', 'The prophet who challenged the prophets of Baal on Mount Carmel.', '1 Kings 18:20–39', 'Elijah called the people to recognize the Lord as God.'),
    _WordPuzzle('TIMOTHY', 'A young coworker of Paul who received two New Testament letters.', '1 Timothy 1:2; 2 Timothy 1:2', 'Paul addressed letters to Timothy, his trusted coworker.'),
    _WordPuzzle('Lazarus', 'The friend of Jesus whom He raised from the dead.', 'John 11:1–44', 'Jesus called Lazarus out of the tomb.'),
    _WordPuzzle('ANDREW', 'The disciple who brought his brother Simon Peter to Jesus.', 'John 1:40–42', 'Andrew brought Simon to meet Jesus.'),
    _WordPuzzle('MARTHA', 'The sister of Mary and Lazarus who welcomed Jesus into her home.', 'Luke 10:38–42; John 11:1', 'Martha welcomed Jesus and served Him.'),
    _WordPuzzle('PHILIP', 'The disciple who told Nathanael about Jesus.', 'John 1:43–46', 'Philip invited Nathanael to come and see Jesus.'),
    _WordPuzzle('ZACCHAEUS', 'The chief tax collector who climbed a tree to see Jesus.', 'Luke 19:1–10', 'Zacchaeus climbed a sycamore tree and later welcomed Jesus.'),
    _WordPuzzle('BARNABAS', 'The believer whose name means son of encouragement.', 'Acts 4:36–37', 'Barnabas was known for encouragement and generosity.'),
    _WordPuzzle('GABRIEL', 'The angel who announced the birth of John and Jesus.', 'Luke 1:11–19, 26–31', 'Gabriel delivered messages about the births of John and Jesus.'),
    _WordPuzzle('SAMSON', 'The judge known for extraordinary strength.', 'Judges 13:24–25; 16:17', 'Samson was set apart to God and given great strength.'),
    _WordPuzzle('DEBORAH', 'The prophetess and judge who led Israel.', 'Judges 4:4–9', 'Deborah served as a judge and gave guidance to Israel.'),
    _WordPuzzle('NEHEMIAH', 'The leader who helped rebuild Jerusalem’s wall.', 'Nehemiah 2:17–18; 6:15', 'Nehemiah led the people in rebuilding Jerusalem’s wall.'),
  ];

  final _answerController = TextEditingController();
  final _random = Random();
  late List<_WordPuzzle> _session;
  int _index = 0;
  int _score = 0;
  int _best = 0;
  int _attempts = 0;
  bool _revealed = false;
  bool _finished = false;
  String? _message;
  String _scrambledLetters = '';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _newGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = prefs.getInt(_bestKey) ?? 0);
  }

  String _makeScramble(String word) {
    final letters = word.toUpperCase().split('');
    for (var i = 0; i < 12; i++) {
      letters.shuffle(_random);
      if (letters.join() != word.toUpperCase()) break;
    }
    return letters.join('  ');
  }

  void _newGame() {
    final list = List<_WordPuzzle>.from(_bank)..shuffle(_random);
    final nextSession = list.take(10).toList();
    setState(() {
      _session = nextSession;
      _scrambledLetters = _makeScramble(nextSession.first.word);
      _index = 0;
      _score = 0;
      _attempts = 0;
      _revealed = false;
      _finished = false;
      _message = null;
      _answerController.clear();
    });
  }


  void _checkAnswer() {
    if (_revealed || _finished) return;
    final guess = _answerController.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (guess.isEmpty) {
      setState(() => _message = 'Type your answer first.');
      return;
    }
    final correct = guess == _session[_index].word.toUpperCase();
    setState(() {
      _attempts++;
      if (correct) {
        final points = _attempts == 1 ? 10 : _attempts == 2 ? 7 : 5;
        _score += points;
        _revealed = true;
        _message = 'Correct! +$points points';
      } else {
        _message = 'Not quite. Try again — you have another attempt.';
      }
    });
  }

  Future<void> _next() async {
    if (_index == _session.length - 1) {
      final prefs = await SharedPreferences.getInstance();
      final best = max(_best, _score);
      await prefs.setInt(_bestKey, best);
      if (!mounted) return;
      setState(() {
        _best = best;
        _finished = true;
      });
      return;
    }
    setState(() {
      _index++;
      _scrambledLetters = _makeScramble(_session[_index].word);
      _attempts = 0;
      _revealed = false;
      _message = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Word Puzzle'),
        actions: [
          IconButton(tooltip: 'Restart game', onPressed: _newGame, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(child: _finished ? _result(dark) : _game(dark)),
    );
  }

  Widget _game(bool dark) {
    final puzzle = _session[_index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_blue, Color(0xFF17418B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.extension_rounded, color: _gold),
              SizedBox(width: 9),
              Text('UNSCRAMBLE THE WORD', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .8)),
              Spacer(),
              Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 5),
              Text('OFFLINE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 18),
            Text('PUZZLE ${_index + 1} OF ${_session.length}', style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 7),
            Text('Score: $_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            ClipRRect(borderRadius: const BorderRadius.circular(20), child: LinearProgressIndicator(value: (_index + 1) / _session.length, minHeight: 7, backgroundColor: Colors.white24, color: _gold)),
          ]),
        ),
        const SizedBox(height: 22),
        Text('CLUE', style: const TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(puzzle.clue, style: const TextStyle(fontSize: 19, height: 1.45, fontWeight: FontWeight.w700)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(color: dark ? const Color(0xFF172438) : const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(17), border: Border.all(color: _blue.withValues(alpha: .2))),
          child: Column(children: [
            const Text('MIXED-UP LETTERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: _blue)),
            const SizedBox(height: 14),
            Text(_scrambledLetters, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 2.2, color: _blue)),
            const SizedBox(height: 8),
            Text('${puzzle.word.length} letters', style: TextStyle(color: dark ? Colors.white70 : Colors.black54, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _answerController,
          enabled: !_revealed,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _checkAnswer(),
          decoration: const InputDecoration(labelText: 'Your answer', hintText: 'Type the Bible word or name'),
        ),
        const SizedBox(height: 12),
        if (_message != null)
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: _revealed ? const Color(0xFF1B8E52).withValues(alpha: .10) : const Color(0xFFD4AF37).withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
            child: Text(_message!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        if (_revealed) ...[
          const SizedBox(height: 12),
          Text(puzzle.explanation, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 6),
          Text(puzzle.reference, style: const TextStyle(color: _blue, fontWeight: FontWeight.w900)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _revealed ? _next : _checkAnswer,
          child: Text(_revealed ? (_index == _session.length - 1 ? 'Finish game' : 'Next puzzle') : 'Check answer'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _revealed ? null : () => setState(() {
            _revealed = true;
            _message = 'Answer: ${puzzle.word}';
          }),
          icon: const Icon(Icons.lightbulb_outline_rounded),
          label: const Text('Reveal answer'),
        ),
        const SizedBox(height: 8),
        Text('First try: 10 points • Second try: 7 points • Later tries: 5 points', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : Colors.black54)),
      ],
    );
  }

  Widget _result(bool dark) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.emoji_events_rounded, color: _gold, size: 76),
        const SizedBox(height: 18),
        const Text('PUZZLES COMPLETED', style: TextStyle(color: _blue, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text('$_score points', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _blue)),
        const SizedBox(height: 8),
        Text('Best score: $_best', style: TextStyle(color: dark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text('Great work! Keep learning the people, places and stories in Scripture.', textAlign: TextAlign.center, style: TextStyle(height: 1.5)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _newGame, icon: const Icon(Icons.replay_rounded), label: const Text('Play again'))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to NGN'))),
      ]),
    ),
  );
}

class _WordPuzzle {
  const _WordPuzzle(this.word, this.clue, this.reference, this.explanation);
  final String word;
  final String clue;
  final String reference;
  final String explanation;
}
