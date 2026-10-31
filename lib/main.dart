import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_page.dart';
import 'community_page.dart';

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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            const Row(children: [
              Text('N', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: NewGenerationNetworkApp.primaryBlue)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NEW GENERATION NETWORK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Raising a Righteous Generation for Christ', style: TextStyle(fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, dynamic>?>(
              future: repo.dailyVerse(),
              builder: (context, snapshot) {
                final verse = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B5ED7),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x220B5ED7), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.auto_stories_rounded, color: NewGenerationNetworkApp.accentGold),
                      SizedBox(width: 10),
                      Text('Daily Bible Verse', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator()
                    else if (verse == null)
                      const Text('Your daily verse will appear here when published by N.G.N.', style: TextStyle(color: Colors.white, height: 1.5))
                    else ...[
                      Text('“${verse['verse_text']?.toString() ?? ''}”', style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.55)),
                      const SizedBox(height: 10),
                      Text(verse['reference']?.toString() ?? '', style: const TextStyle(color: NewGenerationNetworkApp.accentGold, fontWeight: FontWeight.w800)),
                    ],
                  ]),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text('Explore', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: const [
                _HomeFeatureCard(icon: Icons.play_circle_outline_rounded, title: 'Teachings', page: TeachingsPage()),
                _HomeFeatureCard(icon: Icons.menu_book_outlined, title: 'Bible Studies', page: BiblePage()),
                _HomeFeatureCard(icon: Icons.favorite_border_rounded, title: 'Devotional', page: DevotionalsPage()),
                _HomeFeatureCard(icon: Icons.upload_file_outlined, title: 'Latest Uploads', page: TeachingsPage()),
                _HomeFeatureCard(icon: Icons.calendar_month_outlined, title: 'Events', page: EventsPage()),
                _HomeFeatureCard(icon: Icons.campaign_outlined, title: 'Announcements', page: AnnouncementsPage()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({required this.icon, required this.title, required this.page});
  final IconData icon;
  final String title;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF162238) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dark ? const Color(0xFF26364F) : const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF0B5ED7).withValues(alpha: .10), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: NewGenerationNetworkApp.primaryBlue),
          ),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('More', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _MoreTile(icon: Icons.campaign_rounded, title: 'Announcements', onTap: () => open(context, const AnnouncementsPage())),
          _MoreTile(icon: Icons.event_rounded, title: 'Upcoming Events', onTap: () => open(context, const EventsPage())),
          _MoreTile(icon: Icons.groups_rounded, title: 'Community', onTap: () => open(context, const CommunityPage())),
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
