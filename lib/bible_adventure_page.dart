import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bible_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BibleAdventurePage extends StatefulWidget {
  const BibleAdventurePage({super.key});
  @override
  State<BibleAdventurePage> createState() => _BibleAdventurePageState();
}

class _Stage {
  const _Stage(this.title, this.emoji, this.reference, this.question, this.options, this.answer, this.lesson);
  final String title, emoji, reference, question, lesson;
  final List<String> options;
  final int answer;
}

class _BibleAdventurePageState extends State<BibleAdventurePage> {
  static const navy = Color(0xFF071A35), gold = Color(0xFFFFC94A);
  static const bestKey = 'ngn_bible_adventure_best';
  static const progressKey = 'ngn_bible_adventure_stage';
  static const stages = <_Stage>[
    _Stage('The Ark of Promise','🛶','Genesis 6–9','What sign did God place in the clouds as a reminder of His covenant?',['A bright star','A rainbow','A pillar of fire','A dove'],1,'The rainbow was the sign of God’s covenant with Noah and every living creature.'),
    _Stage('The Call of Moses','🔥','Exodus 3','What did Moses see in the wilderness?',['A burning bush that was not consumed','A golden ladder','A river flowing uphill','A cloud of birds'],0,'God called Moses from the burning bush and gave him a mission to lead His people.'),
    _Stage('David’s Courage','🪨','1 Samuel 17','What did David use when he faced Goliath?',['A sword and shield','A spear','A sling and a stone','A bow and arrow'],2,'David trusted the Lord rather than relying on human strength.'),
    _Stage('The Lion’s Den','🦁','Daniel 6','Why was Daniel thrown into the lions’ den?',['He refused to stop praying to God','He left the kingdom','He challenged the king','He lost the royal seal'],0,'Daniel remained faithful in prayer, and God protected him.'),
    _Stage('Jonah’s Journey','🐋','Jonah 1–3','Which city was Jonah sent to warn?',['Bethlehem','Nineveh','Jericho','Damascus'],1,'God sent Jonah to Nineveh and showed that His mercy reaches those who turn to Him.'),
    _Stage('Esther’s Brave Choice','👑','Esther 4–7','Who encouraged Esther to speak to the king for her people?',['Haman','Mordecai','Nehemiah','Ezra'],1,'Esther acted courageously at a critical moment to help protect her people.'),
    _Stage('The First Christmas','⭐','Luke 2:1–20','Where was baby Jesus laid after His birth?',['In a palace bed','In a fishing boat','In a manger','In the temple'],2,'Jesus was born in humble surroundings. The good news was announced to shepherds.'),
    _Stage('The Wedding at Cana','🍇','John 2:1–11','What did Jesus turn water into?',['Oil','Milk','Wine','Honey'],2,'At Cana, Jesus revealed His glory through His first recorded sign.'),
    _Stage('The Good Samaritan','🤝','Luke 10:25–37','Who acted as a neighbour to the injured traveller?',['A priest','A Levite','A Samaritan','A merchant'],2,'Jesus taught that being a neighbour means showing practical mercy to others.'),
    _Stage('The Lost Son','🏡','Luke 15:11–32','How did the father respond when his younger son returned?',['He welcomed him with compassion','He sent him away','He refused to speak','He asked him to leave'],0,'The parable shows the joy of repentance and the Father’s compassion.'),
    _Stage('The Empty Tomb','🌅','Matthew 28:1–10','What message did the angel give the women at the tomb?',['Jesus is still here','He is risen','The tomb is closed forever','Return next month'],1,'The resurrection is at the heart of the Christian faith: Jesus is risen.'),
    _Stage('Pentecost','🕊️','Acts 2:1–4','What happened when the Holy Spirit came upon the disciples?',['They spoke in other languages','They left Jerusalem','The temple disappeared','The sea became calm'],0,'At Pentecost, the disciples were empowered to witness about Jesus.'),
  ];

  final List<_Stage> _offlineStages = [];
  List<_Stage> get allStages => [...stages, ..._offlineStages];

  int stage = 0, score = 0, best = 0;
  int? selected;
  bool answered = false, finished = false, loading = true;

  @override
  void initState() { super.initState(); _restore(); }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    best = prefs.getInt(bestKey) ?? 0;
    await _loadOfflineChallenges();
    if (!mounted) return;
    final savedStage = prefs.getInt(progressKey) ?? 0;
    setState(() {
      stage = savedStage.clamp(0, allStages.length - 1);
      loading = false;
    });
  }

  Future<void> _loadOfflineChallenges() async {
    // Add 988 verse-based stages to the 12 hand-authored story stages.
    // Every prompt, answer and reference is built from Bible files bundled
    // inside the app, so the full 1,000-stage adventure works offline.
    try {
      final repository = BibleRepository();
      final verses = <({String reference, String text})>[];
      for (final bookName in repository.bookNames) {
        final raw = await rootBundle.loadString('assets/bible/books/$bookName.json');
        final book = BibleBook.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        for (final chapter in book.chapters) {
          for (final verse in chapter.verses) {
            final text = verse.text.trim();
            if (text.split(RegExp(r'\s+')).length < 5) continue;
            verses.add((
              reference: '${book.name} ${chapter.number}:${verse.number}',
              text: text,
            ));
          }
        }
      }
      if (verses.length < 988) return;
      final step = verses.length / 988;
      final selected = List.generate(
        988,
        (index) => verses[(index * step).floor()],
      );
      for (var i = 0; i < selected.length; i++) {
        final item = selected[i];
        final correctIndex = i % 4;
        final options = <String>[];
        var offset = 1;
        while (options.length < 3) {
          final candidate = verses[(i * 37 + offset * 113) % verses.length].reference;
          if (candidate != item.reference && !options.contains(candidate)) {
            options.add(candidate);
          }
          offset++;
        }
        options.insert(correctIndex, item.reference);
        final excerpt = item.text.length > 180
            ? '${item.text.substring(0, 177)}…'
            : item.text;
        _offlineStages.add(_Stage(
          'Scripture Trail ${i + 1}',
          '📜',
          'SCRIPTURE CHALLENGE',
          'Which Bible reference contains this passage?\n“$excerpt”',
          options,
          correctIndex,
          'This passage is from ${item.reference}. Read the surrounding verses to understand its full context.',
        ));
      }
    } catch (_) {
      // The 12 hand-authored story stages remain as a safe fallback.
    }
  }

  void _choose(int index) {
    if (answered) return;
    setState(() { selected = index; answered = true; if (index == allStages[stage].answer) score += 100; });
  }

  Future<void> _next() async {
    if (stage == allStages.length - 1) {
      final p = await SharedPreferences.getInstance();
      if (score > best) {
        best = score;
        await p.setInt(bestKey, best);
      }
      await p.setInt(progressKey, 0);
      if (mounted) setState(() => finished = true);
    } else if (mounted) {
      setState(() { stage++; selected = null; answered = false; });
      final p = await SharedPreferences.getInstance();
      await p.setInt(progressKey, stage);
    }
  }

  Future<void> _restart() async {
    setState(() {
      stage = 0;
      score = 0;
      selected = null;
      answered = false;
      finished = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(progressKey, 0);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: navy, body: Center(child: CircularProgressIndicator(color: gold)));
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: const Text('Bible Adventure', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('★ $best', style: const TextStyle(color: gold, fontWeight: FontWeight.w900))))]),
      body: SafeArea(child: finished ? _finish() : _game()),
    );
  }

  Widget _game() {
    final s = allStages[stage];
    return ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 28), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('CHALLENGE ${stage + 1} OF ${allStages.length}', style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        Text('$score PTS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: (stage + 1) / allStages.length, minHeight: 8, backgroundColor: Colors.white12, color: gold)),
      const SizedBox(height: 20),
      Container(height: 205, decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF2457A6), Color(0xFF102B53), Color(0xFF09172D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: gold.withValues(alpha: .42)),
        boxShadow: [BoxShadow(color: const Color(0xFF1746A2).withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 10))]),
        child: Stack(children: [
          Positioned(right: -12, top: -25, child: Icon(Icons.auto_awesome, size: 150, color: Colors.white.withValues(alpha: .05))),
          const Positioned(left: 18, top: 16, child: Text('NGN • SCRIPTURE QUEST', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
          Center(child: Text(s.emoji, style: const TextStyle(fontSize: 84))),
          Positioned(left: 20, right: 20, bottom: 17, child: Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900))),
        ])),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(19), decoration: BoxDecoration(color: const Color(0xFF102644), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .09))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.menu_book_rounded, color: gold, size: 17), const SizedBox(width: 7), Text(s.reference, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 13),
          Text(s.question, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.35)),
          const SizedBox(height: 17),
          ...List.generate(s.options.length, (i) {
            final correct = i == s.answer, chosen = selected == i;
            final fill = !answered ? const Color(0xFF193657) : correct ? const Color(0xFF145B48) : chosen ? const Color(0xFF713B43) : const Color(0xFF193657);
            final outline = !answered ? Colors.white.withValues(alpha: .10) : correct ? const Color(0xFF52D6A0) : chosen ? const Color(0xFFFF8B8B) : Colors.white.withValues(alpha: .06);
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: fill, borderRadius: BorderRadius.circular(14),
              child: InkWell(borderRadius: BorderRadius.circular(14), onTap: answered ? null : () => _choose(i),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: outline, width: 1.2)),
                  child: Row(children: [
                    Container(width: 29, height: 29, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(9)), child: Text(String.fromCharCode(65 + i), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 12), Expanded(child: Text(s.options[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.3))),
                    if (answered && correct) const Icon(Icons.check_circle_rounded, color: Color(0xFF70E2B3)),
                    if (answered && chosen && !correct) const Icon(Icons.cancel_rounded, color: Color(0xFFFF9A9A)),
                  ]))))); }),
          if (answered) ...[
            const SizedBox(height: 5),
            Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFF0B3D39), borderRadius: BorderRadius.circular(13)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_outline_rounded, color: gold), const SizedBox(width: 9),
                Expanded(child: Text(s.lesson, style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 12))),
              ])),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _next,
              style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 15)),
              icon: Icon(stage == allStages.length - 1 ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded),
              label: Text(stage == allStages.length - 1 ? 'COMPLETE ADVENTURE' : 'CONTINUE JOURNEY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)))),
          ],
        ])),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.offline_bolt_rounded, color: Color(0xFF65D6A8), size: 16), const SizedBox(width: 6),
        Text('PLAYABLE OFFLINE • BEST SCORE SAVED ON THIS DEVICE', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .5)),
      ]),
    ]);
  }

  Widget _finish() => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Container(width: double.infinity, padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF1C4D86), Color(0xFF102644), Color(0xFF09172D)], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: gold.withValues(alpha: .45))),
    child: Column(children: [
      const Text('🏆', style: TextStyle(fontSize: 76)), const SizedBox(height: 12),
      const Text('ADVENTURE COMPLETE!', textAlign: TextAlign.center, style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 9), const Text('You have travelled through these Bible stories. Keep the lessons in your heart.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.5)),
      const SizedBox(height: 22), Text('$score', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
      const Text('POINTS EARNED', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      const SizedBox(height: 22), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _restart, style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 15)), icon: const Icon(Icons.replay_rounded), label: const Text('PLAY AGAIN', style: TextStyle(fontWeight: FontWeight.w900)))),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('BACK TO GAMES', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))),
    ]))));
}
