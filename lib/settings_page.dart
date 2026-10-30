import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.currentMode, required this.onThemeChanged});
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String language = 'English';
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => language = p.getString('ngn_language') ?? 'English');
    });
  }

  Future<void> saveLanguage(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ngn_language', value);
    if (mounted) setState(() => language = value);
  }

  Future<void> openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 6), child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          ...children,
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section('Appearance', [
            RadioListTile<ThemeMode>(title: const Text('System default'), subtitle: const Text('Follow your phone appearance'), value: ThemeMode.system, groupValue: widget.currentMode, onChanged: (v) { if (v != null) widget.onThemeChanged(v); }),
            RadioListTile<ThemeMode>(title: const Text('Light mode'), value: ThemeMode.light, groupValue: widget.currentMode, onChanged: (v) { if (v != null) widget.onThemeChanged(v); }),
            RadioListTile<ThemeMode>(title: const Text('Dark mode'), value: ThemeMode.dark, groupValue: widget.currentMode, onChanged: (v) { if (v != null) widget.onThemeChanged(v); }),
          ]),
          section('Language', [
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: const Text('App language'),
              subtitle: Text(language == 'English' ? 'English' : '$language (preference saved; translation coming soon)'),
              trailing: DropdownButton<String>(
                value: language,
                underline: const SizedBox.shrink(),
                items: const ['English', 'Yoruba', 'Hausa', 'Igbo'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) { if (v != null) saveLanguage(v); },
              ),
            ),
          ]),
          section('About N.G.N.', const [
            ListTile(leading: Icon(Icons.church_rounded), title: Text('NEW GENERATION NETWORK'), subtitle: Text('Raising a Righteous Generation for Christ')),
            Padding(padding: EdgeInsets.fromLTRB(18, 4, 18, 16), child: Text('Our mission is to spread the Gospel of Jesus Christ, inspire lives, strengthen faith, and bring hope to people around the world through impactful Christian content.', style: TextStyle(height: 1.5))),
          ]),
          section('Contact & Socials', [
            const ListTile(leading: Icon(Icons.chat_rounded), title: Text('WhatsApp / Phone'), subtitle: Text('+234 915 994 2740\n+234 701 818 4333\n+234 906 632 8985\n+234 704 684 7936')),
            const ListTile(leading: Icon(Icons.email_rounded), title: Text('Email'), subtitle: Text('newgenerationnetwork617@gmail.com')),
            const ListTile(leading: Icon(Icons.play_circle_rounded), title: Text('YouTube'), subtitle: Text('@NGNOfficialTV')),
            ListTile(leading: const Icon(Icons.facebook_rounded), title: const Text('Facebook'), subtitle: const Text('NEW GENERATION NETWORK'), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => openLink('https://www.facebook.com/61563641344316/')),
          ]),
          const SizedBox(height: 8),
          const Center(child: Text('N.G.N. • Faith • Hope • Truth • Christ', style: TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
