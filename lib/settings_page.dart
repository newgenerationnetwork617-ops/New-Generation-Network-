import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.currentMode, required this.onThemeChanged});
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  Future<void> openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 6), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .2))),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          section('Appearance', [
            RadioGroup<ThemeMode>(
              groupValue: widget.currentMode,
              onChanged: (v) { if (v != null) widget.onThemeChanged(v); },
              child: const Column(children: [
                RadioListTile<ThemeMode>(title: Text('System default'), subtitle: Text('Follow your phone appearance'), value: ThemeMode.system),
                RadioListTile<ThemeMode>(title: Text('Light mode'), value: ThemeMode.light),
                RadioListTile<ThemeMode>(title: Text('Dark mode'), value: ThemeMode.dark),
              ]),
            ),
          ]),
          section('About N.G.N.', const [
            ListTile(leading: Icon(Icons.church_rounded), title: Text('NEW GENERATION NETWORK'), subtitle: Text('Raising a Righteous Generation for Christ')),
            Padding(padding: EdgeInsets.fromLTRB(18, 4, 18, 16), child: Text('Our mission is to spread the Gospel of Jesus Christ, inspire lives, strengthen faith, and bring hope to people around the world through impactful Christian content.', style: TextStyle(height: 1.5))),
          ]),
          section('Contact & Socials', [
            ListTile(leading: const Icon(Icons.chat_rounded), title: const Text('WhatsApp'), subtitle: const Text('+234 915 994 2740'), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => openLink('https://wa.me/2349159942740')),
            ListTile(leading: const Icon(Icons.phone_rounded), title: const Text('Call N.G.N.'), subtitle: const Text('+234 701 818 4333'), trailing: const Icon(Icons.call_rounded), onTap: () => openLink('tel:+2347018184333')),
            const ListTile(leading: Icon(Icons.phone_outlined), title: Text('Other contact numbers'), subtitle: Text('+234 906 632 8985\n+234 704 684 7936')),
            ListTile(leading: const Icon(Icons.email_rounded), title: const Text('Email'), subtitle: const Text('newgenerationnetwork617@gmail.com'), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => openLink('mailto:newgenerationnetwork617@gmail.com')),
            ListTile(leading: const Icon(Icons.play_circle_rounded), title: const Text('YouTube'), subtitle: const Text('@NGNOfficialTV'), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => openLink('https://www.youtube.com/@NGNOfficialTV')),
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
