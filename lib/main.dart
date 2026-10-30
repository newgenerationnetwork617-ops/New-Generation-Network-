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
  static const softYellow = Color(0xFFFFF5CC);
  static const inkBlack = Color(0xFF111827);
  @override
  State<NewGenerationNetworkApp> createState() => _NewGenerationNetworkAppState();
}

class _NewGenerationNetworkAppState extends State<NewGenerationNetworkApp> {
  ThemeMode themeMode = ThemeMode.system;
  static const primaryBlue = Color(0xFF0B5ED7);
  static const accentYellow = Color(0xFFFFC107);
  static const softYellow = Color(0xFFFFF5CC);
  static const inkBlack = Color(0xFF111827);

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
      DevotionalsPage(),
      TeachingsPage(),
      MorePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        indicatorColor: NewGenerationNetworkApp.softYellow,
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories_rounded), label: 'Bible'),
          NavigationDestination(icon: Icon(Icons.favorite_border_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Devotional'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: 'Teachings'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'More'),
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NewGenerationNetworkApp.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('N', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEW GENERATION NETWORK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Raising a righteous generation for Christ', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NewGenerationNetworkApp.primaryBlue, Color(0xFF063B8C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: NewGenerationNetworkApp.accentYellow, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faith. Hope. Truth. Christ.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text('Growing together through God’s Word and impactful Christian content.', style: TextStyle(color: Colors.white, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FutureBuilder<Map<String, dynamic>?>(
              future: repo.dailyVerse(),
              builder: (context, snapshot) {
                final verse = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.menu_book_rounded, color: NewGenerationNetworkApp.primaryBlue),
                        SizedBox(width: 8),
                        Text('Daily Bible Verse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const LinearProgressIndicator()
                      else if (verse == null)
                        const Text('Your daily verse will appear here when published by N.G.N.')
                      else ...[
                        Text('“${verse['verse_text']?.toString() ?? ''}”', style: const TextStyle(fontSize: 17, height: 1.55)),
                        const SizedBox(height: 8),
                        Text(verse['reference']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            const Text('Explore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _QuickCard(icon: Icons.campaign_rounded, title: 'Announcements', page: AnnouncementsPage())),
                SizedBox(width: 12),
                Expanded(child: _QuickCard(icon: Icons.event_rounded, title: 'Events', page: EventsPage())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.title, required this.page});
  final IconData icon;
  final String title;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NewGenerationNetworkApp.softYellow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: NewGenerationNetworkApp.primaryBlue),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
