import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'game_leaderboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Offline-first Bible Trivia. Questions are bundled with the app so the
/// game remains playable without a network connection.
class BibleTriviaPage extends StatefulWidget {
  const BibleTriviaPage({super.key});

  @override
  State<BibleTriviaPage> createState() => _BibleTriviaPageState();
}

class _BibleTriviaPageState extends State<BibleTriviaPage> {
  static const _blue = Color(0xFF073B8C);
  static const _gold = Color(0xFFD4AF37);
  static const _highScoreKey = 'ngn_bible_trivia_high_score';

  final Map<String, List<_TriviaQuestion>> _questions = {
    'Easy': const [
      _TriviaQuestion('“The Lord is my shepherd.” Where is this verse found?', ['Psalm 23:1', 'John 10:10', 'Proverbs 3:5', 'Matthew 6:33'], 0, 'Psalm 23:1', 'Psalm 23 begins by describing the Lord as our shepherd.', isVerseChallenge: true),
      _TriviaQuestion('“For God so loved the world.” Where is this verse found?', ['Romans 8:28', 'John 3:16', '1 John 4:8', 'Genesis 1:1'], 1, 'John 3:16', 'John 3:16 teaches about God’s love and the gift of His Son.', isVerseChallenge: true),
      _TriviaQuestion('“Jesus wept.” Where is this short verse found?', ['Luke 19:41', 'John 11:35', 'Matthew 5:4', 'Mark 1:15'], 1, 'John 11:35', 'John 11:35 records Jesus weeping before the raising of Lazarus.', isVerseChallenge: true),
      _TriviaQuestion('Who built the ark?', ['Moses', 'Noah', 'Abraham', 'David'], 1, 'Genesis 6:13–22', 'God instructed Noah to build an ark before the flood.'),
      _TriviaQuestion('Who was the mother of Jesus?', ['Martha', 'Elizabeth', 'Mary', 'Ruth'], 2, 'Luke 1:26–31', 'Mary was chosen to be the mother of Jesus.'),
      _TriviaQuestion('Where was Jesus born?', ['Nazareth', 'Jerusalem', 'Bethlehem', 'Jericho'], 2, 'Luke 2:4–7', 'Jesus was born in Bethlehem.'),
      _TriviaQuestion('Who defeated Goliath?', ['Jonathan', 'David', 'Saul', 'Samuel'], 1, '1 Samuel 17:45–50', 'David trusted God and defeated Goliath with a sling and a stone.'),
      _TriviaQuestion('How many apostles did Jesus appoint from His disciples?', ['10', '11', '12', '13'], 2, 'Luke 6:13–16', 'Jesus chose twelve apostles.'),
      _TriviaQuestion('Who was swallowed by a great fish?', ['Jonah', 'Job', 'Joseph', 'Elijah'], 0, 'Jonah 1:17', 'Jonah spent three days and three nights inside the great fish.'),
      _TriviaQuestion('What is the first book of the Bible?', ['Exodus', 'Psalms', 'Matthew', 'Genesis'], 3, 'Genesis 1:1', 'Genesis is the first book of the Bible.'),
      _TriviaQuestion('Who received the Ten Commandments?', ['Aaron', 'Moses', 'Joshua', 'Caleb'], 1, 'Exodus 31:18', 'God gave the tablets of the covenant to Moses.'),
      _TriviaQuestion('What did Jesus turn water into?', ['Oil', 'Milk', 'Wine', 'Juice'], 2, 'John 2:1–11', 'Jesus performed His first recorded sign at a wedding in Cana.'),
      _TriviaQuestion('Who was known for great strength and long hair?', ['Samson', 'Gideon', 'Esau', 'Boaz'], 0, 'Judges 16:17', 'Samson’s strength was connected to his Nazirite vow.'),
      _TriviaQuestion('Who led the Israelites out of Egypt?', ['Joshua', 'Moses', 'Aaron', 'Caleb'], 1, 'Exodus 3:10', 'God called Moses to lead His people out of Egypt.'),
      _TriviaQuestion('Who was the strongest man mentioned in the book of Judges?', ['Gideon', 'Samson', 'Jephthah', 'Ehud'], 1, 'Judges 13:24–25', 'Samson was given great strength by the Spirit of the Lord.'),
      _TriviaQuestion('What did God create on the first day?', ['Animals', 'The sun', 'Light', 'People'], 2, 'Genesis 1:3–5', 'God said, “Let there be light,” and there was light.'),
      _TriviaQuestion('Who climbed a sycamore tree to see Jesus?', ['Nicodemus', 'Zacchaeus', 'Bartimaeus', 'Thomas'], 1, 'Luke 19:1–4', 'Zacchaeus climbed a sycamore tree because he was short.'),
      _TriviaQuestion('Which disciple denied Jesus three times?', ['John', 'Andrew', 'Peter', 'Philip'], 2, 'Luke 22:54–62', 'Peter denied knowing Jesus three times before the rooster crowed.'),
      _TriviaQuestion('What was the name of the garden where Adam and Eve lived?', ['Gethsemane', 'Eden', 'Carmel', 'Sharon'], 1, 'Genesis 2:8', 'God planted a garden in Eden and placed Adam there.'),
      _TriviaQuestion('Who was sold by his brothers into Egypt?', ['Benjamin', 'Reuben', 'Joseph', 'Judah'], 2, 'Genesis 37:26–28', 'Joseph’s brothers sold him to traders who took him to Egypt.'),
      _TriviaQuestion('What food did God provide for the Israelites in the wilderness?', ['Fish', 'Manna', 'Grapes', 'Bread from Egypt'], 1, 'Exodus 16:14–15', 'God provided manna for the Israelites to eat.'),
      _TriviaQuestion('Who baptized Jesus?', ['Peter', 'John the Baptist', 'James', 'Andrew'], 1, 'Matthew 3:13–17', 'John baptized Jesus in the Jordan River.'),
      _TriviaQuestion('Which prayer did Jesus teach His disciples?', ['Prayer of Jabez', 'The Lord’s Prayer', 'Prayer of Hannah', 'Prayer of Solomon'], 1, 'Matthew 6:9–13', 'Jesus taught His disciples how to pray, beginning “Our Father”.'),
      _TriviaQuestion('Which reference contains the command, “Honour thy father and thy mother”?', ['Exodus 20:12', 'Deuteronomy 6:5', 'Leviticus 19:18', 'Numbers 6:24'], 0, 'Exodus 20:12', 'The command to honour parents is part of the Ten Commandments.', isVerseChallenge: true),
      _TriviaQuestion('Where is the verse that says, “Be still, and know that I am God”?', ['Psalm 46:10', 'Psalm 91:1', 'Isaiah 26:3', 'Proverbs 16:3'], 0, 'Psalm 46:10', 'Psalm 46:10 calls people to be still and recognize God.', isVerseChallenge: true),
      _TriviaQuestion('Which reference records, “In the beginning God created the heaven and the earth”?', ['Genesis 1:1', 'Genesis 2:7', 'John 1:1', 'Hebrews 11:3'], 0, 'Genesis 1:1', 'The Bible opens with the account of God creating the heavens and the earth.', isVerseChallenge: true),
      _TriviaQuestion('Where does the Bible say, “The wages of sin is death”?', ['Romans 3:23', 'Romans 6:23', 'Romans 8:1', 'Galatians 6:7'], 1, 'Romans 6:23', 'Romans 6:23 contrasts sin’s wages with God’s gift of eternal life.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter contains the Beatitudes beginning, “Blessed are the poor in spirit”?', ['Matthew 5', 'Matthew 6', 'Luke 10', 'John 15'], 0, 'Matthew 5:3', 'The Beatitudes begin in Matthew chapter 5.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter is the Lord’s Prayer recorded in the Gospel of Matthew?', ['Matthew 5', 'Matthew 6', 'Matthew 7', 'Matthew 13'], 1, 'Matthew 6:9–13', 'Matthew records Jesus teaching the Lord’s Prayer in chapter 6.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “I can do all things through Christ which strengtheneth me”?', ['Philippians 2:13', 'Philippians 4:13', 'Ephesians 6:10', 'Colossians 3:17'], 1, 'Philippians 4:13', 'Paul writes about finding strength through Christ in Philippians 4:13.', isVerseChallenge: true),
      _TriviaQuestion('Where is the instruction, “Children, obey your parents in the Lord”?', ['Ephesians 4:32', 'Ephesians 5:1', 'Ephesians 6:1', 'Colossians 3:16'], 2, 'Ephesians 6:1', 'The instruction appears at the beginning of Ephesians chapter 6.', isVerseChallenge: true),
      _TriviaQuestion('What sign did God place in the sky as a reminder of His covenant after the flood?', ['A star', 'A rainbow', 'A cloud', 'A pillar of fire'], 1, 'Genesis 9:12–17', 'God set the rainbow in the cloud as the sign of His covenant with the earth.'),
      _TriviaQuestion('Who was Isaac’s wife?', ['Rachel', 'Leah', 'Rebekah', 'Keturah'], 2, 'Genesis 24:67', 'Rebekah became Isaac’s wife after Abraham’s servant met her.'),
      _TriviaQuestion('Which city’s walls fell after Israel marched around them as God instructed?', ['Ai', 'Jericho', 'Bethel', 'Hebron'], 1, 'Joshua 6:1–20', 'The walls of Jericho fell after Israel followed God’s instructions.'),
      _TriviaQuestion('Where is the verse, “In the beginning was the Word, and the Word was with God”?', ['John 1:1', 'John 1:14', 'Genesis 1:1', '1 John 1:1'], 0, 'John 1:1', 'John opens by describing the Word who was with God in the beginning.', isVerseChallenge: true),
      _TriviaQuestion('Which reference records God calling Abram to leave his country and family?', ['Genesis 6:9', 'Genesis 12:1', 'Genesis 15:6', 'Genesis 22:2'], 1, 'Genesis 12:1', 'God called Abram to leave his country and go to the land He would show him.', isVerseChallenge: true),
      _TriviaQuestion('Where is the command, “Thou shalt have no other gods before me”?', ['Exodus 20:3', 'Exodus 20:12', 'Deuteronomy 5:16', 'Leviticus 19:18'], 0, 'Exodus 20:3', 'This is the first commandment in the Ten Commandments list in Exodus 20.', isVerseChallenge: true),
      _TriviaQuestion('Which reference announces, “For unto you is born this day… a Saviour, which is Christ the Lord”?', ['Luke 1:31', 'Luke 2:11', 'Matthew 1:21', 'John 1:14'], 1, 'Luke 2:11', 'The angel announced Jesus’ birth to the shepherds in Luke 2:11.', isVerseChallenge: true),
      _TriviaQuestion('Where did Jesus give the command to love the Lord with all your heart, soul, mind and strength?', ['Mark 12:30', 'Matthew 5:9', 'Luke 6:31', 'John 14:15'], 0, 'Mark 12:30', 'Jesus gave this as the greatest commandment in Mark 12.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “Be ye transformed by the renewing of your mind”?', ['Romans 8:1', 'Romans 10:9', 'Romans 12:2', 'Romans 15:13'], 2, 'Romans 12:2', 'Paul urges believers to be transformed by the renewing of their minds.', isVerseChallenge: true),
      _TriviaQuestion('Where did Jesus command His followers to make disciples of all nations?', ['Matthew 10:5', 'Matthew 16:18', 'Matthew 28:19', 'Mark 1:17'], 2, 'Matthew 28:19', 'The Great Commission is recorded at the end of Matthew.', isVerseChallenge: true),
      _TriviaQuestion('Which reference begins, “I will lift up mine eyes unto the hills”?', ['Psalm 23:1', 'Psalm 91:1', 'Psalm 121:1', 'Psalm 150:6'], 2, 'Psalm 121:1', 'Psalm 121 begins with the psalmist looking to the hills and asking where help comes from.', isVerseChallenge: true),
      _TriviaQuestion('Where is the verse, “The name of the LORD is a strong tower”?', ['Proverbs 3:5', 'Proverbs 18:10', 'Proverbs 22:6', 'Ecclesiastes 3:1'], 1, 'Proverbs 18:10', 'Proverbs 18:10 describes the Lord’s name as a strong tower.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says that the servant was wounded for our transgressions?', ['Isaiah 6:8', 'Isaiah 40:31', 'Isaiah 53:5', 'Isaiah 61:1'], 2, 'Isaiah 53:5', 'Isaiah 53 describes the suffering servant and the healing associated with his wounds.', isVerseChallenge: true),

      _TriviaQuestion('Who interpreted Pharaoh’s dreams about seven years of plenty and famine?', ['Aaron', 'Joseph', 'Daniel', 'Moses'], 1, 'Genesis 41:14–36', 'Joseph explained the dreams and advised Pharaoh to prepare for the coming famine.'),
      _TriviaQuestion('Which disciple stepped out of the boat and walked toward Jesus on the water?', ['John', 'Andrew', 'Peter', 'Thomas'], 2, 'Matthew 14:28–31', 'Peter walked toward Jesus before becoming afraid of the wind.'),
      _TriviaQuestion('Where does the Bible say, “Be still, and know that I am God”?', ['Psalm 23:1', 'Psalm 46:10', 'Psalm 91:2', 'Psalm 119:105'], 1, 'Psalm 46:10', 'Psalm 46 calls God’s people to be still and recognize His authority.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “I can do all things through Christ which strengtheneth me”?', ['Romans 8:28', 'Philippians 4:13', 'Galatians 2:20', 'Ephesians 6:10'], 1, 'Philippians 4:13', 'Paul describes the strength he receives through Christ.', isVerseChallenge: true),
    ],
    'Medium': const [
      _TriviaQuestion('“Your word is a lamp to my feet.” Where is this verse found?', ['Psalm 119:105', 'Proverbs 4:23', 'Isaiah 40:31', 'John 8:12'], 0, 'Psalm 119:105', 'The psalm describes God’s word as a lamp and a light for our path.', isVerseChallenge: true),
      _TriviaQuestion('“Pray without ceasing.” Where is this instruction found?', ['Ephesians 6:10', '1 Thessalonians 5:17', 'Romans 12:2', 'Colossians 3:23'], 1, '1 Thessalonians 5:17', 'Paul encourages believers to remain constant in prayer.', isVerseChallenge: true),
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
      _TriviaQuestion('Who was the mother of Samuel?', ['Peninnah', 'Hannah', 'Abigail', 'Michal'], 1, '1 Samuel 1:19–20', 'Hannah prayed for a son, and God gave her Samuel.'),
      _TriviaQuestion('Which disciple was a tax collector before following Jesus?', ['Matthew', 'Peter', 'John', 'Thomas'], 0, 'Matthew 9:9', 'Jesus called Matthew from the tax collector’s booth.'),
      _TriviaQuestion('Who succeeded Moses as leader of Israel?', ['Caleb', 'Aaron', 'Joshua', 'Eleazar'], 2, 'Joshua 1:1–2', 'God appointed Joshua to lead Israel after Moses.'),
      _TriviaQuestion('Which prophet was taken up into heaven in a whirlwind?', ['Elisha', 'Elijah', 'Isaiah', 'Jeremiah'], 1, '2 Kings 2:11', 'Elijah was taken up in a whirlwind.'),
      _TriviaQuestion('What was the name of Abraham’s wife?', ['Rebekah', 'Rachel', 'Sarah', 'Leah'], 2, 'Genesis 17:15–16', 'God changed Sarai’s name to Sarah and promised she would bear a son.'),
      _TriviaQuestion('Who explained Pharaoh’s dreams in Egypt?', ['Daniel', 'Joseph', 'Moses', 'Aaron'], 1, 'Genesis 41:14–32', 'Joseph explained Pharaoh’s dreams and warned of coming famine.'),
      _TriviaQuestion('Which couple hosted a church in their home and worked with Paul?', ['Aquila and Priscilla', 'Ananias and Sapphira', 'Zechariah and Elizabeth', 'Herod and Herodias'], 0, '1 Corinthians 16:19', 'Aquila and Priscilla hosted a church in their home.'),
      _TriviaQuestion('Who was the first Christian martyr recorded in Acts?', ['James', 'Stephen', 'Philip', 'Barnabas'], 1, 'Acts 7:54–60', 'Stephen was killed after bearing witness about Jesus.'),
      _TriviaQuestion('Which book comes immediately after the Gospel of John?', ['Romans', 'Acts', 'Hebrews', 'Revelation'], 1, 'New Testament order', 'Acts follows the four Gospels in the New Testament.'),
      _TriviaQuestion('What was the name of the servant whose ear Peter cut off?', ['Malchus', 'Bartimaeus', 'Tychicus', 'Onesimus'], 0, 'John 18:10', 'John identifies the servant as Malchus.'),
      _TriviaQuestion('Which reference says, “The just shall live by faith”?', ['Romans 1:17', 'Romans 5:1', 'Hebrews 4:12', 'James 2:17'], 0, 'Romans 1:17', 'Paul quotes the statement that the just shall live by faith.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter does Paul describe the armour of God?', ['Ephesians 2', 'Ephesians 4', 'Ephesians 6', 'Ephesians 5'], 2, 'Ephesians 6:10–18', 'The armour of God passage is in Ephesians chapter 6.', isVerseChallenge: true),
      _TriviaQuestion('Where is the verse, “Let every thing that hath breath praise the LORD” found?', ['Psalm 100:1', 'Psalm 145:18', 'Psalm 150:6', 'Psalm 34:1'], 2, 'Psalm 150:6', 'Psalm 150 closes by calling everything that has breath to praise the Lord.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter contains the account of the valley of dry bones?', ['Ezekiel 34', 'Ezekiel 36', 'Ezekiel 37', 'Ezekiel 40'], 2, 'Ezekiel 37:1–14', 'The vision of the dry bones is recorded in Ezekiel chapter 37.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “Create in me a clean heart, O God”?', ['Psalm 32:5', 'Psalm 51:10', 'Psalm 63:1', 'Psalm 139:23'], 1, 'Psalm 51:10', 'David asks God for a clean heart in Psalm 51.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter does Jesus raise Lazarus from the dead?', ['John 9', 'John 10', 'John 11', 'John 12'], 2, 'John 11:1–44', 'The raising of Lazarus is narrated in John chapter 11.', isVerseChallenge: true),
      _TriviaQuestion('Where is the verse, “Faith without works is dead” found?', ['Hebrews 11:1', 'James 1:5', 'James 2:17', '1 Peter 1:7'], 2, 'James 2:17', 'James explains that genuine faith is demonstrated by action.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter records the fruit of the Spirit?', ['Galatians 3', 'Galatians 4', 'Galatians 5', 'Galatians 6'], 2, 'Galatians 5:22–23', 'The fruit of the Spirit is listed in Galatians chapter 5.', isVerseChallenge: true),
      _TriviaQuestion('Who was the first high priest of Israel?', ['Moses', 'Aaron', 'Eleazar', 'Joshua'], 1, 'Exodus 28:1; 29:9', 'Aaron and his sons were appointed to the priesthood, with Aaron serving as high priest.'),
      _TriviaQuestion('Which disciple was also called Didymus?', ['Peter', 'Thomas', 'Matthew', 'Philip'], 1, 'John 11:16; 20:24', 'Didymus means twin and is used of Thomas.'),
      _TriviaQuestion('Which river did Naaman wash in when he followed Elisha’s instruction?', ['Nile', 'Euphrates', 'Jordan', 'Tigris'], 2, '2 Kings 5:10–14', 'Naaman dipped himself seven times in the Jordan.'),
      _TriviaQuestion('In which chapter does Saul encounter Jesus on the road to Damascus?', ['Acts 2', 'Acts 5', 'Acts 9', 'Acts 16'], 2, 'Acts 9:1–19', 'Saul’s conversion and encounter with Jesus are recorded in Acts chapter 9.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter contains the parable of the prodigal son in Luke?', ['Luke 10', 'Luke 12', 'Luke 15', 'Luke 18'], 2, 'Luke 15:11–32', 'The parable of the prodigal son appears in Luke chapter 15.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter of Matthew is the parable of the ten virgins recorded?', ['Matthew 13', 'Matthew 18', 'Matthew 22', 'Matthew 25'], 3, 'Matthew 25:1–13', 'Jesus tells the parable of the ten virgins in Matthew chapter 25.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter records Elijah’s contest with the prophets of Baal on Mount Carmel?', ['1 Kings 17', '1 Kings 18', '1 Kings 19', '2 Kings 2'], 1, '1 Kings 18:20–39', 'The contest on Mount Carmel is recorded in 1 Kings chapter 18.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter is Abraham tested when God tells him to offer Isaac?', ['Genesis 12', 'Genesis 15', 'Genesis 22', 'Genesis 32'], 2, 'Genesis 22:1–19', 'The account of Abraham’s test is found in Genesis chapter 22.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter describes the Israelites crossing the Red Sea?', ['Exodus 3', 'Exodus 12', 'Exodus 14', 'Exodus 20'], 2, 'Exodus 14:15–31', 'The crossing of the Red Sea is narrated in Exodus chapter 14.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter are Shadrach, Meshach and Abednego thrown into the fiery furnace?', ['Daniel 1', 'Daniel 2', 'Daniel 3', 'Daniel 6'], 2, 'Daniel 3:19–27', 'The fiery furnace account is found in Daniel chapter 3.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter records Esther deciding to approach the king on behalf of her people?', ['Esther 2', 'Esther 3', 'Esther 4', 'Esther 7'], 2, 'Esther 4:13–16', 'Esther chapter 4 records her decision to approach the king.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter does Jonah pray to God from inside the great fish?', ['Jonah 1', 'Jonah 2', 'Jonah 3', 'Jonah 4'], 1, 'Jonah 2:1–10', 'Jonah’s prayer from inside the fish is in chapter 2.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter describes Ezra reading the Book of the Law to the gathered people?', ['Nehemiah 2', 'Nehemiah 4', 'Nehemiah 8', 'Nehemiah 13'], 2, 'Nehemiah 8:1–8', 'The public reading and explanation of the Law are recorded in Nehemiah chapter 8.', isVerseChallenge: true),

      _TriviaQuestion('Who became the leader of Israel after Moses died?', ['Caleb', 'Aaron', 'Joshua', 'Eleazar'], 2, 'Joshua 1:1–9', 'God commissioned Joshua to lead the people into the land promised to them.'),
      _TriviaQuestion('What was the name of Samuel’s mother?', ['Deborah', 'Hannah', 'Abigail', 'Michal'], 1, '1 Samuel 1:1–20', 'Hannah prayed for a son and later dedicated Samuel to the Lord’s service.'),
      _TriviaQuestion('Which New Testament chapter is well known for its description of love?', ['Romans 8', '1 Corinthians 13', 'Hebrews 11', 'James 1'], 1, '1 Corinthians 13', 'Paul describes the qualities and lasting importance of love.', isVerseChallenge: true),
      _TriviaQuestion('Where does Scripture say that faith without works is dead?', ['Hebrews 11:1', 'James 2:17', 'Romans 12:2', '1 Peter 5:7'], 1, 'James 2:17', 'James teaches that genuine faith is demonstrated through action.', isVerseChallenge: true),
    ],
    'Hard': const [
      _TriviaQuestion('“The joy of the Lord is your strength.” Where is this verse found?', ['Nehemiah 8:10', 'Habakkuk 3:18', 'Psalm 28:7', 'Isaiah 12:2'], 0, 'Nehemiah 8:10', 'Nehemiah encouraged the people not to grieve, because the Lord’s joy was their strength.', isVerseChallenge: true),
      _TriviaQuestion('“Love is patient, love is kind.” Where is this passage found?', ['Romans 5:8', '1 Corinthians 13:4', 'Galatians 5:22', '1 John 3:18'], 1, '1 Corinthians 13:4', 'Paul describes the qualities of love in 1 Corinthians 13.', isVerseChallenge: true),
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
      _TriviaQuestion('Which king found the Book of the Law during temple repairs?', ['Hezekiah', 'Josiah', 'Ahab', 'Manasseh'], 1, '2 Kings 22:8–11', 'Hilkiah the priest found the Book of the Law during Josiah’s reign.'),
      _TriviaQuestion('Who was the father of Methuselah?', ['Enoch', 'Lamech', 'Jared', 'Noah'], 0, 'Genesis 5:21–27', 'Enoch became the father of Methuselah.'),
      _TriviaQuestion('Which prophet saw a vision of a valley of dry bones?', ['Daniel', 'Ezekiel', 'Zechariah', 'Amos'], 1, 'Ezekiel 37:1–10', 'Ezekiel saw dry bones come together in a vision.'),
      _TriviaQuestion('Who was the mother of King Lemuel, whose sayings appear in Proverbs 31?', ['Bathsheba', 'Hannah', 'Unknown in the text', 'Abigail'], 2, 'Proverbs 31:1', 'Proverbs 31 introduces the sayings as words taught to Lemuel by his mother without naming her.'),
      _TriviaQuestion('Which man was chosen to carry Jesus’ cross?', ['Simon of Cyrene', 'Joseph of Arimathea', 'Nicodemus', 'Barabbas'], 0, 'Luke 23:26', 'Simon of Cyrene was made to carry the cross behind Jesus.'),
      _TriviaQuestion('Which church in Revelation was described as lukewarm?', ['Ephesus', 'Smyrna', 'Laodicea', 'Pergamum'], 2, 'Revelation 3:14–16', 'The message to Laodicea warns that it was neither hot nor cold.'),
      _TriviaQuestion('Who was the father of the sons of Zebedee, James and John?', ['Alphaeus', 'Zebedee', 'Jonah', 'Clopas'], 1, 'Matthew 4:21', 'James and John were the sons of Zebedee.'),
      _TriviaQuestion('Which prophet married Gomer?', ['Amos', 'Hosea', 'Micah', 'Joel'], 1, 'Hosea 1:2–3', 'God instructed Hosea to marry Gomer.'),
      _TriviaQuestion('Who was the Roman governor who questioned Paul in Caesarea?', ['Felix', 'Gallio', 'Pilate', 'Festus'], 0, 'Acts 24:24–27', 'Paul appeared before the governor Felix in Caesarea.'),
      _TriviaQuestion('Which man was described as a chief tax collector in Jericho?', ['Matthew', 'Zacchaeus', 'Cornelius', 'Levi'], 1, 'Luke 19:1–2', 'Luke describes Zacchaeus as a chief tax collector.'),
      _TriviaQuestion('Which reference contains the words, “The fear of the LORD is the beginning of knowledge”?', ['Proverbs 1:7', 'Proverbs 3:5', 'Ecclesiastes 12:13', 'Job 28:28'], 0, 'Proverbs 1:7', 'Proverbs begins by identifying reverence for the Lord as the beginning of knowledge.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter does Paul list the gifts of the Spirit, including wisdom, knowledge and faith?', ['1 Corinthians 10', '1 Corinthians 12', '1 Corinthians 13', '1 Corinthians 15'], 1, '1 Corinthians 12:4–11', 'The gifts of the Spirit are discussed in 1 Corinthians chapter 12.', isVerseChallenge: true),
      _TriviaQuestion('Where is the verse, “Thy word have I hid in mine heart, that I might not sin against thee”?', ['Psalm 19:14', 'Psalm 37:4', 'Psalm 119:11', 'Psalm 119:18'], 2, 'Psalm 119:11', 'The psalmist describes keeping God’s word in the heart in Psalm 119:11.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter contains the “hall of faith” passage naming Abel, Enoch, Noah and Abraham?', ['Romans 8', 'Hebrews 10', 'Hebrews 11', 'James 2'], 2, 'Hebrews 11', 'Hebrews chapter 11 recalls people who lived by faith.', isVerseChallenge: true),
      _TriviaQuestion('Where does Micah ask what the Lord requires: to do justly, love mercy and walk humbly?', ['Micah 4:1', 'Micah 5:2', 'Micah 6:8', 'Nahum 1:7'], 2, 'Micah 6:8', 'Micah 6:8 summarizes the conduct God requires.', isVerseChallenge: true),
      _TriviaQuestion('Which chapter records Peter’s sermon on the day of Pentecost?', ['Acts 1', 'Acts 2', 'Acts 4', 'Acts 10'], 1, 'Acts 2:14–41', 'Peter addressed the crowd in Acts chapter 2 after the coming of the Holy Spirit.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “Be ye doers of the word, and not hearers only”?', ['James 1:22', 'James 2:14', '1 John 2:5', 'Romans 12:1'], 0, 'James 1:22', 'James urges believers to put the word into practice.', isVerseChallenge: true),
      _TriviaQuestion('In which chapter does Jesus teach the parable of the sower in Matthew?', ['Matthew 10', 'Matthew 12', 'Matthew 13', 'Matthew 18'], 2, 'Matthew 13:1–23', 'The parable of the sower is the first parable in Matthew chapter 13.', isVerseChallenge: true),
      _TriviaQuestion('Which Roman governor presided over Jesus’ trial before the crucifixion?', ['Felix', 'Festus', 'Pontius Pilate', 'Gallio'], 2, 'Matthew 27:11–26; John 18:28–19:16', 'Pontius Pilate questioned Jesus and handed Him over to be crucified.'),
      _TriviaQuestion('Who was the priest whose sons were Hophni and Phinehas?', ['Eli', 'Samuel', 'Zadok', 'Abiathar'], 0, '1 Samuel 1:3; 2:12', 'Eli served as priest while his sons served at the tabernacle.'),
      _TriviaQuestion('Which king of Salem was both king and priest and blessed Abram?', ['Abimelech', 'Melchizedek', 'Adoni-zedek', 'Pharaoh'], 1, 'Genesis 14:18–20', 'Melchizedek was king of Salem and priest of God Most High.'),
      _TriviaQuestion('Which prophet urged the returned exiles to give attention to rebuilding the temple?', ['Zechariah', 'Haggai', 'Malachi', 'Obadiah'], 1, 'Haggai 1:1–8', 'Haggai called the people to consider their ways and rebuild the Lord’s house.'),
      _TriviaQuestion('Where is the promise, “They that wait upon the LORD shall renew their strength”?', ['Isaiah 26:3', 'Isaiah 40:31', 'Jeremiah 17:7', 'Lamentations 3:23'], 1, 'Isaiah 40:31', 'Isaiah 40:31 promises renewed strength to those who wait upon the Lord.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “The just shall live by his faith”?', ['Habakkuk 1:5', 'Habakkuk 2:4', 'Zephaniah 3:17', 'Malachi 3:10'], 1, 'Habakkuk 2:4', 'Habakkuk 2:4 contrasts the proud with the one who lives by faith.', isVerseChallenge: true),
      _TriviaQuestion('Where is the passage that begins, “For I know the thoughts that I think toward you”?', ['Jeremiah 1:5', 'Jeremiah 17:7', 'Jeremiah 29:11', 'Jeremiah 31:3'], 2, 'Jeremiah 29:11', 'The promise appears in Jeremiah’s letter to the exiles in Babylon.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says that all Scripture is given by inspiration of God?', ['2 Timothy 2:15', '2 Timothy 3:16', 'Titus 2:11', 'Hebrews 4:12'], 1, '2 Timothy 3:16', 'Paul teaches Timothy about the inspiration and usefulness of Scripture.', isVerseChallenge: true),
      _TriviaQuestion('Where does the Bible urge believers to run with patience the race set before them?', ['Hebrews 10:24', 'Hebrews 11:1', 'Hebrews 12:1', 'Hebrews 13:5'], 2, 'Hebrews 12:1', 'Hebrews 12:1 uses the picture of a race to encourage perseverance.', isVerseChallenge: true),
      _TriviaQuestion('Which reference tells believers to cast all their care upon God because He cares for them?', ['1 Peter 2:9', '1 Peter 3:15', '1 Peter 5:7', '2 Peter 1:5'], 2, '1 Peter 5:7', 'Peter encourages believers to place their anxieties on God.', isVerseChallenge: true),
      _TriviaQuestion('Where is the verse that says all things work together for good to them that love God?', ['Romans 5:8', 'Romans 8:28', 'Romans 10:17', 'Romans 12:21'], 1, 'Romans 8:28', 'Paul writes about God working in all things for the good of those who love Him.', isVerseChallenge: true),
      _TriviaQuestion('Which reference instructs believers to work heartily, as to the Lord and not unto men?', ['Colossians 2:6', 'Colossians 3:17', 'Colossians 3:23', 'Colossians 4:2'], 2, 'Colossians 3:23', 'Paul teaches believers to work wholeheartedly as serving the Lord.', isVerseChallenge: true),
      _TriviaQuestion('Where is the instruction, “Delight thyself also in the LORD”?', ['Psalm 27:1', 'Psalm 34:8', 'Psalm 37:4', 'Psalm 46:1'], 2, 'Psalm 37:4', 'Psalm 37 encourages trust and delight in the Lord.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says, “Iron sharpeneth iron; so a man sharpeneth the countenance of his friend”?', ['Proverbs 15:1', 'Proverbs 17:17', 'Proverbs 27:17', 'Ecclesiastes 4:9'], 2, 'Proverbs 27:17', 'Proverbs 27:17 uses iron sharpening iron as a picture of mutual encouragement.', isVerseChallenge: true),

      _TriviaQuestion('Which king asked God for wisdom instead of riches or long life?', ['David', 'Saul', 'Solomon', 'Hezekiah'], 2, '1 Kings 3:5–14', 'Solomon asked for an understanding heart to govern God’s people.'),
      _TriviaQuestion('Which prophet was instructed to marry Gomer?', ['Amos', 'Hosea', 'Micah', 'Joel'], 1, 'Hosea 1:1–3', 'Hosea’s family life became part of the prophetic message to Israel.'),
      _TriviaQuestion('Where does the Bible speak of running the race with patience?', ['Hebrews 12:1', 'Romans 5:1', '1 Timothy 4:8', '2 Timothy 4:7'], 0, 'Hebrews 12:1', 'Hebrews encourages believers to run with endurance, fixing their eyes on Jesus.', isVerseChallenge: true),
      _TriviaQuestion('Which reference says that God’s mercies are new every morning?', ['Isaiah 40:31', 'Lamentations 3:22–23', 'Psalm 19:1', 'Matthew 5:9'], 1, 'Lamentations 3:22–23', 'Lamentations points to God’s unfailing compassion and faithfulness.', isVerseChallenge: true),
    ],
  };

  String _difficulty = 'All';
  String _category = 'All Questions';
  int _selectedLevel = 1;
  Map<String, List<_TriviaQuestion>> _remoteQuestions = {};

  bool _isVerseChallenge(_TriviaQuestion question) =>
      question.isVerseChallenge;

  Iterable<_TriviaQuestion> get _allQuestions => [
        ..._questions.values.expand((items) => items),
        ..._remoteQuestions.values.expand((items) => items),
      ];

  int get _knowledgeQuestionCount => _allQuestions
      .where((question) => !_isVerseChallenge(question))
      .length;

  int get _verseQuestionCount => _allQuestions
      .where(_isVerseChallenge)
      .length;
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
    _loadSelectedLevel();
    _loadRemoteQuestions();
    _startRound();
  }

  Future<void> _loadSelectedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _selectedLevel =
        ((prefs.getInt('ngn_bible_trivia_level') ?? 0) + 1).clamp(1, 1000));
  }

  Future<void> _loadRemoteQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'ngn_bible_trivia_remote_cache';

    // Restore downloaded questions first so they remain available offline.
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final rows = List<Map<String, dynamic>>.from(jsonDecode(cached) as List);
        final grouped = _groupRemoteQuestions(rows);
        if (mounted) setState(() => _remoteQuestions = grouped);
      } catch (_) {
        await prefs.remove(cacheKey);
      }
    }

    try {
      final rows = await Supabase.instance.client
          .from('bible_trivia_questions')
          .select('question,options,correct_index,difficulty,bible_reference,explanation')
          .eq('is_published', true)
          .order('created_at')
          .timeout(const Duration(seconds: 3));
      final remoteRows = List<Map<String, dynamic>>.from(rows);
      final grouped = _groupRemoteQuestions(remoteRows);
      await prefs.setString(cacheKey, jsonEncode(remoteRows));
      if (mounted) setState(() => _remoteQuestions = grouped);
    } catch (_) {
      // The bundled and cached questions remain available offline.
    }
  }

  Map<String, List<_TriviaQuestion>> _groupRemoteQuestions(
      List<Map<String, dynamic>> rows) {
    final grouped = <String, List<_TriviaQuestion>>{
      'Easy': [],
      'Medium': [],
      'Hard': [],
    };
    for (final row in rows) {
      final difficulty = row['difficulty']?.toString() ?? 'Easy';
      final rawOptions = row['options'];
      if (!grouped.containsKey(difficulty) ||
          rawOptions is! List ||
          rawOptions.length != 4 ||
          row['question'] == null ||
          row['bible_reference'] == null ||
          row['explanation'] == null ||
          row['correct_index'] is! num) {
        continue;
      }
      final options = List<String>.from(rawOptions);
      final answerIndex = (row['correct_index'] as num).toInt();
      if (answerIndex < 0 || answerIndex >= options.length) continue;
      grouped[difficulty]!.add(_TriviaQuestion(
        row['question'].toString(),
        options,
        answerIndex,
        row['bible_reference'].toString(),
        row['explanation'].toString(),
      ));
    }
    return grouped;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _highScore = prefs.getInt(_highScoreKey) ?? 0);
  }

  void _startRound() {
    final local = _difficulty == 'All'
        ? _questions.values.expand((items) => items)
        : _questions[_difficulty]!;
    final remote = _difficulty == 'All'
        ? _remoteQuestions.values.expand((items) => items)
        : (_remoteQuestions[_difficulty] ?? <_TriviaQuestion>[]);
    final pool = [...local, ...remote]
        .where((question) => _category == 'All Questions' ||
            (_category == 'Bible Knowledge'
                ? !_isVerseChallenge(question)
                : _isVerseChallenge(question)))
        .toList();
    if (pool.isEmpty) return;
    pool.shuffle(Random(DateTime.now().microsecondsSinceEpoch + _selectedLevel));
    setState(() {
      _round = pool.take(10).toList();
      _index = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _finished = false;
    });
  }

  Future<void> _unlockNextLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('ngn_bible_trivia_level') ?? 0;
    await prefs.setInt('ngn_bible_trivia_level',
        max(saved, _selectedLevel).clamp(0, 999).toInt());
  }

  Future<void> _submitScore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('game_scores').insert({
        'user_id': user.id,
        'game_id': 'bible_trivia',
        'score': _score,
      }).timeout(const Duration(seconds: 3));
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList('ngn_game_score_queue') ?? [];
      queue.add('bible_trivia|$_score');
      await prefs.setStringList('ngn_game_score_queue', queue);
    }
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

  Future<void> _nextQuestion() async {
    if (_index == _round.length - 1) {
      setState(() => _finished = true);
      await _unlockNextLevel();
      await _submitScore();
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
            tooltip: 'Leaderboard',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLeaderboardPage(gameId: 'bible_trivia', gameTitle: 'Bible Trivia'))),
            icon: const Icon(Icons.leaderboard_rounded),
          ),
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
              Icon(Icons.menu_book_rounded, color: _gold),
              SizedBox(width: 8),
              Text('KNOW THE WORD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1)),
              Spacer(),
              Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 5),
              Text('OFFLINE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 18),
            Text(_difficulty.toUpperCase(), style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('LEVEL $_selectedLevel  •  QUESTION ${_index + 1} OF ${_round.length}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
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
            items: ['All', ..._questions.keys].map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
            onChanged: _index == 0 && !_answered
                ? (value) {
                    if (value == null) return;
                    setState(() => _difficulty = value);
                    _startRound();
                  }
                : null,
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('QUESTION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
          const Spacer(),
          DropdownButton<String>(
            value: _category,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'All Questions', child: Text('All Questions')),
              DropdownMenuItem(value: 'Bible Knowledge', child: Text('Bible Knowledge')),
              DropdownMenuItem(value: 'Bible Verses & Chapters', child: Text('Bible Verses & Chapters')),
            ],
            onChanged: _index == 0 && !_answered
                ? (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                    _startRound();
                  }
                : null,
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Question bank: $_knowledgeQuestionCount / 700 Bible knowledge • $_verseQuestionCount / 300 Bible verses & chapters',
          style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : Colors.black54, height: 1.4),
        ),
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
          Text('Level $_selectedLevel completed  •  Your best score: $_highScore', style: TextStyle(color: dark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
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
  const _TriviaQuestion(this.question, this.options, this.answerIndex, this.reference, this.explanation, {this.isVerseChallenge = false});

  final String question;
  final List<String> options;
  final int answerIndex;
  final String reference;
  final String explanation;
  final bool isVerseChallenge;
}
