import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW GENERATION NETWORK'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            SizedBox(height: 12),
            Text(
              'Raising a righteous generation for Christ.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'To spread the Gospel of Jesus Christ, inspire lives, strengthen faith, and bring hope to people around the world through impactful Christian content.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 28),
            _FeatureCard(
              title: 'Daily Bible Verse',
              icon: Icons.menu_book_rounded,
            ),
            _FeatureCard(
              title: 'Daily Devotional',
              icon: Icons.auto_stories_rounded,
            ),
            _FeatureCard(
              title: 'Teachings & Sermons',
              icon: Icons.play_circle_fill_rounded,
            ),
            _FeatureCard(
              title: 'Announcements & Events',
              icon: Icons.event_rounded,
            ),
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
  });

  final String title;
  final IconData icon;

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
      ),
    );
  }
}
