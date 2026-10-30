import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.currentMode, required this.onThemeChanged});
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          RadioListTile<ThemeMode>(title: const Text('System default'), subtitle: const Text('Follow your phone light or dark mode'), value: ThemeMode.system, groupValue: currentMode, onChanged: (v) { if (v != null) onThemeChanged(v); }),
          RadioListTile<ThemeMode>(title: const Text('Light mode'), value: ThemeMode.light, groupValue: currentMode, onChanged: (v) { if (v != null) onThemeChanged(v); }),
          RadioListTile<ThemeMode>(title: const Text('Dark mode'), value: ThemeMode.dark, groupValue: currentMode, onChanged: (v) { if (v != null) onThemeChanged(v); }),
          const Divider(height: 32),
          const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const ListTile(leading: Icon(Icons.chat_rounded), title: Text('WhatsApp / Phone'), subtitle: Text('+234 915 994 2740\n+234 701 818 4333\n+234 906 632 8985\n+234 704 684 7936')),
          const ListTile(leading: Icon(Icons.email_rounded), title: Text('Email'), subtitle: Text('newgenerationnetwork617@gmail.com')),
          const ListTile(leading: Icon(Icons.play_circle_rounded), title: Text('YouTube'), subtitle: Text('@NGNOfficialTV')),
          const Divider(height: 32),
          const ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('About N.G.N.'), subtitle: Text('Raising a Righteous Generation for Christ')),
        ],
      ),
    );
  }
}
