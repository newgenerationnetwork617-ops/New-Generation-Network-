import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'in_app_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page.dart';
import 'community_page.dart';

import 'admin_dashboard.dart';
import 'bible_page.dart';
import 'content_pages.dart';
import 'content_repository.dart';
import 'bible_trivia_page.dart';
import 'bible_word_puzzle_page.dart';

const supabaseUrl = 'https://nlhjxoevyatvxstxgnhs.supabase.co';
final appNavigatorKey = GlobalKey<NavigatorState>();

const supabasePublishableKey =
    'sb_publishable_QiReFPxygdWtOlRy5Eol6Q_uuubGD7j';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  await InAppNotificationService.instance.initialize();
  runApp(const NewGenerationNetworkApp());
}

class NewGenerationNetworkApp extends StatefulWidget {
  const NewGenerationNetworkApp({super.key});
  static const primaryBlue = Color(0xFF0B5ED7);
  static const accentGold = Color(0xFFD4AF37);


  @override
  State<NewGenerationNetworkApp> createState() => _NewGenerationNetworkAppState();
}

class _NewGenerationNetworkAppState extends State<NewGenerationNetworkApp> {
  ThemeMode themeMode = ThemeMode.system;
  static const primaryBlue = Color(0xFF0B5ED7);
  static const accentGold = Color(0xFFD4AF37);

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
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue).copyWith(
          primary: primaryBlue,
          secondary: accentGold,
          tertiary: const Color(0xFF2E7D32),
          surface: Colors.white,
          onSurface: const Color(0xFF171A1F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        dividerColor: const Color(0xFFE5E7EB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE7EAF0)),
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
          indicatorColor: Color(0xFFE8F0FE),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.dark).copyWith(
          primary: const Color(0xFF7CB0FF),
          secondary: accentGold,
          tertiary: const Color(0xFF66BB6A),
          surface: const Color(0xFF17191D),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F1115), surfaceTintColor: Colors.transparent, elevation: 0),
        cardTheme: CardThemeData(color: const Color(0xFF17191D), surfaceTintColor: Colors.transparent, elevation: 0, shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF2B2F36)), borderRadius: BorderRadius.circular(16))),
        navigationBarTheme: const NavigationBarThemeData(height: 68, elevation: 0, backgroundColor: Color(0xFF14161A), indicatorColor: Color(0xFF24334A)),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF17191D), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF343941)))),
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
    _scheduleLocalMidnightRefresh();
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
      if (mounted) {
        setState(() {});
        _scheduleLocalMidnightRefresh();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeContent(key: ValueKey(DateTime.now().toLocal().toIso8601String().substring(0, 10))),
      const BiblePage(),
      const TeachingsPage(),
      const EventsPage(),
      const CommunityPage(),
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
              backgroundColor: NewGenerationNetworkApp.primaryBlue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.menu_rounded),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories_rounded), label: 'Bible'),
          const NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: 'Media'),
          const NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event_rounded), label: 'Events'),
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
        ],
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
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: NewGenerationNetworkApp.primaryBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('NGN', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: .6)),
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
                    color: const Color(0xFF0B5ED7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x240B5ED7), blurRadius: 24, offset: Offset(0, 10))],
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
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Explore N.G.N.', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              Text('Ministry Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark ? const Color(0xFFD4AF37) : NewGenerationNetworkApp.primaryBlue)),
            ]),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: const [
                _HomeFeatureCard(icon: Icons.play_circle_outline_rounded, title: 'Teachings', subtitle: 'Watch & listen', page: TeachingsPage()),
                _HomeFeatureCard(icon: Icons.auto_stories_outlined, title: 'Holy Bible', subtitle: 'Read the Word', page: BiblePage()),
                _HomeFeatureCard(icon: Icons.favorite_border_rounded, title: 'Devotional', subtitle: 'Grow daily', page: DevotionalsPage()),
                _HomeFeatureCard(icon: Icons.groups_outlined, title: 'Community', subtitle: 'Connect together', page: CommunityPage()),
                _HomeFeatureCard(icon: Icons.calendar_month_outlined, title: 'Events', subtitle: 'Stay connected', page: EventsPage()),
                _HomeFeatureCard(icon: Icons.campaign_outlined, title: 'Announcements', subtitle: 'Latest updates', page: AnnouncementsPage()),
                _HomeFeatureCard(icon: Icons.quiz_rounded, title: 'Bible Trivia', subtitle: 'Test your Bible knowledge', page: BibleTriviaPage()),
                _HomeFeatureCard(icon: Icons.extension_rounded, title: 'Bible Word Puzzle', subtitle: 'Unscramble Bible words', page: BibleWordPuzzlePage()),
              ],
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
