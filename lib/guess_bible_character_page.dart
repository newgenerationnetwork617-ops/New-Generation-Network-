import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuessBibleCharacterPage extends StatefulWidget {
  const GuessBibleCharacterPage({super.key});
  @override
  State<GuessBibleCharacterPage> createState() => _GuessBibleCharacterPageState();
}

class _GuessBibleCharacterPageState extends State<GuessBibleCharacterPage> {
  static const blue = Color(0xFF0B5ED7), gold = Color(0xFFD4AF37);
  static const bank = <_Person>[
    _Person('Noah','Easy',['I was told to build a huge vessel.','My family survived a worldwide flood.','I sent out a raven and a dove.','God gave a rainbow as a covenant sign.'],'Genesis 6–9','Noah obeyed God and built the ark.'),
    _Person('Moses','Easy',['I was placed in a basket as a baby.','I grew up in Pharaoh’s household.','God spoke to me from a burning bush.','I led Israel out of Egypt.'],'Exodus 2–14','God called Moses to lead Israel out of slavery.'),
    _Person('David','Easy',['I was the youngest son in my family.','I cared for sheep before becoming king.','I faced a Philistine champion with a sling.','I defeated Goliath.'],'1 Samuel 16–17','David trusted God when he faced Goliath.'),
    _Person('Esther','Easy',['I was raised by Mordecai.','I became queen in Persia.','I approached the king without being summoned.','I helped save my people from a plot.'],'Esther 2–8','Esther showed courage to protect her people.'),
    _Person('Peter','Easy',['I was a fisherman from Galilee.','My brother was Andrew.','I stepped out of a boat toward Jesus.','Jesus called me a rock.'],'Matthew 4:18–20; 14:28–31; John 1:42','Peter became a leading apostle and witness of Jesus.'),
    _Person('Mary','Easy',['An angel named Gabriel visited me.','I lived in Nazareth.','I was engaged to Joseph.','I became the mother of Jesus.'],'Luke 1:26–38; 2:1–7','Mary accepted God’s calling with humility.'),
    _Person('Joseph','Easy',['I was one of Jacob’s sons.','My brothers sold me into slavery.','I interpreted Pharaoh’s dreams.','I became a ruler in Egypt.'],'Genesis 37; 39–45','Joseph forgave his brothers and helped preserve lives.'),
    _Person('Jonah','Easy',['God sent me to Nineveh.','I tried to flee by ship.','I was swallowed by a great fish.','After three days I went to Nineveh.'],'Jonah 1–3','Jonah learned to obey God’s call.'),
    _Person('Ruth','Easy',['I came from Moab.','I stayed loyal to Naomi.','I gathered grain in Boaz’s field.','I became an ancestor of King David.'],'Ruth 1–4','Ruth showed loyalty and faithfulness.'),
    _Person('Paul','Easy',['I was first known as Saul.','I persecuted followers of Jesus.','I met Jesus on the road to Damascus.','I became an apostle and wrote many letters.'],'Acts 9; 13–28','Paul’s life was transformed and he became a missionary.'),
    _Person('Abraham','Medium',['I was called to leave my homeland.','God promised me many descendants.','My wife was Sarah.','I trusted God when asked to offer Isaac.'],'Genesis 12; 15; 22','Abraham is remembered for his faith.'),
    _Person('Deborah','Medium',['I was a prophetess.','I served as a judge in Israel.','I summoned Barak to lead Israel’s army.','I sang a victory song after Sisera was defeated.'],'Judges 4–5','Deborah courageously guided Israel.'),
    _Person('Gideon','Medium',['An angel found me threshing wheat in a winepress.','I asked God for signs involving a fleece.','My army was reduced to 300 men.','God used me to defeat Midian.'],'Judges 6–7','God showed that victory depended on Him.'),
    _Person('Samuel','Medium',['My mother was Hannah.','I served under Eli as a child.','I heard God call me at night.','I anointed Saul and David as kings.'],'1 Samuel 1–3; 10; 16','Samuel served as prophet and judge.'),
    _Person('Elijah','Medium',['I announced a drought in Ahab’s reign.','Ravens brought me food.','I challenged Baal’s prophets on Mount Carmel.','I heard God in a gentle whisper.'],'1 Kings 17–19','Elijah called Israel back to the Lord.'),
    _Person('Daniel','Medium',['I was taken from Judah to Babylon.','I refused the king’s food.','I interpreted dreams.','I was protected in a den of lions.'],'Daniel 1–6','Daniel remained faithful to God in Babylon.'),
    _Person('Zacchaeus','Medium',['I was a chief tax collector.','I was short in stature.','I climbed a tree to see Jesus.','Jesus visited my home and I promised to repay people.'],'Luke 19:1–10','Meeting Jesus led Zacchaeus to repentance.'),
    _Person('Stephen','Medium',['I was chosen to help needy believers.','I was full of faith and the Holy Spirit.','I spoke before the council.','I was the first Christian martyr recorded in Acts.'],'Acts 6–7','Stephen remained faithful while witnessing about Jesus.'),
    _Person('Lydia','Hard',['I came from Thyatira.','I sold purple cloth.','I listened to Paul near a river in Philippi.','My household was baptised and I welcomed the missionaries.'],'Acts 16:11–15','Lydia became an early believer in Philippi.'),
    _Person('Mephibosheth','Hard',['I was Jonathan’s son and Saul’s grandson.','I became disabled after a childhood fall.','David asked whether anyone from Saul’s family remained.','David restored my land and welcomed me to his table.'],'2 Samuel 4:4; 9','David showed kindness to Jonathan’s son.'),
  ];

  final answer = TextEditingController();
  String difficulty = 'All', mode = 'Quick Guess';
  List<_Person> session = [];
  int index = 0, clue = 0, score = 0, best = 0;
  bool solved = false, finished = false;
  String? message;
  _Person get current => session[index];

  @override
  void initState() { super.initState(); _loadBest(); _start(); }
  @override
  void dispose() { answer.dispose(); super.dispose(); }
  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => best = p.getInt('ngn_guess_character_best') ?? 0);
  }
  List<_Person> get pool => difficulty == 'All' ? List.of(bank) : bank.where((p) => p.level == difficulty).toList();

  void _start() {
    final items = pool;
    if (items.isEmpty) return;
    if (mode == 'Daily Mystery') {
      final d = DateTime.now();
      final seed = d.year * 1000 + d.month * 32 + d.day;
      session = [items[seed % items.length]];
    } else {
      items.shuffle(Random());
      session = mode == 'Quick Guess' ? items.take(5).toList() : items;
    }
    setState(() { index = 0; clue = 0; score = 0; solved = false; finished = false; message = null; answer.clear(); });
  }

  void _submit() {
    if (solved || finished) return;
    final guess = answer.text.trim().toLowerCase();
    if (guess.isEmpty) { setState(() => message = 'Enter a name first.'); return; }
    if (guess == current.name.toLowerCase()) {
      final points = [100, 75, 50, 25][clue];
      setState(() { score += points; solved = true; message = 'Correct! +$points points'; });
    } else if (mode == 'Endless Challenge') {
      setState(() { finished = true; message = 'Incorrect answer. This Endless run has ended.'; });
      _saveBest();
    } else {
      setState(() => message = 'Not quite. Try again or reveal the next clue.');
    }
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    final value = max(best, score);
    await p.setInt('ngn_guess_character_best', value);
    if (mounted) setState(() => best = value);
  }
  void _nextClue() { if (clue < 3) setState(() { clue++; message = null; }); }
  Future<void> _next() async {
    if (index == session.length - 1) { setState(() => finished = true); await _saveBest(); return; }
    setState(() { index++; clue = 0; solved = false; message = null; answer.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Guess the Bible Character')),
      body: SafeArea(child: session.isEmpty ? const Center(child: Text('No characters for this difficulty.')) : finished ? _result(dark) : _game(dark)),
    );
  }

  Widget _game(bool dark) => ListView(padding: const EdgeInsets.all(20), children: [
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [blue, Color(0xFF17418B)]), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.person_search_rounded, color: gold), SizedBox(width: 8), Text('WHO AM I?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), Spacer(), Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16), SizedBox(width: 5), Text('OFFLINE', style: TextStyle(color: Colors.white70, fontSize: 10))]),
        const SizedBox(height: 12),
        Text(mode.toUpperCase(), style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Character ${index + 1} of ${session.length}  •  Score: $score', style: const TextStyle(color: Colors.white)),
      ]),
    ),
    const SizedBox(height: 14),
    Wrap(spacing: 6, children: ['Quick Guess', 'Endless Challenge', 'Daily Mystery'].map((m) => ChoiceChip(label: Text(m), selected: mode == m, onSelected: (_) { setState(() => mode = m); _start(); })).toList()),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(
      initialValue: difficulty,
      decoration: const InputDecoration(labelText: 'Difficulty'),
      items: const ['All', 'Easy', 'Medium', 'Hard'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) { if (v != null) { setState(() => difficulty = v); _start(); } },
    ),
    const SizedBox(height: 20),
    Text('CLUE ${clue + 1} OF 4', style: const TextStyle(color: blue, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: dark ? const Color(0xFF172438) : const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(16)), child: Text(current.clues[clue], style: const TextStyle(fontSize: 18, height: 1.45, fontWeight: FontWeight.w700))),
    const SizedBox(height: 8),
    Text('Points available: ${[100, 75, 50, 25][clue]}', style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
    const SizedBox(height: 16),
    if (solved) ...[
      Text(current.name, style: const TextStyle(fontSize: 27, color: blue, fontWeight: FontWeight.w900)),
      Text(current.explanation, style: const TextStyle(height: 1.45)),
      Text(current.reference, style: const TextStyle(color: blue, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      FilledButton(onPressed: _next, child: Text(index == session.length - 1 ? 'Finish game' : 'Next character')),
    ] else ...[
      TextField(controller: answer, textCapitalization: TextCapitalization.words, onSubmitted: (_) => _submit(), decoration: const InputDecoration(labelText: 'Who is this Bible character?', hintText: 'Enter a name')),
      const SizedBox(height: 10),
      if (message != null) Text(message!, style: const TextStyle(fontWeight: FontWeight.w700)),
      FilledButton(onPressed: _submit, child: const Text('Submit answer')),
      OutlinedButton(onPressed: clue < 3 ? _nextClue : null, child: const Text('Reveal next clue')),
      TextButton(onPressed: () => setState(() { solved = true; message = 'Answer: ${current.name}'; }), child: const Text('Reveal answer')),
    ],
    const SizedBox(height: 16),
    Text('Best score: $best • Wrong answers can be retried except in Endless Challenge.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : Colors.black54)),
  ]);

  Widget _result(bool dark) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.emoji_events_rounded, color: gold, size: 76),
      const SizedBox(height: 16),
      Text(mode == 'Endless Challenge' ? 'ENDLESS RUN ENDED' : 'CHALLENGE COMPLETED', style: const TextStyle(color: blue, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Text('$score points', style: const TextStyle(fontSize: 36, color: blue, fontWeight: FontWeight.w900)),
      Text('Best score: $best', style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: _start, child: const Text('Play again'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to NGN'))),
    ]),
  ));
}

class _Person {
  const _Person(this.name, this.level, this.clues, this.reference, this.explanation);
  final String name, level;
  final List<String> clues;
  final String reference, explanation;
}
