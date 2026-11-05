import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'game_leaderboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuessBibleCharacterPage extends StatefulWidget {
  const GuessBibleCharacterPage({super.key});
  @override
  State<GuessBibleCharacterPage> createState() => _GuessBibleCharacterPageState();
}

class _GuessBibleCharacterPageState extends State<GuessBibleCharacterPage> {
  static const blue = Color(0xFF1746A2), gold = Color(0xFFFFC94A);
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
    _Person('Huldah','Hard',['I was a prophetess in Jerusalem.','King Josiah sent officials to seek the Lord’s guidance through me.','I confirmed the seriousness of the words found in the Book of the Law.','My message is recorded during Josiah’s reforms.'],'2 Kings 22:14–20; 2 Chronicles 34:22–28','Huldah faithfully delivered the Lord’s message during Josiah’s reign.'),
    _Person('Ebed-Melech','Hard',['I served in the royal court of King Zedekiah.','I spoke up when Jeremiah was left in a cistern.','I gathered men and old cloths to help rescue the prophet.','God later sent me a message of protection.'],'Jeremiah 38:7–13; 39:15–18','Ebed-Melech showed courage and compassion by helping Jeremiah.'),
    _Person('Bezalel','Hard',['I came from the tribe of Judah.','My father was Uri and my grandfather was Hur.','God filled me with skill for craftsmanship.','I helped make the tabernacle and its furnishings.'],'Exodus 31:1–11; 35:30–35','Bezalel used God-given skill to help build the tabernacle.'),
    _Person('Onesimus','Hard',['I was connected with Philemon.','Paul wrote a letter concerning me.','Paul described me as formerly unhelpful but now useful.','Paul appealed for me to be welcomed as a brother.'],'Philemon 1:8–21; Colossians 4:9','Onesimus became a valued brother in the faith.'),
    _Person('Epaphroditus','Hard',['I came from the church in Philippi.','I carried support from the believers to Paul.','I became seriously ill while serving Christ.','Paul praised my faithful service and sacrifice.'],'Philippians 2:25–30; 4:18','Epaphroditus served faithfully and risked his life for the work of Christ.'),
    _Person('Shamgar','Hard',['I was one of Israel’s deliverers.','I used an oxgoad in battle.','The Bible records that I struck down six hundred Philistines.','My brief account appears in the book of Judges.'],'Judges 3:31','Shamgar helped deliver Israel from the Philistines.'),

    _Person('Abigail','Medium',['I was married to Nabal.','I met David while he was on his way to confront my household.','I brought food and spoke wisely to prevent bloodshed.','After Nabal died, I became David’s wife.'],'1 Samuel 25','Abigail acted with wisdom and helped prevent needless violence.'),
    _Person('Jonathan','Easy',['I was the son of Israel’s first king.','I made a covenant of friendship with David.','I gave David my robe and weapons.','I remained loyal to David despite my father’s jealousy.'],'1 Samuel 18–20','Jonathan showed loyal friendship to David.'),
    _Person('Elisha','Medium',['I was ploughing when Elijah called me.','I asked for a double portion of Elijah’s spirit.','I healed Naaman after he washed in the Jordan.','I succeeded Elijah as prophet.'],'1 Kings 19:19–21; 2 Kings 2; 5','Elisha continued the prophetic ministry after Elijah.'),
    _Person('Nathan','Medium',['I served as a prophet during David’s reign.','I told the king a story about a rich man and a poor man’s lamb.','I confronted David after his sin with Bathsheba.','I later supported Solomon’s succession.'],'2 Samuel 7; 12; 1 Kings 1','Nathan faithfully delivered God’s message to the king.'),
    _Person('Hezekiah','Hard',['I was a king of Judah who trusted the Lord.','I removed high places and restored temple worship.','I prayed when Jerusalem faced the Assyrian threat.','God gave me fifteen additional years after I became ill.'],'2 Kings 18–20; 2 Chronicles 29–32','Hezekiah sought the Lord during a national crisis.'),
    _Person('Josiah','Hard',['I became king of Judah when I was eight years old.','The Book of the Law was found during temple repairs in my reign.','I humbled myself when its words were read.','I led reforms to restore worship of the Lord.'],'2 Kings 22–23; 2 Chronicles 34–35','Josiah responded humbly to God’s written word.'),
    _Person('Jabez','Hard',['My mother gave me a name connected with sorrow.','I prayed that God would bless me and enlarge my border.','I asked for God’s hand to be with me.','My short account appears in the genealogies of Judah.'],'1 Chronicles 4:9–10','Jabez called on the God of Israel for blessing and protection.'),
    _Person('Barnabas','Medium',['My name means son of encouragement.','I was a Levite from Cyprus.','I supported the early church and introduced Saul to the apostles.','I travelled with Paul on an early missionary journey.'],'Acts 4:36–37; 9:26–27; 13–15','Barnabas encouraged believers and served in mission work.'),
    _Person('Timothy','Easy',['My mother was Eunice and my grandmother was Lois.','Paul called me his son in the faith.','I travelled and served alongside Paul.','Two New Testament letters bear my name.'],'Acts 16:1–3; 2 Timothy 1:5','Timothy became a trusted younger coworker of Paul.'),
    _Person('Silas','Medium',['I was a leader among believers in Jerusalem.','I travelled with Paul after the disagreement about John Mark.','I was imprisoned with Paul in Philippi.','We prayed and sang hymns while in prison.'],'Acts 15:22–40; 16:19–34','Silas served faithfully during the early church’s mission.'),
    _Person('Priscilla','Medium',['I was married to Aquila.','I worked as a tentmaker.','My husband and I travelled with Paul.','We explained the way of God more accurately to Apollos.'],'Acts 18:1–3, 18–26; Romans 16:3–5','Priscilla served with her husband in teaching and ministry.'),
    _Person('Aquila','Medium',['I was a Jewish tentmaker from Pontus.','I was married to Priscilla.','I met Paul in Corinth.','My household hosted a church gathering.'],'Acts 18:1–3; 1 Corinthians 16:19','Aquila partnered with Priscilla and Paul in Christian service.'),
    _Person('Cornelius','Medium',['I was a Roman centurion in Caesarea.','I feared God and gave generously to those in need.','An angel directed me to send for Peter.','The Holy Spirit came upon my household as Peter preached.'],'Acts 10:1–48','Cornelius’s household became an important early Gentile church story.'),
    _Person('Tabitha','Medium',['I was also known by the Greek name Dorcas.','I lived in Joppa.','I was known for doing good works and helping the poor.','Peter prayed and God restored me to life.'],'Acts 9:36–42','Tabitha was known for kindness and generosity.'),
    _Person('Philip the evangelist','Medium',['I was one of the seven chosen to serve in the early church.','I preached in Samaria.','An angel directed me to the road toward Gaza.','I explained Isaiah’s scroll to an Ethiopian official and baptised him.'],'Acts 6:5; 8:4–40; 21:8','Philip shared the good news with people in Samaria and beyond.'),
    _Person('Micaiah son of Imlah','Hard',['I was a prophet summoned by King Ahab.','I did not simply agree with the other court prophets.','I described a vision of the Lord’s heavenly council.','My warning concerned Ahab’s battle at Ramoth-gilead.'],'1 Kings 22:8–28','Micaiah spoke the message he believed the Lord had given him.'),
    _Person('Jehoshaphat','Hard',['I was a king of Judah who sought the Lord.','I sent teachers through the towns to teach the Book of the Law.','I prayed when a great army came against Judah.','The people praised God and saw their enemies defeated.'],'2 Chronicles 17; 20','Jehoshaphat called the people to seek God in a time of danger.'),
    _Person('Barzillai','Hard',['I was an elderly man from Gilead.','I supplied David and his people when they were in need.','David invited me to come to Jerusalem after Absalom’s rebellion.','I asked to remain in my own city because of my age.'],'2 Samuel 17:27–29; 19:31–39','Barzillai showed loyalty and generosity to David.'),

    _Person('Saul','Medium',['I was from the tribe of Benjamin.','Samuel anointed me as Israel’s first king.','I disobeyed God’s instruction concerning Amalek.','I later became jealous of David.'],'1 Samuel 9–15; 18–31','Saul was Israel’s first king, but his disobedience brought serious consequences.'),
    _Person('Rehoboam','Hard',['I was the son of Solomon.','I became king after my father died.','I rejected the elders’ advice and listened to younger advisers.','The kingdom divided during my reign.'],'1 Kings 12:1–24; 2 Chronicles 10','Rehoboam’s harsh response contributed to the division of the kingdom.'),
    _Person('Jeroboam','Hard',['I was given rule over ten tribes after the kingdom divided.','I became the first king of the northern kingdom of Israel.','I set up golden calves at Bethel and Dan.','A prophet from Judah confronted me at the altar.'],'1 Kings 11:26–40; 12:25–33; 13','Jeroboam led Israel into idolatrous worship.'),
    _Person('Asa','Hard',['I was a king of Judah.','I removed many idols and sought the Lord.','I faced an invading army and called on God for help.','Later in life I relied on a foreign king instead of seeking the Lord.'],'1 Kings 15:9–24; 2 Chronicles 14–16','Asa’s reign included reforms and a later failure to rely fully on God.'),
    _Person('Jehu','Hard',['I was anointed king over Israel by a messenger sent by Elisha.','I drove a chariot furiously.','I brought judgment on the house of Ahab.','I destroyed Baal worship in Israel but did not turn fully to the Lord.'],'2 Kings 9–10','Jehu carried out judgment on Ahab’s house, though his own obedience was incomplete.'),
    _Person('Ezra','Medium',['I was a priest and a skilled scribe.','I was devoted to studying and teaching the Law of the Lord.','I travelled from Babylon to Jerusalem.','I helped the people understand the Law after the exile.'],'Ezra 7–10; Nehemiah 8','Ezra taught God’s Law and helped restore the people’s commitment.'),
    _Person('Nehemiah','Medium',['I served as cupbearer to the Persian king.','I heard that Jerusalem’s walls were broken down.','I prayed and asked the king for permission to return.','I led the rebuilding of Jerusalem’s walls despite opposition.'],'Nehemiah 1–6','Nehemiah combined prayer, planning and leadership to rebuild Jerusalem’s walls.'),
    _Person('Elizabeth','Easy',['My husband was Zechariah the priest.','I was a relative of Mary.','I gave birth to John in my old age.','I was filled with the Holy Spirit when Mary visited me.'],'Luke 1:5–25, 39–45, 57–66','Elizabeth became the mother of John the Baptist.'),
    _Person('Zechariah the priest','Medium',['I served as a priest in the division of Abijah.','An angel appeared to me while I served in the temple.','I was told that my wife would have a son named John.','I praised God after my speech was restored.'],'Luke 1:5–23, 57–79','Zechariah was the father of John the Baptist.'),
    _Person('Simeon','Hard',['I was a righteous and devout man in Jerusalem.','The Holy Spirit revealed that I would see the Lord’s Christ before I died.','I took the infant Jesus in my arms at the temple.','I praised God and spoke to Mary about the child’s future.'],'Luke 2:25–35','Simeon recognized Jesus as God’s promised salvation.'),
_Person('Hagar','Medium',['I was an Egyptian servant in Abraham’s household.','I became the mother of Ishmael.','I fled into the wilderness and encountered the angel of the Lord.','God heard the distress of my son.'],'Genesis 16; 21:8–21','God saw Hagar in her distress and provided for her and Ishmael.'),
    _Person('Ishmael','Medium',['I was the son of Abraham and Hagar.','An angel announced my birth before I was born.','God promised to make me into a great nation.','I grew up in the wilderness of Paran.'],'Genesis 16; 17:18–20; 21:8–21','God heard Ishmael and fulfilled His promise concerning him.'),
    _Person('Laban','Medium',['I lived in Haran.','I was the brother of Rebekah.','Jacob worked for me and married my daughters Leah and Rachel.','I made agreements with Jacob concerning his wages.'],'Genesis 24; 29–31','Laban was Jacob’s uncle and father-in-law.'),
    _Person('Potiphar','Medium',['I was an Egyptian officer of Pharaoh.','I bought Joseph after he was taken to Egypt.','I placed Joseph in charge of my household.','My wife falsely accused Joseph.'],'Genesis 39:1–20','Potiphar’s household was where Joseph served before being imprisoned.'),
    _Person('Miriam','Medium',['I was the sister of Moses and Aaron.','I watched over my baby brother near the river.','I helped arrange for our mother to nurse him.','I later led the women in singing after the sea crossing.'],'Exodus 2:1–10; 15:20–21; Numbers 12','Miriam was a prophetess and the sister of Moses and Aaron.'),
    _Person('Caleb','Medium',['I was sent to explore Canaan with eleven other men.','I trusted that God could give Israel the land.','I encouraged the people not to rebel in fear.','At an old age I asked for the hill country promised to me.'],'Numbers 13–14; Joshua 14:6–14','Caleb followed the Lord wholeheartedly and remained confident in His promise.'),
    _Person('Joshua','Easy',['I served as Moses’ assistant.','I was one of the twelve spies sent into Canaan.','I became Israel’s leader after Moses died.','I led the people across the Jordan and around Jericho.'],'Exodus 17:8–14; Numbers 13–14; Joshua 1–6','Joshua led Israel into the promised land and urged the people to serve the Lord.'),
    _Person('Eli','Medium',['I was a priest serving at Shiloh.','I guided the young Samuel when he heard God calling.','My sons served as priests but acted wickedly.','I died after hearing that the ark had been captured.'],'1 Samuel 1–4','Eli served as priest and helped Samuel recognize the Lord’s call.'),
    _Person('Samuel','Easy',['My mother prayed earnestly for me before I was born.','I served the Lord as a boy at Shiloh.','I heard God calling me during the night.','I anointed Saul and later David as kings.'],'1 Samuel 1–16','Samuel served as a prophet and judge who anointed Israel’s first two kings.'),
    _Person('Hannah','Easy',['I was married to Elkanah.','I prayed at the tabernacle because I longed for a child.','I promised to dedicate my son to the Lord.','I gave birth to Samuel and later praised God in prayer.'],'1 Samuel 1–2','Hannah’s prayer and faith are recorded at the beginning of 1 Samuel.'),
    _Person('Uriah the Hittite','Hard',['I was a soldier in David’s army.','My wife was Bathsheba.','I remained loyal to my fellow soldiers while they were in battle.','David arranged for me to be placed at the front of the fighting.'],'2 Samuel 11','Uriah is remembered in the account of David’s wrongdoing and abuse of royal power.'),
    _Person('Mephibosheth','Hard',['I was the son of Jonathan and grandson of Saul.','I became disabled in both feet as a child.','David showed me kindness because of his covenant with Jonathan.','I ate regularly at the king’s table.'],'2 Samuel 4:4; 9','David honoured his friendship with Jonathan by showing kindness to Mephibosheth.'),
    _Person('Huldah','Hard',['I was a prophetess living in Jerusalem.','King Josiah’s officials came to seek the word of the Lord from me.','I confirmed the seriousness of the words found in the Book of the Law.','I also delivered a message of mercy to Josiah because he humbled himself.'],'2 Kings 22:14–20; 2 Chronicles 34:22–28','Huldah faithfully delivered God’s message during Josiah’s reforms.'),
    _Person('Habakkuk','Hard',['I was a prophet who questioned why injustice seemed to go unanswered.','I asked God why violence and wrongdoing were widespread.','I learned that the righteous shall live by faith.','My book ends with a declaration of trust even in hardship.'],'Habakkuk 1–3','Habakkuk’s prophecy moves from honest questions toward confident trust in God.')
  ];

  final answer = TextEditingController();
  List<_Person> allCharacters = List<_Person>.from(bank);
  static const _characterCacheKey = 'ngn_guess_character_remote_cache';
  String difficulty = 'All', mode = 'Quick Guess';
  List<_Person> session = [];
  int index = 0, clue = 0, score = 0, best = 0;
  bool solved = false, finished = false;
  String? message;
  _Person get current => session[index];

  @override
  void initState() { super.initState(); _loadBest(); _start(); _syncRemoteCharacters(); }
  @override
  void dispose() { answer.dispose(); super.dispose(); }
  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => best = p.getInt('ngn_guess_character_best') ?? 0);
  }
  List<_Person> get pool => difficulty == 'All'
      ? List.of(allCharacters)
      : allCharacters.where((p) => p.level == difficulty).toList();

  Future<void> _syncRemoteCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_characterCacheKey);
    if (cached != null) {
      try {
        final rows = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        final cachedPeople = rows.map(_personFromMap).toList();
        if (cachedPeople.isNotEmpty && mounted) {
          setState(() => allCharacters = _mergeCharacters(cachedPeople));
          _start();
        }
      } catch (_) {
        // Ignore an invalid old cache and keep the bundled characters.
      }
    }

    try {
      final rows = await Supabase.instance.client
          .from('bible_characters')
          .select('name,difficulty,clues,bible_references,explanation')
          .eq('is_published', true)
          .order('name');
      final remoteRows = List<Map<String, dynamic>>.from(rows);
      if (remoteRows.isEmpty) return;
      await prefs.setString(_characterCacheKey, jsonEncode(remoteRows));
      final remotePeople = remoteRows.map(_personFromMap).toList();
      if (mounted) {
        setState(() => allCharacters = _mergeCharacters(remotePeople));
        _start();
      }
    } catch (_) {
      // The bundled and last-cached character sets remain playable offline.
    }
  }

  _Person _personFromMap(Map<String, dynamic> row) => _Person(
    row['name'].toString(),
    row['difficulty'].toString(),
    List<String>.from(row['clues'] as List),
    row['bible_references'].toString(),
    row['explanation'].toString(),
  );

  List<_Person> _mergeCharacters(List<_Person> remote) {
    final byName = <String, _Person>{
      for (final person in bank) person.name.toLowerCase(): person,
      for (final person in remote) person.name.toLowerCase(): person,
    };
    return byName.values.toList();
  }

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
      appBar: AppBar(title: const Text('Guess the Bible Character'), actions: [
        IconButton(
          tooltip: 'Leaderboard',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLeaderboardPage(gameId: 'guess_bible_character', gameTitle: 'Guess the Bible Character'))),
          icon: const Icon(Icons.leaderboard_rounded),
        ),
      ]),
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
