import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_dashboard.dart';
import 'bible_page.dart';
import 'content_pages.dart';
import 'content_repository.dart';

const supabaseUrl = 'https://nlhjxoevyatvxstxgnhs.supabase.co';
const supabasePublishableKey =
    'sb_publishable_QiReFPxygdWtOlRy5Eol6Q_uuubGD7j';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const NewGenerationNetworkApp());
}

class NewGenerationNetworkApp extends StatelessWidget {
  const NewGenerationNetworkApp({super.key});

  static const Color primaryBlue = Color(0xFF0B5ED7);
  static const Color accentYellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEW GENERATION NETWORK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final repo = ContentRepository(Supabase.instance.client);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW GENERATION NETWORK'),
        actions: [
          IconButton(
            tooltip: 'Admin',
            onPressed: () => open(context, const AdminLoginPage()),
            icon: const Icon(Icons.admin_panel_settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/branding/team_logo.jpg',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Raising a righteous generation for Christ.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Faith. Hope. Truth. Christ.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 22),
            FutureBuilder<Map<String, dynamic>?>( 
              future: repo.dailyVerse(),
              builder: (context, snapshot) {
                final verse = snapshot.data;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.menu_book_rounded), SizedBox(width: 8), Text('Daily Bible Verse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const LinearProgressIndicator()
                      else if (verse == null)
                        const Text('Your daily verse will appear here when published by N.G.N.')
                      else ...[
                        Text('“${verse['verse_text']?.toString() ?? ''}”', style: const TextStyle(fontSize: 17, height: 1.5)),
                        const SizedBox(height: 8),
                        Text(verse['reference']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _FeatureCard(title: 'Holy Bible', icon: Icons.auto_stories_rounded, onTap: () => open(context, const BiblePage())),
            _FeatureCard(title: 'Daily Devotional', icon: Icons.favorite_rounded, onTap: () => open(context, const DevotionalsPage())),
            _FeatureCard(title: 'Teachings & Sermons', icon: Icons.play_circle_fill_rounded, onTap: () => open(context, const TeachingsPage())),
            _FeatureCard(title: 'Announcements', icon: Icons.campaign_rounded, onTap: () => open(context, const AnnouncementsPage())),
            _FeatureCard(title: 'Upcoming Events', icon: Icons.event_rounded, onTap: () => open(context, const EventsPage())),
          ],
        ),
      ),
    );
  }
}
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.circle,
          color: NewGenerationNetworkApp.accentYellow,
        ),
        title: Text(title),
        trailing: Icon(icon),
        onTap: onTap,
      ),
    );
  }
}
