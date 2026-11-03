import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first Bible Trivia. Questions are bundled with the app so the
/// game remains playable without a network connection.
class BibleTriviaPage extends StatefulWidget {
  const BibleTriviaPage({super.key});

  @override
  State<BibleTriviaPage> createState() => _BibleTriviaPageState();
}

class _BibleTriviaPageState extends State<BibleTriviaPage> {
  static const _blue = Color(0xFF0B5ED7);
  static const _gold = Color(0xFFD4AF37);
  static const _highScoreKey = 'ngn_bible_trivia_high_score';

  final Map<String, List<_TriviaQuestion>> _questions = {
    'Easy': const [
      _TriviaQuestion('Who built the ark?', ['Moses', 'Noah', 'Abraham', 'David'], 1, 'Genesis 6:13–22', 'God instructed Noah to build an ark before the flood.'),
      _TriviaQuestion('Who was the mother of Jesus?', ['Martha', 'Elizabeth', 'Mary', 'Ruth'], 2, 'Luke 1:26–31', 'Mary was chosen to be the mother of Jesus.'),
      _TriviaQuestion('Where was Jesus born?', ['Nazareth', 'Jerusalem', 'Bethlehem', 'Jericho'], 2, 'Luke 2:4–7', 'Jesus was born in Bethlehem.'),
      _TriviaQuestion('Who defeated Goliath?', ['Jonathan', 'David', 'Saul', 'Samuel'], 1, '1 Samuel 17:45–50', 'David trusted God and defeated Goliath with a sling and a stone.'),
      _TriviaQuestion('How many disciples did Jesus choose?', ['10', '11', '12', '13'], 2, 'Luke 6:13–16', 'Jesus chose twelve apostles.'),
      _TriviaQuestion('Who was swallowed by a great fish?', ['Jonah', 'Job', 'Joseph', 'Elijah'], 0, 'Jonah 1:17', 'Jonah spent three days and three nights inside the great fish.'),
      _TriviaQuestion('What is the first book of the Bible?', ['Exodus', 'Psalms', 'Matthew', 'Genesis'], 3, 'Genesis 1:1', 'Genesis is the first book of the Bible.'),
      _TriviaQuestion('Who received the Ten Commandments?', ['Aaron', 'Moses', 'Joshua', 'Caleb'], 1, 'Exodus 31:18', 'God gave the tablets of the covenant to Moses.'),
      _TriviaQuestion('What did Jesus turn water into?', ['Oil', 'Milk', 'Wine', 'Juice'], 2, 'John 2:1–11', 'Jesus performed His first recorded sign at a wedding in Cana.'),
      _TriviaQuestion('Who was known for great strength and long hair?', ['Samson', 'Gideon', 'Esau', 'Boaz'], 0, 'Judges 16:17', 'Samson’s strength was connected to his Nazirite vow.'),
    ],
    'Medium': const [
      _TriviaQuestion('Which queen visited Solomon to test his wisdom?', ['Queen Esther', 'Queen of Sheba', 'Queen Jezebel', 'Queen Vashti'], 1, '1 Kings 10:1–3', 'The queen of Sheba came with difficult questions for Solomon.'),
      _TriviaQuestion('Who interpreted the writing on the wall for Belshazzar?', ['Ezekiel', 'Jeremiah', 'Daniel', 'Nehemiah'], 2, 'Daniel 5:13–28', 'Daniel explained the meaning of the writing.'),
      _TriviaQuestion('Which woman hid the Israelite spies in Jericho?', ['Deborah', 'Rahab', 'Jael', 'Abigail'], 1, 'Joshua 2:1–6', 'Rahab welcomed and hid the spies.'),
      _TriviaQuestion('Who was the first king of Israel?', ['David', 'Solomon', 'Saul', 'Samuel'], 2, '1 Samuel 10:1', 'Samuel anointed Saul as Israel’s first king.'),
      _TriviaQuestion('On which island did John receive the Revelation?', ['Crete', 'Cyprus', 'Patmos', 'Malta'], 2, 'Revelation 1:9', 'John said he was on the island called Patmos.'),
      _TriviaQuestion('Who was Ruth’s mother-in-law?', ['Hannah', 'Naomi', 'Miriam', 'Leah'], 1, 'Ruth 1:3–4', 'Ruth remained devoted to Naomi after their husbands died.'),
      _TriviaQuestion('Which prophet challenged the prophets of Baal on Mount Carmel?', ['Elisha', 'Isaiah', 'Elijah', 'Nathan'], 2, '1 Kings 18:20–39', 'Elijah called Israel to recognize the Lord as God.'),
      _TriviaQuestion('Who replaced Judas among the apostles?', ['Barnabas', 'Silas', 'Matthias', 'Timothy'], 2, 'Acts 1:23–26', 'Matthias was chosen to take Judas’s place among the eleven.'),
      _TriviaQuestion('What was the occupation of Lydia, whom Paul met in Philippi?', ['Tentmaker', 'Seller of purple cloth', 'Fisherwoman', 'Tax collector'], 1, 'Acts 16:14', 'Lydia was a seller of purple goods from Thyatira.'),
      _TriviaQuestion('Which judge made a vow before fighting the Ammonites?', ['Gideon', 'Jephthah', 'Samson', 'Ehud'], 1, 'Judges 11:30–31', 'Jephthah made a vow before going into battle.'),
    ],
    'Hard': const [
      _TriviaQuestion('Who was the father of Bezalel, the craftsman of the tabernacle?', ['Hur', 'Uri', 'Oholiab', 'Ithamar'], 1, 'Exodus 31:2', 'Bezalel was the son of Uri, son of Hur, of the tribe of Judah.'),
      _TriviaQuestion('Which king of Judah was eight years old when he began to reign?', ['Josiah', 'Joash', 'Uzziah', 'Hezekiah'], 0, '2 Kings 22:1', 'Josiah began to reign at eight years old.'),
      _TriviaQuestion('Who was the father of John the Baptist?', ['Simeon', 'Zechariah', 'Cleopas', 'Jairus'], 1, 'Luke 1:5–13', 'Zechariah was a priest and the father of John.'),
      _TriviaQuestion('In which city were believers first called Christians?', ['Jerusalem', 'Ephesus', 'Antioch', 'Corinth'], 2, 'Acts 11:26', 'The disciples were first called Christians in Antioch.'),
      _TriviaQuestion('Who was the prophetess consulted during King Josiah’s reign?', ['Huldah', 'Anna', 'Miriam', 'Deborah'], 0, '2 Kings 22:14', 'Huldah gave the Lord’s message to the king’s messengers.'),
      _TriviaQuestion('Which man fell from a window while Paul was preaching?', ['Tychicus', 'Eutychus', 'Titus', 'Trophimus'], 1, 'Acts 20:9', 'Eutychus fell from the third story and was restored to life.'),
      _TriviaQuestion('Who was the father of the prophet Samuel?', ['Elkanah', 'Abimelech', 'Boaz', 'Jesse'], 0, '1 Samuel 1:1–20', 'Samuel was born to Hannah and Elkanah.'),
      _TriviaQuestion('Which judge was left-handed and killed King Eglon?', ['Shamgar', 'Ehud', 'Othniel', 'Tola'], 1, 'Judges 3:15–22', 'Ehud was a left-handed Benjamite who delivered Israel from Moab.'),
      _TriviaQuestion('Who was the high priest when young Samuel served at the tabernacle?', ['Abiathar', 'Eli', 'Zadok', 'Aaron'], 1, '1 Samuel 1:9; 2:11', 'Samuel served the Lord under Eli the priest.'),
      _TriviaQuestion('Which coworker did Paul describe as “the beloved physician”?', ['Luke', 'Mark', 'Titus', 'Aristarchus'], 0, 'Colossians 4:14', 'Paul identifies Luke as the beloved physician.'),
    ],
  };

  String _difficulty = 'Easy';
  List<_TriviaQuestion> _round = [];
  int _index = 0;
  int _score = 0;
  int _highScore = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startRound();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _highScore = prefs.getInt(_highScoreKey) ?? 0);
  }

  void _startRound() {
    final pool = List<_TriviaQuestion>.from(_questions[_difficulty]!);
    pool.shuffle(Random());
    setState(() {
      _round = pool.take(10).toList();
      _index = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _finished = false;
    });
  }

  Future<void> _submitAnswer() async {
    if (_selected == null || _answered || _finished) return;
    final correct = _selected == _round[_index].answerIndex;
    setState(() {
      _answered = true;
      if (correct) _score += 10;
    });
    if (_index == _round.length - 1) {
      final prefs = await SharedPreferences.getInstance();
      final best = max(_highScore, _score);
      await prefs.setInt(_highScoreKey, best);
      if (mounted) setState(() => _highScore = best);
    }
  }

  void _nextQuestion() {
    if (_index == _round.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Trivia'),
        actions: [
          IconButton(
            tooltip: 'Restart quiz',
            onPressed: _startRound,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _finished ? _buildResult(dark) : _buildQuiz(dark),
      ),
    );
  }

  Widget _buildQuiz(bool dark) {
    final question = _round[_index];
    final progress = (_index + 1) / _round.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, Color(0xFF17418B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              const Icon(Icons.menu_book_rounded, color: _gold),
              const SizedBox(width: 8),
              const Text('KNOW THE WORD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const Spacer(),
              const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              const Text('OFFLINE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 18),
            Text(_difficulty.toUpperCase(), style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('Question ${_index + 1} of ${_round.length}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: Colors.white24, color: _gold),
            ),
            const SizedBox(height: 12),
            Text('Score: $_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          const Text('DIFFICULTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
          const Spacer(),
          DropdownButton<String>(
            value: _difficulty,
            underline: const SizedBox.shrink(),
            items: _questions.keys.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
            onChanged: _index == 0 && !_answered
                ? (value) {
                    if (value == null) return;
                    setState(() => _difficulty = value);
                    _startRound();
                  }
                : null,
          ),
        ]),
        const SizedBox(height: 14),
        Text(question.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 20),
        ...List.generate(question.options.length, (i) {
          final isCorrect = i == question.answerIndex;
          final isSelected = _selected == i;
          Color? fill;
          Color? border;
          if (_answered && isCorrect) {
            fill = const Color(0xFF1B8E52).withValues(alpha: .10);
            border = const Color(0xFF1B8E52);
          } else if (_answered && isSelected && !isCorrect) {
            fill = const Color(0xFFD32F2F).withValues(alpha: .08);
            border = const Color(0xFFD32F2F);
          } else if (isSelected) {
            fill = _blue.withValues(alpha: .08);
            border = _blue;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _answered ? null : () => setState(() => _selected = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                decoration: BoxDecoration(
                  color: fill ?? (dark ? const Color(0xFF17191D) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border ?? (dark ? const Color(0xFF343941) : const Color(0xFFE1E6EF)), width: border == null ? 1 : 1.7),
                ),
                child: Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _blue.withValues(alpha: .10), borderRadius: BorderRadius.circular(9)),
                    child: Text(String.fromCharCode(65 + i), style: const TextStyle(color: _blue, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(question.options[i], style: const TextStyle(fontWeight: FontWeight.w700))),
                  if (_answered && isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF1B8E52)),
                  if (_answered && isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: Color(0xFFD32F2F)),
                ]),
              ),
            ),
          );
        }),
        if (_answered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF202A36) : const Color(0xFFFFFBEE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: .45)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selected == question.answerIndex ? 'Correct! +10 points' : 'Good try! Keep learning.', style: TextStyle(fontWeight: FontWeight.w900, color: _selected == question.answerIndex ? const Color(0xFF1B8E52) : null)),
              const SizedBox(height: 6),
              Text(question.explanation, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 6),
              Text(question.reference, style: const TextStyle(color: _blue, fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _answered ? _nextQuestion : _selected == null ? null : _submitAnswer,
          child: Text(_answered ? (_index == _round.length - 1 ? 'See my result' : 'Next question') : 'Submit answer'),
        ),
      ],
    );
  }

  Widget _buildResult(bool dark) {
    final perfect = _score == _round.length * 10;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: _gold.withValues(alpha: .16), shape: BoxShape.circle),
            child: Icon(perfect ? Icons.emoji_events_rounded : Icons.school_rounded, color: _gold, size: 48),
          ),
          const SizedBox(height: 22),
          const Text('QUIZ COMPLETED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: _blue)),
          const SizedBox(height: 8),
          const Text('Well done!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text('$_score / ${_round.length * 10}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: _blue)),
          const SizedBox(height: 6),
          Text('Your best score: $_highScore', style: TextStyle(color: dark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(perfect ? 'Excellent! You answered every question correctly.' : 'Keep exploring the Scriptures and try again.', textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _startRound, icon: const Icon(Icons.replay_rounded), label: const Text('Play again'))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to NGN'))),
        ]),
      ),
    );
  }
}

class _TriviaQuestion {
  const _TriviaQuestion(this.question, this.options, this.answerIndex, this.reference, this.explanation);

  final String question;
  final List<String> options;
  final int answerIndex;
  final String reference;
  final String explanation;
}
