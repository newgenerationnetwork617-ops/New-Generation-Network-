import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'in_app_notifications.dart';
import 'daily_local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'push_notification_service.dart';

import 'settings_page.dart';
import 'community_page.dart';

import 'admin_dashboard.dart';
import 'bible_page.dart';
import 'content_pages.dart';
import 'content_repository.dart';
import 'bible_trivia_page.dart';
import 'bible_word_puzzle_page.dart';
import 'bible_grid_search_page.dart';
import 'guess_bible_character_page.dart';
import 'game_lobby_page.dart';

const supabaseUrl = 'https://nlhjxoevyatvxstxgnhs.supabase.co';
final appNavigatorKey = GlobalKey<NavigatorState>();

const supabasePublishableKey =
    'sb_publishable_QiReFPxygdWtOlRy5Eol6Q_uuubGD7j';

Future<void> _initializePushNotificationsSafely() async {
  try {
    await PushNotificationService.instance.initialize();
  } catch (error, stackTrace) {
    // Push is optional: log the issue but never prevent the app from opening.
    debugPrint('NGN push notification setup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);

  // Render NGN before initializing notification plugins. Device timezone and
  // notification platform calls can be slow or unavailable on some phones;
  // they must never hold the app on a blank startup screen.
  // Render the app before starting optional notification setup. If Firebase,
  // Google Play services, or notification permissions are unavailable, NGN
  // must still open normally instead of remaining on a black screen.
  runApp(const NewGenerationNetworkApp());

  unawaited(_initializePushNotificationsSafely());
  // In-app counters and guest chat identity can refresh after the first frame.
  unawaited(InAppNotificationService.instance.initialize());
}

class NewGenerationNetworkApp extends StatefulWidget {
  const NewGenerationNetworkApp({super.key});
  static const primaryBlue = Color(0xFF073B8C);
  static const accentGold = Color(0xFFD4AF37);


  @override
  State<NewGenerationNetworkApp> createState() => _NewGenerationNetworkAppState();
}

class _NewGenerationNetworkAppState extends State<NewGenerationNetworkApp> {
  ThemeMode themeMode = ThemeMode.system;
  static const primaryBlue = Color(0xFF1746A2);
  static const accentGold = Color(0xFFFFC94A);

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString('ngn_theme_mode') ?? 'system';
      if (mounted) setState(() => themeMode = saved == 'light' ? ThemeMode.light : saved == 'dark' ? ThemeMode.dark : ThemeMode.system);
    });
  }

  Future<void> changeTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ngn_theme_mode', mode.name);
    if (mounted) setState(() => themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEW GENERATION NETWORK',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue).copyWith(
          primary: primaryBlue,
          secondary: accentGold,
          tertiary: const Color(0xFF12A887),
          surface: Colors.white,
          onSurface: const Color(0xFF171A1F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F5FA),
        dividerColor: const Color(0xFFE3E8F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE3E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD8DDE6))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD8DDE6))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 1.5)),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
        navigationBarTheme: const NavigationBarThemeData(
          height: 68,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFF3E7B5),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.dark).copyWith(
          primary: const Color(0xFF9ABEFF),
          secondary: accentGold,
          tertiary: const Color(0xFF45C7A4),
          surface: const Color(0xFF102A50),
        ),
        scaffoldBackgroundColor: const Color(0xFF061B3A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF081629), surfaceTintColor: Colors.transparent, elevation: 0),
        cardTheme: CardThemeData(color: const Color(0xFF13233A), surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF263B57)), borderRadius: BorderRadius.circular(16))),
        navigationBarTheme: const NavigationBarThemeData(height: 68, elevation: 0, backgroundColor: Color(0xFF0D1E33), indicatorColor: Color(0xFF1B3A62)),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF13233A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF304660)))),
      ),
      home: SplashScreen(onDone: () => Navigator.of(appNavigatorKey.currentContext!).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()))),
      navigatorKey: appNavigatorKey,
    );
  }
}

class _NotificationBadgeIcon extends StatelessWidget {
  const _NotificationBadgeIcon({
    required this.icon,
    required this.unread,
    this.color,
  });

  final IconData icon;
  final ValueListenable<int> unread;
  final Color? color;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: unread,
        builder: (context, count, child) => Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color),
            if (count > 0)
              Positioned(
                top: -9,
                right: -12,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 500 ? '500+' : count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int index = 0;
  Timer? _dayRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DailyLocalNotificationService.instance.openedPayload.addListener(_handleDailyNotificationTap);
    _scheduleLocalMidnightRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Notification scheduling is optional and can take time on some devices.
      // Keep navigation and the first screen responsive even if it fails.
      unawaited(_initializeDailyNotificationsSafely());
    });
  }

  Future<void> _initializeDailyNotificationsSafely() async {
    try {
      await DailyLocalNotificationService.instance.initialize();
      if (!mounted) return;
      _handleDailyNotificationTap();
      await DailyLocalNotificationService.instance.requestPermissionAndSchedule();
    } catch (error, stackTrace) {
      // Notifications are an optional convenience, never a reason to block NGN.
      debugPrint('NGN local notification setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleDailyNotificationTap() {
    final service = DailyLocalNotificationService.instance;
    final payload = service.openedPayload.value;
    if (payload == null || !mounted) return;
    service.openedPayload.value = null;
    if (payload.startsWith('devotional:')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DevotionalsPage()),
      );
    } else if (payload.startsWith('word:')) {
      setState(() => index = 0);
    } else if (payload.startsWith('reflection:')) {
      setState(() => index = 2);
    }
  }

  void _scheduleLocalMidnightRefresh() {
    _dayRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _dayRefreshTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleLocalMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      InAppNotificationService.instance.refreshCounts();
      DailyLocalNotificationService.instance.scheduleUpcoming();
      if (mounted) {
        setState(() {});
        _scheduleLocalMidnightRefresh();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DailyLocalNotificationService.instance.openedPayload.removeListener(_handleDailyNotificationTap);
    _dayRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeContent(key: ValueKey(DateTime.now().toLocal().toIso8601String().substring(0, 10))),
      const BiblePage(),
      const DevotionalsPage(),
      const TeachingsPage(),
      const CommunityPage(),
      const BibleGamesHubPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      // Keep the menu floating clear of the bottom navigation and chat composer.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: index == 4
          ? null
          : FloatingActionButton.small(
              tooltip: 'More, Settings & Admin',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MorePage()),
              ),
              backgroundColor: NewGenerationNetworkApp.accentGold,
              foregroundColor: const Color(0xFF081629),
              child: const Icon(Icons.menu_rounded),
            ),
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories_rounded), label: 'Bible'),
          const NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny_rounded), label: 'Devotion'),
          const NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: 'Teachings'),
          NavigationDestination(
            icon: _NotificationBadgeIcon(
              icon: Icons.groups_outlined,
              unread: InAppNotificationService.instance.communityUnread,
            ),
            selectedIcon: _NotificationBadgeIcon(
              icon: Icons.groups_rounded,
              unread: InAppNotificationService.instance.communityUnread,
            ),
            label: 'Community',
          ),
          const NavigationDestination(icon: Icon(Icons.extension_outlined), selectedIcon: Icon(Icons.extension_rounded), label: 'Games'),
        ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => repo.wordForDate(DateTime.now()),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(children: [
              Container(
                width: 54, height: 54,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NewGenerationNetworkApp.accentGold.withValues(alpha: .75)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x160B2450), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Image.asset(
                  'assets/branding/ngn_team_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('NGN', style: TextStyle(color: NewGenerationNetworkApp.primaryBlue, fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NEW GENERATION NETWORK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .25)),
                SizedBox(height: 2),
                Text('Raising a Righteous Generation for Christ', style: TextStyle(fontSize: 11.5, color: Color(0xFF667085))),
              ])),
            ]),
            const SizedBox(height: 22),
            FutureBuilder<Map<String, dynamic>?>(
              future: repo.wordForDate(DateTime.now()),
              builder: (context, snapshot) {
                final verse = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF123A82), Color(0xFF1764C0), Color(0xFF0D2D64)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: NewGenerationNetworkApp.accentGold.withValues(alpha: .45)),
                    boxShadow: const [BoxShadow(color: Color(0x26123A82), blurRadius: 26, offset: Offset(0, 11))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.auto_stories_rounded, color: NewGenerationNetworkApp.accentGold, size: 21),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(child: Text('WORD FOR TODAY', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
                    ]),
                    const SizedBox(height: 18),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator()
                    else if (verse == null)
                      const Text('Your offline Word for Today is not available for this date.', style: TextStyle(color: Colors.white, height: 1.55))
                    else ...[
                      Text(verse['word']?.toString() ?? '', style: const TextStyle(color: NewGenerationNetworkApp.accentGold, fontSize: 25, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      Text(verse['meaning']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
                      const SizedBox(height: 16),
                      Text('“${verse['verse_text']?.toString() ?? ''}”', style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Text(verse['reference']?.toString() ?? '', style: const TextStyle(color: NewGenerationNetworkApp.accentGold, fontSize: 14, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(verse['translation']?.toString() ?? 'World English Bible (WEB)', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 16),
                    Container(width: 42, height: 3, decoration: BoxDecoration(color: NewGenerationNetworkApp.accentGold, borderRadius: BorderRadius.circular(99))),
                  ]),
                );
              },
            ),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevotionalsPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dark
                        ? const [Color(0xFF18345B), Color(0xFF12243D)]
                        : const [Color(0xFFFFF8E5), Color(0xFFFFFDF7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NewGenerationNetworkApp.accentGold.withValues(alpha: .65), width: 1.2),
                ),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: NewGenerationNetworkApp.accentGold.withValues(alpha: .18), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.favorite_rounded, color: NewGenerationNetworkApp.accentGold, size: 29),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOUR DAILY DEVOTIONAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.05, color: NewGenerationNetworkApp.accentGold)),
                    SizedBox(height: 5),
                    Text('Spend time in God’s Word', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Read today’s message and grow in faith.', style: TextStyle(fontSize: 12.5, height: 1.35)),
                  ])),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: dark ? Colors.white : NewGenerationNetworkApp.primaryBlue),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Explore N.G.N.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text('Ministry Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? const Color(0xFFD4AF37) : NewGenerationNetworkApp.primaryBlue)),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _HomeQuickLink(icon: Icons.event_rounded, label: 'Upcoming Events', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsPage()))),
                _HomeQuickLink(icon: Icons.campaign_rounded, label: 'Announcements', onTap: () {
                  InAppNotificationService.instance.markAnnouncementsRead();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsPage()));
                }),
              ],
            ),
            const SizedBox(height: 18),
            const SizedBox(
              height: 126,
              child: _HomeFeatureCard(
                icon: Icons.extension_rounded,
                title: 'Bible Games',
                subtitle: 'Learn and enjoy four Bible games',
                page: BibleGamesHubPage(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF162238) : const Color(0xFFFFFBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NewGenerationNetworkApp.accentGold.withValues(alpha: .38)),
              ),
              child: const Row(children: [
                Icon(Icons.church_outlined, color: NewGenerationNetworkApp.accentGold),
                SizedBox(width: 12),
                Expanded(child: Text('Faith • Hope • Righteous Living', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class BibleGamesHubPage extends StatelessWidget {
  const BibleGamesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Games')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          const Text(
            'Learn the Word through play',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a game and enjoy a fun way to grow your Bible knowledge.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.28,
            children: const [
              _HomeFeatureCard(
                icon: Icons.quiz_rounded,
                title: 'Bible Trivia',
                subtitle: 'Test your Bible knowledge',
                page: GameLobbyPage(
                  title: 'Bible Trivia',
                  subtitle: 'Choose a level, grow in the Word and challenge your best score.',
                  gameId: 'bible_trivia',
                  icon: Icons.quiz_rounded,
                  bestKey: 'ngn_bible_trivia_high_score',
                  levelKey: 'ngn_bible_trivia_level',
                  totalLevels: 15,
                  gamePage: BibleTriviaPage(),
                ),
              ),
              _HomeFeatureCard(
                icon: Icons.extension_rounded,
                title: 'Bible Word Cookies',
                subtitle: 'Form Bible words from letter clues',
                page: GameLobbyPage(
                  title: 'Bible Word Cookies',
                  subtitle: 'Build Bible words, solve clues and advance through 1,000 levels.',
                  gameId: 'bible_word_search',
                  icon: Icons.extension_rounded,
                  bestKey: 'ngn_bible_word_search_best',
                  levelKey: 'ngn_bible_word_search_level',
                  totalLevels: 1000,
                  gamePage: BibleWordPuzzlePage(),
                ),
              ),
              _HomeFeatureCard(
                icon: Icons.person_search_rounded,
                title: 'Guess the Bible Character',
                subtitle: 'Who am I? Bible clues',
                page: GameLobbyPage(
                  title: 'Guess the Bible Character',
                  subtitle: 'Read the clues, identify Bible people and start a fresh shuffled round.',
                  gameId: 'guess_bible_character',
                  icon: Icons.person_search_rounded,
                  bestKey: 'ngn_guess_character_best',
                  gamePage: GuessBibleCharacterPage(),
                ),
              ),
              _HomeFeatureCard(
                icon: Icons.grid_on_rounded,
                title: 'Word Search Puzzle',
                subtitle: 'Choose a Bible category and find hidden words',
                page: BibleGridSearchPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeQuickLink extends StatelessWidget {
  const _HomeQuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: NewGenerationNetworkApp.primaryBlue),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF162238) : Colors.white,
      side: BorderSide(color: NewGenerationNetworkApp.primaryBlue.withValues(alpha: .18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({required this.icon, required this.title, required this.subtitle, required this.page});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (page is AnnouncementsPage) {
          InAppNotificationService.instance.markAnnouncementsRead();
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF162238) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dark ? const Color(0xFF26364F) : const Color(0xFFE7EAF0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF0B5ED7).withValues(alpha: .09), borderRadius: BorderRadius.circular(11)),
            child: title == 'Community'
                ? _NotificationBadgeIcon(
                    icon: icon,
                    unread: InAppNotificationService.instance.communityUnread,
                    color: NewGenerationNetworkApp.primaryBlue,
                  )
                : title == 'Announcements'
                    ? _NotificationBadgeIcon(
                        icon: icon,
                        unread: InAppNotificationService.instance.announcementsUnread,
                        color: NewGenerationNetworkApp.primaryBlue,
                      )
                    : Icon(icon, color: NewGenerationNetworkApp.primaryBlue, size: 22),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 11.5, color: dark ? const Color(0xFFADB8CA) : const Color(0xFF667085))),
        ]),
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
          _MoreTile(icon: Icons.campaign_rounded, title: 'Announcements', badge: InAppNotificationService.instance.announcementsUnread, onTap: () { InAppNotificationService.instance.markAnnouncementsRead(); open(context, const AnnouncementsPage()); }),
          _MoreTile(icon: Icons.event_rounded, title: 'Upcoming Events', onTap: () => open(context, const EventsPage())),
          _MoreTile(icon: Icons.groups_rounded, title: 'Community', badge: InAppNotificationService.instance.communityUnread, onTap: () => open(context, const CommunityPage())),
          _MoreTile(icon: Icons.settings_rounded, title: 'Settings', onTap: () => open(context, SettingsPage(currentMode: context.findAncestorStateOfType<_NewGenerationNetworkAppState>()?.themeMode ?? ThemeMode.system, onThemeChanged: (mode) => context.findAncestorStateOfType<_NewGenerationNetworkAppState>()?.changeTheme(mode)))),
            _MoreTile(icon: Icons.admin_panel_settings_rounded, title: 'Administrator', onTap: () => open(context, const AdminLoginPage())),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, required this.onTap, this.badge});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ValueListenable<int>? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: badge == null
            ? Icon(icon, color: NewGenerationNetworkApp.primaryBlue)
            : _NotificationBadgeIcon(
                icon: icon,
                unread: badge!,
                color: NewGenerationNetworkApp.primaryBlue,
              ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 1800), widget.onDone); }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Image.asset('assets/branding/ngn_team_logo.png', width: 168, height: 168, fit: BoxFit.contain), const SizedBox(height: 24), const Text('NEW GENERATION NETWORK', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Raising a Righteous Generation for Christ', textAlign: TextAlign.center)]))));
}
