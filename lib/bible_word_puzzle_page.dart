import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first Bible Word Search. The bundled pack is always available;
/// downloaded packs can be merged into this bank in a later content-sync step.
class BibleWordPuzzlePage extends StatefulWidget {
  const BibleWordPuzzlePage({super.key});
  @override
  State<BibleWordPuzzlePage> createState() => _BibleWordPuzzlePageState();
}

class _BibleWordSearch {
  const _BibleWordSearch(this.verse, this.reference, this.words, this.explanation, this.level);
  final String verse, reference, explanation, level;
  final List<String> words;
}

class _BibleWordPuzzlePageState extends State<BibleWordPuzzlePage> {
  static const _blue = Color(0xFF0B5ED7);
  static const _gold = Color(0xFFD4AF37);
  static const _bestKey = 'ngn_bible_word_search_best';
  static const int _size = 12;

  // KJV excerpts are public domain. This starter pack is structured for
  // expansion to the requested 300 reviewed entries.
  static const List<_BibleWordSearch> _bank = [
    _BibleWordSearch('The Lord is my shepherd; I shall not want.', 'Psalm 23:1', ['LORD','SHEPHERD','WANT'], 'David describes the Lord as the shepherd who cares for him.', 'Easy'),
    _BibleWordSearch('Be still, and know that I am God.', 'Psalm 46:10', ['STILL','KNOW','GOD'], 'This verse calls readers to recognise God above the nations.', 'Easy'),
    _BibleWordSearch('Thy word is a lamp unto my feet, and a light unto my path.', 'Psalm 119:105', ['WORD','LAMP','FEET','LIGHT','PATH'], 'God’s word gives guidance for the journey of life.', 'Easy'),
    _BibleWordSearch('I can do all things through Christ which strengtheneth me.', 'Philippians 4:13', ['CHRIST','STRENGTHENETH','THINGS'], 'Paul speaks of finding strength in Christ in every circumstance.', 'Medium'),
    _BibleWordSearch('Trust in the Lord with all thine heart; and lean not unto thine own understanding.', 'Proverbs 3:5', ['TRUST','LORD','HEART','UNDERSTANDING'], 'Wisdom teaches complete trust in the Lord rather than self-reliance.', 'Medium'),
    _BibleWordSearch('The joy of the Lord is your strength.', 'Nehemiah 8:10', ['JOY','LORD','STRENGTH'], 'The people were encouraged to rejoice in the Lord.', 'Easy'),
    _BibleWordSearch('For we walk by faith, not by sight.', '2 Corinthians 5:7', ['WALK','FAITH','SIGHT'], 'Christian life is guided by faith in God.', 'Medium'),
    _BibleWordSearch('Let all your things be done with charity.', '1 Corinthians 16:14', ['THINGS','DONE','CHARITY'], 'Paul instructs believers to let love shape all they do.', 'Easy'),
    _BibleWordSearch('Create in me a clean heart, O God; and renew a right spirit within me.', 'Psalm 51:10', ['CREATE','CLEAN','HEART','RENEW','SPIRIT'], 'David asks God for inner renewal and a faithful spirit.', 'Medium'),
    _BibleWordSearch('The name of the Lord is a strong tower: the righteous runneth into it, and is safe.', 'Proverbs 18:10', ['NAME','LORD','STRONG','TOWER','RIGHTEOUS','SAFE'], 'God is pictured as a secure refuge for those who trust Him.', 'Hard'),
    _BibleWordSearch('In the beginning God created the heaven and the earth.', 'Genesis 1:1', ['BEGINNING','GOD','CREATED','HEAVEN','EARTH'], 'The Bible opens by declaring God as Creator.', 'Easy'),
    _BibleWordSearch('The Lord is good, a strong hold in the day of trouble; and he knoweth them that trust in him.', 'Nahum 1:7', ['LORD','GOOD','STRONG','TROUBLE','TRUST'], 'God is good and knows those who take refuge in Him.', 'Hard'),
    _BibleWordSearch('Let your light so shine before men, that they may see your good works, and glorify your Father.', 'Matthew 5:16', ['LIGHT','SHINE','GOOD','WORKS','GLORIFY','FATHER'], 'Jesus calls His followers to live so their actions point others to God.', 'Hard'),
    _BibleWordSearch('Blessed are the peacemakers: for they shall be called the children of God.', 'Matthew 5:9', ['BLESSED','PEACEMAKERS','CHILDREN','GOD'], 'Jesus honours those who actively make peace.', 'Medium'),
    _BibleWordSearch('Jesus Christ the same yesterday, and to day, and for ever.', 'Hebrews 13:8', ['JESUS','CHRIST','SAME','YESTERDAY','EVER'], 'The verse declares the unchanging nature of Jesus Christ.', 'Medium'),
    _BibleWordSearch('The Lord shall fight for you, and ye shall hold your peace.', 'Exodus 14:14', ['LORD','FIGHT','HOLD','PEACE'], 'Moses reassured Israel as they faced the Red Sea.', 'Medium'),
    _BibleWordSearch('A soft answer turneth away wrath: but grievous words stir up anger.', 'Proverbs 15:1', ['SOFT','ANSWER','WRATH','WORDS','ANGER'], 'Gentle speech can calm conflict while harsh speech increases it.', 'Hard'),
    _BibleWordSearch('Let us love one another: for love is of God.', '1 John 4:7', ['LOVE','ANOTHER','GOD'], 'John teaches that genuine love has its source in God.', 'Easy'),
    _BibleWordSearch('The Lord is nigh unto all them that call upon him, to all that call upon him in truth.', 'Psalm 145:18', ['LORD','NIGH','CALL','TRUTH'], 'God is near to those who sincerely call on Him.', 'Hard'),
    _BibleWordSearch('But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith.', 'Galatians 5:22', ['FRUIT','SPIRIT','LOVE','JOY','PEACE','FAITH'], 'Paul lists qualities produced by the Holy Spirit in a believer’s life.', 'Hard'),
  ];

  final Random _random = Random();
  final Set<String> _found = {};
  final Set<int> _foundCells = {};
  final List<int> _selection = [];
  late _BibleWordSearch _puzzle;
  late List<List<String>> _grid;
  int _score = 0, _best = 0, _round = 0;
  String _difficulty = 'All';
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _newPuzzle();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = prefs.getInt(_bestKey) ?? 0);
  }

  List<_BibleWordSearch> get _pool => _difficulty == 'All'
      ? List.of(_bank)
      : _bank.where((p) => p.level == _difficulty).toList();

  void _newPuzzle() {
    final pool = _pool;
    pool.shuffle(_random);
    _puzzle = pool[_round % pool.length];
    _round++;
    _found.clear();
    _foundCells.clear();
    _selection.clear();
    _message = null;
    _grid = List.generate(_size, (_) => List.filled(_size, ''));
    final words = List<String>.from(_puzzle.words)..sort((a,b) => b.length.compareTo(a.length));
    for (final word in words) {
      _placeWord(word);
    }
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var r=0;r<_size;r++) {
      for (var c=0;c<_size;c++) {
        if (_grid[r][c].isEmpty) _grid[r][c] = letters[_random.nextInt(letters.length)];
      }
    }
    if (mounted) setState(() {});
  }

  void _placeWord(String word) {
    const dirs = [[0,1],[1,0],[1,1],[-1,1]];
    for (var attempt=0; attempt<180; attempt++) {
      final d = dirs[_random.nextInt(dirs.length)];
      final row = _random.nextInt(_size), col = _random.nextInt(_size);
      final endR = row + d[0]*(word.length-1), endC = col + d[1]*(word.length-1);
      if (endR<0 || endR>=_size || endC<0 || endC>=_size) continue;
      var fits = true;
      for (var i=0;i<word.length;i++) {
        final existing = _grid[row+d[0]*i][col+d[1]*i];
        if (existing.isNotEmpty && existing != word[i]) { fits=false; break; }
      }
      if (!fits) continue;
      for (var i=0;i<word.length;i++) {
        _grid[row+d[0]*i][col+d[1]*i] = word[i];
      }
      return;
    }
  }

  void _tapCell(int row, int col) {
    final index = row*_size+col;
    setState(() {
      if (_selection.contains(index)) {
        _selection.clear();
        _message = 'Selection cleared.';
        return;
      }
      _selection.add(index);
      final letters = _selection.map((i) => _grid[i~/_size][i%_size]).join();
      final reverse = letters.split('').reversed.join();
      String? match;
      for (final word in _puzzle.words) {
        if (!_found.contains(word) && (word == letters || word == reverse)) { match = word; break; }
      }
      if (match != null) {
        _found.add(match);
        _foundCells.addAll(_selection);
        _score += 10;
        _selection.clear();
        _message = 'Found $match! +10 points';
        _saveBest();
      } else if (!_puzzle.words.any((w) => !_found.contains(w) && (w.startsWith(letters) || w.endsWith(reverse)))) {
        _selection.clear();
        _message = 'Those letters do not form a target word. Try again.';
      } else {
        _message = null;
      }
    });
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    final best = max(_best, _score);
    await prefs.setInt(_bestKey, best);
    if (mounted) setState(() => _best = best);
  }

  bool get _complete => _found.length == _puzzle.words.length;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Word Search')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.search_rounded,color: _gold), SizedBox(width:8), Text('FIND THE WORDS',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)), Spacer(), Icon(Icons.wifi_off,color:Colors.white70,size:16), SizedBox(width:4), Text('OFFLINE',style:TextStyle(color:Colors.white70,fontSize:10))]),
            const SizedBox(height:10),
            Text('Score: $_score  •  Best: $_best',style:const TextStyle(color:Colors.white)),
            const SizedBox(height:8),
            DropdownButton<String>(
              value: _difficulty,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87),
              items: const ['All','Easy','Medium','Hard'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
              onChanged: (v) { if(v!=null) setState(() { _difficulty=v; _round=0; }); _newPuzzle(); },
            ),
          ]),
        ),
        const SizedBox(height:12),
        if (_difficulty != 'Hard' && _puzzle.level != 'Hard')
          Card(child: Padding(padding: const EdgeInsets.all(14),child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('BIBLE VERSE',style:TextStyle(color:_blue,fontWeight:FontWeight.w900)),
            const SizedBox(height:6),
            Text('“${_puzzle.verse}”',style:const TextStyle(fontSize:15,height:1.45)),
            const SizedBox(height:5),
            Text(_puzzle.reference,style:const TextStyle(color:_blue,fontWeight:FontWeight.w800)),
          ])))
        else
          Card(child: const Padding(padding:EdgeInsets.all(14),child:Text('HARD MODE • The verse is hidden. Find every word using the reference clues in the word list.'))),
        const SizedBox(height:10),
        const Text('TAP THE LETTERS IN ORDER',style:TextStyle(fontWeight:FontWeight.w900,color:_blue)),
        const SizedBox(height:8),
        AspectRatio(aspectRatio:1,child:GridView.builder(
          physics:const NeverScrollableScrollPhysics(),
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:_size,mainAxisSpacing:2,crossAxisSpacing:2),
          itemCount:_size*_size,
          itemBuilder:(context,i) {
            final selected=_selection.contains(i);
            final foundCell=_isCellInFoundWord(i);
            return InkWell(
              onTap:()=>_tapCell(i~/_size,i%_size),
              child:Container(
                alignment:Alignment.center,
                decoration:BoxDecoration(
                  color:foundCell ? Colors.green.shade600 : selected ? _gold : (dark?Colors.white12:Colors.blue.shade50),
                  borderRadius:BorderRadius.circular(4),
                ),
                child:Text(_grid[i~/_size][i%_size],style:TextStyle(fontSize:13,fontWeight:FontWeight.w900,color:foundCell||selected?Colors.white:(dark?Colors.white:Colors.black87))),
              ),
            );
          },
        )),
        const SizedBox(height:12),
        const Text('WORDS TO FIND',style:TextStyle(fontWeight:FontWeight.w900,color:_blue)),
        const SizedBox(height:6),
        Wrap(spacing:8,runSpacing:8,children:_puzzle.words.map((w)=>Chip(
          avatar:Icon(_found.contains(w)?Icons.check_circle:Icons.circle_outlined,size:17,color:_found.contains(w)?Colors.green: _blue),
          label:Text(w,style:TextStyle(decoration:_found.contains(w)?TextDecoration.lineThrough:null,fontWeight:FontWeight.w700)),
          backgroundColor:_found.contains(w)?Colors.green.withValues(alpha:0.12):null,
        )).toList()),
        if (_message!=null) Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text(_message!,style:const TextStyle(fontWeight:FontWeight.w700))),
        if (_complete) Card(color:Colors.green.withValues(alpha:0.12),child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
          const Text('PUZZLE COMPLETED!',style:TextStyle(fontWeight:FontWeight.w900,color:Colors.green)),
          Text(_puzzle.explanation,textAlign:TextAlign.center),
          Text(_puzzle.reference,style:const TextStyle(fontWeight:FontWeight.w800,color:_blue)),
        ]))),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>setState(_selection.clear),icon:const Icon(Icons.backspace_outlined),label:const Text('Clear selection')),
        FilledButton.icon(onPressed:_newPuzzle,icon:const Icon(Icons.navigate_next),label:Text(_complete?'Next puzzle':'New puzzle')),
        const SizedBox(height:8),
        Text('Each word found earns 10 points. Your score is saved on this device.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:dark?Colors.white60:Colors.black54)),
      ])),
    );
  }

  bool _isCellInFoundWord(int index) {
    // Found words are marked by the cells in the selection path before it clears.
    return _foundCells.contains(index);
  }
}
