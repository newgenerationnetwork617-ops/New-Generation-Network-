import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page.dart';

import 'admin_dashboard.dart';
import 'bible_page.dart';
import 'content_pages.dart';
import 'content_repository.dart';

const supabaseUrl = 'https://nlhjxoevyatvxstxgnhs.supabase.co';
final appNavigatorKey = GlobalKey<NavigatorState>();

const supabasePublishableKey =
    'sb_publishable_QiReFPxygdWtOlRy5Eol6Q_uuubGD7j';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const NewGenerationNetworkApp());
}

class NewGenerationNetworkApp extends StatefulWidget {
  const NewGenerationNetworkApp({super.key});
  static const primaryBlue = Color(0xFF0B5ED7);
  static const accentYellow = Color(0xFFFFC107);


  @override
  State<NewGenerationNetworkApp> createState() => _NewGenerationNetworkAppState();
}

class _NewGenerationNetworkAppState extends State<NewGenerationNetworkApp> {
  ThemeMode themeMode = ThemeMode.system;
  static const primaryBlue = Color(0xFF0B5ED7);
  static const accentYellow = Color(0xFFFFC107);

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
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue).copyWith(
          secondary: accentYellow,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFCF2),
        cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        navigationBarTheme: const NavigationBarThemeData(height: 72, elevation: 8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF14213D),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, brightness: Brightness.dark).copyWith(secondary: accentYellow),
        cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      ),
      home: SplashScreen(onDone: () => Navigator.of(appNavigatorKey.currentContext!).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()))),
      navigatorKey: appNavigatorKey,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      HomeContent(),
      BiblePage(),
      TeachingsPage(),
      EventsPage(),
      MorePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        indicatorColor: const Color(0xFFFFF5CC),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories_rounded), label: 'Bible'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: 'Media'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event_rounded), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
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
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => repo.dailyVerse(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF061A45), Color(0xFF075FD8), Color(0xFF19A7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: NewGenerationNetworkApp.accentYellow, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x33005FCC), blurRadius: 22, offset: Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset('assets/branding/team_logo.jpg', width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEW GENERATION', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                            Text('NETWORK', style: TextStyle(color: NewGenerationNetworkApp.accentYellow, fontSize: 27, fontWeight: FontWeight.w900)),
                            Text('Raising a Righteous Generation for Christ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: repo.dailyVerse(),
                    builder: (context, snapshot) {
                      final verse = snapshot.data;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: NewGenerationNetworkApp.accentYellow, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.auto_stories_rounded, color: Color(0xFF062E73)),
                              SizedBox(width: 9),
                              Text('Daily Bible Verse', style: TextStyle(color: Color(0xFF071A40), fontSize: 19, fontWeight: FontWeight.w900)),
                            ]),
                            const SizedBox(height: 12),
                            if (snapshot.connectionState == ConnectionState.waiting)
                              const LinearProgressIndicator()
                            else if (verse == null)
                              const Text('Your daily verse will appear here when published by N.G.N.', style: TextStyle(color: Color(0xFF24324B), height: 1.5))
                            else ...[
                              Text('“${verse['verse_text']?.toString() ?? ''}”', style: const TextStyle(color: Color(0xFF071A40), fontSize: 17, height: 1.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(verse['reference']?.toString() ?? '', style: const TextStyle(color: Color(0xFF075FD8), fontWeight: FontWeight.w900)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: const [
                _HomeFeatureCard(icon: Icons.play_circle_fill_rounded, title: 'Teachings', subtitle: 'Video & Audio', page: TeachingsPage(), blue: true),
                _HomeFeatureCard(icon: Icons.menu_book_rounded, title: 'Bible Studies', subtitle: 'Grow in Faith', page: BiblePage(), blue: true),
                _HomeFeatureCard(icon: Icons.eco_rounded, title: 'Daily Devotional', subtitle: 'Walk with God', page: DevotionalsPage(), blue: false),
                _HomeFeatureCard(icon: Icons.cloud_upload_rounded, title: 'Latest Uploads', subtitle: 'New Content', page: TeachingsPage(), blue: true),
                _HomeFeatureCard(icon: Icons.calendar_month_rounded, title: 'Events', subtitle: 'Join Us', page: EventsPage(), blue: false),
                _HomeFeatureCard(icon: Icons.campaign_rounded, title: 'Announcements', subtitle: 'Stay Informed', page: AnnouncementsPage(), blue: true),
              ],
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                SizedBox(width: 5, height: 30, child: DecoratedBox(decoration: BoxDecoration(color: NewGenerationNetworkApp.accentYellow))),
                SizedBox(width: 10),
                Text('Featured Content', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF071A40))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF061A45), Color(0xFF075FD8)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: NewGenerationNetworkApp.accentYellow),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: NewGenerationNetworkApp.accentYellow, size: 38),
                  SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Growing in Faith Together', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(height: 5),
                    Text('Bible • Teachings • Devotional • Events', style: TextStyle(color: Color(0xFFDCEBFF))),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({required this.icon, required this.title, required this.subtitle, required this.page, required this.blue});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    final colors = blue
        ? const [Color(0xFF0A8DFF), Color(0xFF063B9C)]
        : const [Color(0xFFFFE83D), Color(0xFFFFB300)];
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: blue ? Colors.white : const Color(0xFF071A40), size: 34),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: blue ? Colors.white : const Color(0xFF071A40), fontSize: 17, fontWeight: FontWeight.w900)),
              Text(subtitle, style: TextStyle(color: blue ? const Color(0xFFDCEBFF) : const Color(0xFF263238), fontSize: 12)),
            ]),
          ],
        ),
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('More', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _MoreTile(icon: Icons.campaign_rounded, title: 'Announcements', onTap: () => open(context, const AnnouncementsPage())),
          _MoreTile(icon: Icons.event_rounded, title: 'Upcoming Events', onTap: () => open(context, const EventsPage())),
          _MoreTile(icon: Icons.settings_rounded, title: 'Settings', onTap: () => open(context, SettingsPage(currentMode: context.findAncestorStateOfType<_NewGenerationNetworkAppState>()?.themeMode ?? ThemeMode.system, onThemeChanged: (mode) => context.findAncestorStateOfType<_NewGenerationNetworkAppState>()?.changeTheme(mode)))),
          _MoreTile(icon: Icons.admin_panel_settings_rounded, title: 'Administrator', onTap: () => open(context, const AdminLoginPage())),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon, color: NewGenerationNetworkApp.primaryBlue),
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
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Image.asset('assets/branding/team_logo.jpg', width: 150, height: 150, fit: BoxFit.contain), const SizedBox(height: 24), const Text('NEW GENERATION NETWORK', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Raising a Righteous Generation for Christ', textAlign: TextAlign.center)]))));
}
