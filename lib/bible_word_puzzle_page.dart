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
  static const _levelKey = 'ngn_bible_word_cookies_level';
  static const _queueKey = 'ngn_game_score_queue';
  static final List<_CookiePuzzle> _bank = _buildOneThousandLevels();

  static List<_CookiePuzzle> _buildFiveHundredLevels() {
    // 50 Bible themes × all 20 combinations of three words from six = 1,000 levels.
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
      _ThemePack('The Tabernacle • Exodus 25–30', [
        _WordClue('GOLD','Precious metal used throughout the sanctuary','Exodus 25:3'), _WordClue('LAMP','The golden stand that gave light','Exodus 25:31-37'), _WordClue('ALTAR','Place for offerings before the Lord','Exodus 27:1'), _WordClue('VEIL','Curtain separating the Most Holy Place','Exodus 26:31-33'), _WordClue('ARK','The covenant chest placed in the Most Holy Place','Exodus 25:10-22'), _WordClue('OIL','Used to keep the lamps burning','Exodus 27:20'),
      ]),
      _ThemePack('The Ten Commandments • Exodus 20', [
        _WordClue('HONOUR','Show respect to father and mother','Exodus 20:12'), _WordClue('SABBATH','The day set apart for rest','Exodus 20:8-11'), _WordClue('IDOLS','Images that must not be worshipped','Exodus 20:4-5'), _WordClue('WITNESS','Do not give false testimony','Exodus 20:16'), _WordClue('COVET','Do not desire what belongs to another','Exodus 20:17'), _WordClue('NAME','Do not misuse the Lord’s holy ____','Exodus 20:7'),
      ]),
      _ThemePack('Priests and Worship • Leviticus', [
        _WordClue('AARON','Israel’s first high priest','Leviticus 8:1-2'), _WordClue('ROBE','A garment worn by the priest','Exodus 28:4'), _WordClue('EPOD','A special priestly garment','Exodus 28:6'), _WordClue('OFFER','Present a gift to God','Leviticus 1:2'), _WordClue('HOLY','Set apart for God','Leviticus 19:2'), _WordClue('ALTAR','Place where offerings were presented','Leviticus 1:5'),
      ]),
      _ThemePack('The Twelve Spies • Numbers 13–14', [
        _WordClue('CALEB','One of the two faithful spies','Numbers 14:24'), _WordClue('JOSHUA','The other faithful spy who trusted God','Numbers 14:6-9'), _WordClue('GRAPES','A large cluster was carried from Canaan','Numbers 13:23'), _WordClue('GIANTS','The people who frightened ten spies','Numbers 13:33'), _WordClue('LAND','The place God promised to Israel','Numbers 13:2'), _WordClue('FEAR','The ten spies spread this among the people','Numbers 13:31-33'),
      ]),
      _ThemePack('Balaam and the Donkey • Numbers 22', [
        _WordClue('BALAAM','The man summoned by Balak','Numbers 22:5'), _WordClue('DONKEY','The animal that saw the angel','Numbers 22:23'), _WordClue('ANGEL','The messenger standing in the road','Numbers 22:22-23'), _WordClue('MOAB','The land whose king summoned Balaam','Numbers 22:4-6'), _WordClue('SPEAK','God enabled the animal to do this','Numbers 22:28'), _WordClue('BLESS','What Balaam was made to do to Israel','Numbers 23:11-12'),
      ]),
      _ThemePack('Samson • Judges 13–16', [
        _WordClue('SAMSON','Judge known for extraordinary strength','Judges 13:24-25'), _WordClue('DELILAH','The woman who pressed Samson for his secret','Judges 16:4-6'), _WordClue('HAIR','The sign connected with Samson’s vow','Judges 16:17'), _WordClue('LION','An animal Samson tore apart','Judges 14:5-6'), _WordClue('GATES','Samson carried these away from Gaza','Judges 16:3'), _WordClue('PILLAR','Samson pushed these apart in the temple','Judges 16:29-30'),
      ]),
      _ThemePack('Gideon’s Victory • Judges 6–8', [
        _WordClue('FLEECE','Gideon used this to seek a sign','Judges 6:36-40'), _WordClue('JAR','The soldiers carried this clay vessel','Judges 7:16'), _WordClue('TORCH','Hidden inside each jar','Judges 7:16'), _WordClue('TRUMPET','Blown by Gideon’s three hundred men','Judges 7:18-20'), _WordClue('MIDIAN','The enemy nation defeated by Gideon','Judges 7:23-25'), _WordClue('THREE','Number of hundred men in Gideon’s army','Judges 7:7'),
      ]),
      _ThemePack('Hannah’s Prayer • 1 Samuel 1–2', [
        _WordClue('HANNAH','The mother who prayed for a son','1 Samuel 1:10-20'), _WordClue('ELKANAH','Hannah’s husband','1 Samuel 1:1-2'), _WordClue('ELI','The priest who blessed Hannah','1 Samuel 1:17'), _WordClue('SAMUEL','The son Hannah dedicated to the Lord','1 Samuel 1:27-28'), _WordClue('PRAYER','Hannah poured out her heart in this','1 Samuel 1:12-16'), _WordClue('TEMPLE','Hannah brought Samuel to serve the Lord here','1 Samuel 1:24'),
      ]),
      _ThemePack('Saul Becomes King • 1 Samuel 9–11', [
        _WordClue('SAUL','Israel’s first king','1 Samuel 10:24'), _WordClue('KISH','Saul’s father','1 Samuel 9:1-2'), _WordClue('DONKEY','The animals Saul searched for','1 Samuel 9:3'), _WordClue('OIL','Samuel poured this on Saul’s head','1 Samuel 10:1'), _WordClue('KING','The people asked Samuel for one','1 Samuel 8:5'), _WordClue('GIBEAH','Saul’s home town','1 Samuel 10:26'),
      ]),
      _ThemePack('David and Jonathan • 1 Samuel 18–20', [
        _WordClue('JONATHAN','Saul’s son and David’s close friend','1 Samuel 18:1'), _WordClue('BOW','Jonathan gave this to David','1 Samuel 18:4'), _WordClue('ARROW','Jonathan used this as a warning signal','1 Samuel 20:20-22'), _WordClue('COVENANT','The two friends made a solemn agreement','1 Samuel 20:16-17'), _WordClue('SAUL','The king who became jealous of David','1 Samuel 18:8-9'), _WordClue('FRIEND','Jonathan proved himself to be this to David','1 Samuel 20:17'),
      ]),
      _ThemePack('The Wisdom of Proverbs • Proverbs', [
        _WordClue('WISDOM','The book urges readers to seek this','Proverbs 4:7'), _WordClue('FOOL','The opposite of a wise person','Proverbs 1:7'), _WordClue('TONGUE','Can bring life or destruction','Proverbs 18:21'), _WordClue('HEART','Guard this above all else','Proverbs 4:23'), _WordClue('PATH','The Lord makes straight the way of the righteous','Proverbs 3:5-6'), _WordClue('ANSWER','A gentle one turns away wrath','Proverbs 15:1'),
      ]),
      _ThemePack('Queen Esther • Esther 1–10', [
        _WordClue('ESTHER','The Jewish woman who became queen','Esther 2:17'), _WordClue('MORDECAI','Esther’s cousin and guardian','Esther 2:7'), _WordClue('HAMAN','The official who plotted against the Jews','Esther 3:5-6'), _WordClue('PERSIA','The empire where the story takes place','Esther 1:1'), _WordClue('FEAST','Esther invited the king and Haman to this','Esther 5:4'), _WordClue('COURAGE','Esther showed this by approaching the king','Esther 4:16'),
      ]),
      _ThemePack('Nehemiah Rebuilds • Nehemiah 1–6', [
        _WordClue('NEHEMIAH','The cupbearer who led Jerusalem’s rebuilding','Nehemiah 2:17-18'), _WordClue('WALL','The structure rebuilt around Jerusalem','Nehemiah 6:15'), _WordClue('GATE','An entrance repaired by the people','Nehemiah 3:1'), _WordClue('PRAY','Nehemiah did this before answering the king','Nehemiah 2:4'), _WordClue('SWORD','Workers kept weapons nearby while building','Nehemiah 4:17-18'), _WordClue('JERUSALEM','The city whose walls were rebuilt','Nehemiah 2:11-17'),
      ]),
      _ThemePack('Job’s Faith • Book of Job', [
        _WordClue('JOB','A man described as blameless and upright','Job 1:1'), _WordClue('UZ','The land where Job lived','Job 1:1'), _WordClue('SATAN','The accuser who challenged Job’s faith','Job 1:6-12'), _WordClue('ASHES','Job sat among these in his grief','Job 2:8'), _WordClue('FRIENDS','Visitors who debated with Job','Job 2:11'), _WordClue('REDEEMER','Job declared that this one lives','Job 19:25'),
      ]),
      _ThemePack('Isaiah’s Prophecies • Isaiah', [
        _WordClue('ISAIAH','The prophet who saw the Lord’s glory','Isaiah 6:1'), _WordClue('EMMANUEL','The promised name meaning God with us','Isaiah 7:14'), _WordClue('SERAPH','A heavenly being in Isaiah’s vision','Isaiah 6:2'), _WordClue('HOLY','The seraphim called the Lord this','Isaiah 6:3'), _WordClue('ZION','The mountain associated with the Lord’s house','Isaiah 2:2-3'), _WordClue('PEACE','The promised Prince is called this in a title','Isaiah 9:6'),
      ]),
      _ThemePack('Jeremiah and the New Covenant • Jeremiah', [
        _WordClue('JEREMIAH','The prophet called before birth','Jeremiah 1:5'), _WordClue('ANATHOTH','The town Jeremiah came from','Jeremiah 1:1'), _WordClue('POTTER','Jeremiah watched this worker shape clay','Jeremiah 18:1-6'), _WordClue('CLAY','The material shaped by the potter','Jeremiah 18:4'), _WordClue('COVENANT','God promised a new one written on hearts','Jeremiah 31:31-33'), _WordClue('TEARS','Jeremiah is often associated with weeping','Jeremiah 9:1'),
      ]),
      _ThemePack('Ezekiel’s Visions • Ezekiel', [
        _WordClue('EZEKIEL','The prophet who saw a valley of dry bones','Ezekiel 37:1-10'), _WordClue('BONES','The dry ones came together in a vision','Ezekiel 37:7'), _WordClue('VALLEY','The place of the dry bones vision','Ezekiel 37:1'), _WordClue('WHEELS','Part of the prophet’s opening vision','Ezekiel 1:15-21'), _WordClue('RIVER','Water flowed from the temple in a vision','Ezekiel 47:1-12'), _WordClue('WATCHMAN','A role God gave Ezekiel for Israel','Ezekiel 3:17'),
      ]),
      _ThemePack('The Minor Prophets • Twelve Prophets', [
        _WordClue('HOSEA','The prophet whose marriage became a sign','Hosea 1:2-3'), _WordClue('AMOS','A shepherd called to prophesy to Israel','Amos 7:14-15'), _WordClue('MICAH','The prophet who named Bethlehem in prophecy','Micah 5:2'), _WordClue('NAHUM','The prophet who announced Nineveh’s fall','Nahum 1:1'), _WordClue('HABAKKUK','The prophet who lived by faith','Habakkuk 2:4'), _WordClue('MALACHI','The final book in the Old Testament in many Christian Bibles','Malachi 1:1'),
      ]),
      _ThemePack('John the Baptist • Gospels', [
        _WordClue('JOHN','The prophet who prepared the way for Jesus','Matthew 3:1-3'), _WordClue('JORDAN','The river where John baptised people','Matthew 3:5-6'), _WordClue('CAMEL','The hair used for John’s clothing','Matthew 3:4'), _WordClue('HONEY','Wild food John ate in the wilderness','Matthew 3:4'), _WordClue('VOICE','John was a ____ crying in the wilderness','John 1:23'), _WordClue('BAPTISM','John preached this as a sign of repentance','Mark 1:4'),
      ]),
      _ThemePack('The Sermon on the Mount • Matthew 5–7', [
        _WordClue('POOR','Jesus said these in spirit are blessed','Matthew 5:3'), _WordClue('MEEK','These shall inherit the earth','Matthew 5:5'), _WordClue('MERCY','The merciful will receive this','Matthew 5:7'), _WordClue('SALT','Jesus called His disciples this of the earth','Matthew 5:13'), _WordClue('LIGHT','A city on a hill cannot be hidden; disciples are this','Matthew 5:14'), _WordClue('GOLDEN','The ____ Rule says do to others as you would have them do to you','Matthew 7:12'),
      ]),
      _ThemePack('Jesus Calls the First Disciples • Gospels', [
        _WordClue('SIMON','Peter’s original name','Matthew 4:18'), _WordClue('ANDREW','The brother who was with Simon','Matthew 4:18'), _WordClue('JAMES','The son of Zebedee called by Jesus','Matthew 4:21'), _WordClue('JOHN','James’s brother and fellow fisherman','Matthew 4:21'), _WordClue('NETS','The fishermen were mending these','Matthew 4:21'), _WordClue('FOLLOW','Jesus invited them to do this','Matthew 4:19'),
      ]),
      _ThemePack('The Good Samaritan • Luke 10', [
        _WordClue('SAMARITAN','The traveller who showed compassion','Luke 10:33'), _WordClue('PRIEST','A religious leader who passed by','Luke 10:31'), _WordClue('LEVITE','Another traveller who passed by','Luke 10:32'), _WordClue('INN','The injured man was taken here','Luke 10:34'), _WordClue('OIL','Used with wine to care for the wounds','Luke 10:34'), _WordClue('MERCY','The Samaritan showed this to the injured man','Luke 10:37'),
      ]),
      _ThemePack('The Lost Parables • Luke 15', [
        _WordClue('SHEEP','The shepherd searched for one lost animal','Luke 15:4'), _WordClue('COIN','The woman searched for one lost piece','Luke 15:8'), _WordClue('SON','A younger one left home and later returned','Luke 15:11-24'), _WordClue('FATHER','The one who welcomed the returning son','Luke 15:20'), _WordClue('RING','A gift placed on the returning son’s hand','Luke 15:22'), _WordClue('FEAST','The family celebrated with this','Luke 15:23-24'),
      ]),
      _ThemePack('The Last Supper • Gospels', [
        _WordClue('BREAD','Jesus broke this and gave it to His disciples','Luke 22:19'), _WordClue('CUP','Jesus gave thanks and shared this','Luke 22:20'), _WordClue('WASH','Jesus did this to His disciples’ feet','John 13:5'), _WordClue('FEET','The disciples’ body part Jesus washed','John 13:5'), _WordClue('JUDAS','The disciple who left to betray Jesus','John 13:30'), _WordClue('SERVE','Jesus modelled humble service','John 13:14-15'),
      ]),
      _ThemePack('Pentecost • Acts 2', [
        _WordClue('SPIRIT','The Holy ____ came upon the believers','Acts 2:4'), _WordClue('WIND','A sound like a mighty rushing one filled the house','Acts 2:2'), _WordClue('FIRE','Tongues appeared like this over them','Acts 2:3'), _WordClue('TONGUES','The believers spoke in other languages','Acts 2:4'), _WordClue('PETER','The apostle who addressed the crowd','Acts 2:14'), _WordClue('THREE','About this many thousand were added that day','Acts 2:41'),
      ]),
      _ThemePack('Paul’s Missionary Journeys • Acts', [
        _WordClue('BARNABAS','Paul’s companion on the first journey','Acts 13:2-3'), _WordClue('SILAS','Paul’s companion after the council at Jerusalem','Acts 15:40'), _WordClue('TIMOTHY','A young disciple Paul mentored','Acts 16:1-3'), _WordClue('LYDIA','A seller of purple goods in Philippi','Acts 16:14'), _WordClue('PHILIPPI','The city where Paul and Silas were imprisoned','Acts 16:12-24'), _WordClue('PRISON','Paul and Silas sang hymns in this place','Acts 16:25'),
      ]),
      _ThemePack('The Armour of God • Ephesians 6', [
        _WordClue('BELT','The belt of truth','Ephesians 6:14'), _WordClue('BREASTPLATE','The breastplate of righteousness','Ephesians 6:14'), _WordClue('SHIELD','The shield of faith','Ephesians 6:16'), _WordClue('HELMET','The helmet of salvation','Ephesians 6:17'), _WordClue('SWORD','The sword of the Spirit','Ephesians 6:17'), _WordClue('PRAYER','Believers are told to pray at all times','Ephesians 6:18'),
      ]),
      _ThemePack('The New Creation • Revelation 21–22', [
        _WordClue('HEAVEN','The new one and earth are promised','Revelation 21:1'), _WordClue('CITY','The holy one comes down from God','Revelation 21:2'), _WordClue('GATE','The city has twelve of these','Revelation 21:12'), _WordClue('RIVER','The water of life flows through the city','Revelation 22:1'), _WordClue('TREE','The tree of life stands by the river','Revelation 22:2'), _WordClue('LIGHT','The Lord God gives light there','Revelation 22:5'),
      ]),
    ];

    final levels = <_CookiePuzzle>[];
    for (final theme in themes) {
      for (var a = 0; a < 6; a++) {
        for (var b = a + 1; b < 6; b++) {
          for (var d = b + 1; d < 6; d++) {
            final chosen = [theme.words[a], theme.words[b], theme.words[d]];
            final number = levels.length + 1;
            final difficulty = number <= 300 ? 'Easy' : number <= 700 ? 'Medium' : 'Hard';
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
    return levels.take(1000).toList(growable: false);
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
    _initGame();
  }

  Future<void> _initGame() async {
    final p = await SharedPreferences.getInstance();
    _best = p.getInt(_bestKey) ?? 0;
    _index = p.getInt(_levelKey) ?? 0;
    if (mounted) setState(() {});
    _newPuzzle();
    _syncQueuedScores();
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
    await p.setInt(_levelKey, _index);
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
