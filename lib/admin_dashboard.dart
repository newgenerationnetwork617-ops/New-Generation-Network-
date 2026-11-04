import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_content_manager.dart';
import 'admin_storage_page.dart';
import 'admin_community_page.dart';
import 'admin_bible_characters_page.dart';
import 'admin_bible_trivia_page.dart';
import 'admin_bible_word_search_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (_) {
      setState(
        () => error =
            'Unable to connect. Check your internet connection and try again.',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('N.G.N. Admin')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 24),
          const Text(
            'Administrator Sign In',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Only authorized N.G.N. administrators can continue.'),
          const SizedBox(height: 28),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Admin email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (error != null)
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: loading ? null : login,
            child: Text(loading ? 'Signing in...' : 'Sign in'),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  bool checking = true;
  bool allowed = false;
  int selectedSection = 0;

  void notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> runSave(Future<void> Function() action, String success) async {
    try {
      await action();
      notice(success);
      return true;
    } on PostgrestException catch (e) {
      notice('Could not save: ${e.message}');
      return false;
    } catch (_) {
      notice('Could not save. Check your connection and try again.');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    checkAdmin();
  }

  Future<void> checkAdmin() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        );
      }
      return;
    }

    final row = await supabase
        .from('admin_members')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (!mounted) return;
    setState(() {
      allowed = row != null;
      checking = false;
    });

    if (row == null) {
      await supabase.auth.signOut();
      if (!mounted) return;
      setState(() => checking = false);
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
  }

  Future<void> addBibleVerse() async {
    final reference = TextEditingController();
    final verse = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Daily Bible Verse'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              TextField(controller: reference, decoration: const InputDecoration(labelText: 'Bible reference')),
              TextField(controller: verse, maxLines: 4, decoration: const InputDecoration(labelText: 'Verse text')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await runSave(() async {
                await supabase.from('daily_bible_verses').upsert({
                'verse_date': date.text.trim(),
                'reference': reference.text.trim(),
                'verse_text': verse.text.trim(),
                'updated_at': DateTime.now().toIso8601String(),
              });
              }, 'Daily Bible verse published.');
              if (ok && mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    reference.dispose();
    verse.dispose();
    date.dispose();
  }

  Future<void> addDevotional() async {
    final title = TextEditingController();
    final theme = TextEditingController();
    final bible = TextEditingController();
    final message = TextEditingController();
    final application = TextEditingController();
    final memoryVerse = TextEditingController();
    final prayer = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Devotional'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: theme, decoration: const InputDecoration(labelText: 'Theme')),
              TextField(controller: bible, decoration: const InputDecoration(labelText: 'Bible verse')),
              TextField(controller: message, maxLines: 5, decoration: const InputDecoration(labelText: 'Devotional message')),
              TextField(controller: application, maxLines: 4, decoration: const InputDecoration(labelText: 'Life application')),
              TextField(controller: memoryVerse, maxLines: 3, decoration: const InputDecoration(labelText: 'Memory verse (optional)')),
              TextField(controller: prayer, maxLines: 3, decoration: const InputDecoration(labelText: 'Prayer (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await runSave(() async {
                await supabase.from('devotionals').insert({
                'title': title.text.trim(),
                'theme': theme.text.trim(),
                'bible_reference': bible.text.trim(),
                'message': message.text.trim(),
                'life_application': application.text.trim(),
                'memory_verse': memoryVerse.text.trim(),
                'prayer': prayer.text.trim(),
                'published_at': DateTime.now().toIso8601String(),
              });
              }, 'Devotional published.');
              if (ok && mounted) Navigator.pop(context);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    title.dispose();
    theme.dispose();
    bible.dispose();
    message.dispose();
    application.dispose();
    memoryVerse.dispose();
    prayer.dispose();
  }

  Future<void> addTeaching() async {
    final title = TextEditingController();
    final speaker = TextEditingController();
    final description = TextEditingController();
    final url = TextEditingController();
    final mediaUrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Teaching'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: speaker, decoration: const InputDecoration(labelText: 'Speaker')),
              TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: url, decoration: const InputDecoration(labelText: 'YouTube URL (optional)')),
              TextField(controller: mediaUrl, decoration: const InputDecoration(labelText: 'Direct media URL for offline download (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await runSave(() async {
                await supabase.from('teachings').insert({
                'title': title.text.trim(),
                'speaker': speaker.text.trim(),
                'description': description.text.trim(),
                'youtube_url': url.text.trim(),
                'media_url': mediaUrl.text.trim(),
                'published_at': DateTime.now().toIso8601String(),
              });
              }, 'Teaching published.');
              if (ok && mounted) Navigator.pop(context);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    title.dispose();
    speaker.dispose();
    description.dispose();
    url.dispose();
    mediaUrl.dispose();
  }

  Future<void> addTeachingBook() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'],
    );
    if (picked == null || picked.files.single.path == null) return;
    if (!mounted) return;

    final file = picked.files.single;
    const maxBookBytes = 25 * 1024 * 1024;
    if (file.size <= 0 || file.size > maxBookBytes) {
      notice('Choose a teaching book or document smaller than 25 MB.');
      return;
    }
    final extension = file.extension?.toLowerCase() ?? '';
    final baseName = extension.isEmpty
        ? file.name
        : file.name.substring(0, file.name.length - extension.length - 1);
    final title = TextEditingController(text: baseName.replaceAll('_', ' '));
    final speaker = TextEditingController();
    final description = TextEditingController();

    final details = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Teaching Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(file.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Book / teaching title')),
              TextField(controller: speaker, decoration: const InputDecoration(labelText: 'Author / speaker (optional)')),
              TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Upload & publish')),
        ],
      ),
    );

    if (details != true || !mounted) {
      title.dispose();
      speaker.dispose();
      description.dispose();
      return;
    }
    if (title.text.trim().isEmpty) {
      notice('Please enter a title for this teaching book.');
      title.dispose();
      speaker.dispose();
      description.dispose();
      return;
    }

    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    // Keep teaching files at the bucket root so the Media Storage manager can list them.
    final storagePath = 'teaching_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final mime = switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'rtf' => 'application/rtf',
      'odt' => 'application/vnd.oasis.opendocument.text',
      _ => 'application/octet-stream',
    };

    try {
      await supabase.storage.from('ngn-media').upload(
        storagePath,
        File(file.path!),
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );
      final publicUrl = supabase.storage.from('ngn-media').getPublicUrl(storagePath);
      await supabase.from('teachings').insert({
        'title': title.text.trim(),
        'speaker': speaker.text.trim().isEmpty ? null : speaker.text.trim(),
        'description': description.text.trim().isEmpty ? null : description.text.trim(),
        'content_type': 'book',
        'media_url': publicUrl,
        'published_at': DateTime.now().toUtc().toIso8601String(),
      });
      notice('Teaching book uploaded and published.');
    } catch (e) {
      try {
        await supabase.storage.from('ngn-media').remove([storagePath]);
      } catch (_) {}
      notice('Could not upload teaching book: $e');
    } finally {
      title.dispose();
      speaker.dispose();
      description.dispose();
    }
  }

  Future<void> addAnnouncement() async {
    final title = TextEditingController();
    final body = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: body, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await runSave(() async {
                await supabase.from('announcements').insert({
                'title': title.text.trim(),
                'body': body.text.trim(),
                'published_at': DateTime.now().toIso8601String(),
              });
              }, 'Announcement published.');
              if (ok && mounted) Navigator.pop(context);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    title.dispose();
    body.dispose();
  }

  Future<void> addEvent() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final venue = TextEditingController();
    DateTime startsAt = DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Event title')),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: venue, decoration: const InputDecoration(labelText: 'Venue')),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Event date & time'),
                  subtitle: Text(startsAt.toString().substring(0, 16)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startsAt,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startsAt),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final ok = await runSave(() async {
                  await supabase.from('events').insert({
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'venue': venue.text.trim(),
                    'starts_at': startsAt.toUtc().toIso8601String(),
                    'published': true,
                    'published_at': DateTime.now().toUtc().toIso8601String(),
                  });
                }, 'Event published.');
                if (ok && dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    description.dispose();
    venue.dispose();
  }

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? tint,
  }) {
    final color = tint ?? Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionHeading(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget publishGrid() {
    final actions = <({String title, String subtitle, IconData icon, VoidCallback run})>[
      (title: 'Daily Bible Verse', subtitle: 'Publish today’s Scripture', icon: Icons.menu_book_rounded, run: addBibleVerse),
      (title: 'Daily Devotional', subtitle: 'Share a faith-building message', icon: Icons.auto_stories_rounded, run: addDevotional),
      (title: 'Teachings & Sermons', subtitle: 'Add a teaching or sermon', icon: Icons.play_circle_fill_rounded, run: addTeaching),
      (title: 'Teaching Book', subtitle: 'Upload a PDF or document', icon: Icons.picture_as_pdf_rounded, run: addTeachingBook),
      (title: 'Announcement', subtitle: 'Share an important update', icon: Icons.campaign_rounded, run: addAnnouncement),
      (title: 'Create Event', subtitle: 'Publish an upcoming event', icon: Icons.event_rounded, run: addEvent),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((item) => SizedBox(
            width: width,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: item.run,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 27, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget dashboardHome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: 0.78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEW GENERATION NETWORK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              SizedBox(height: 9),
              Text('Welcome, Administrator', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('What would you like to manage today?', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        sectionHeading('Quick publish', subtitle: 'Create and share new content in a few taps'),
        publishGrid(),
        sectionHeading('Manage NGN', subtitle: 'Go directly to the areas you use most'),
        actionTile(title: 'Published Content', subtitle: 'Edit, schedule or remove existing content', icon: Icons.library_books_rounded, onTap: () => openPage(const AdminContentManagerPage())),
        actionTile(title: 'Community', subtitle: 'Moderate conversations and members', icon: Icons.groups_rounded, onTap: () => openPage(const AdminCommunityPage())),
        actionTile(title: 'Media Storage', subtitle: 'Review uploaded files and storage', icon: Icons.cloud_rounded, onTap: () => openPage(const AdminStoragePage())),
      ],
    );
  }

  Widget manageSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const Text('Manage your content', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Find existing posts and keep the NGN experience up to date.'),
        const SizedBox(height: 18),
        actionTile(title: 'Published Content', subtitle: 'Devotionals, teachings, announcements, events and verses', icon: Icons.edit_note_rounded, onTap: () => openPage(const AdminContentManagerPage())),
        actionTile(title: 'Community Moderation', subtitle: 'Manage community activity', icon: Icons.groups_rounded, onTap: () => openPage(const AdminCommunityPage())),
        actionTile(title: 'Media Storage', subtitle: 'Manage uploaded media', icon: Icons.cloud_rounded, onTap: () => openPage(const AdminStoragePage())),
      ],
    );
  }

  Widget toolsSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const Text('Games & question banks', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Maintain the Bible games and their content libraries.'),
        const SizedBox(height: 18),
        actionTile(title: 'Bible Character Bank', subtitle: 'Manage Guess the Bible Character entries', icon: Icons.person_search_rounded, onTap: () => openPage(const AdminBibleCharactersPage())),
        actionTile(title: 'Bible Trivia Question Bank', subtitle: 'Manage Bible quiz questions', icon: Icons.quiz_rounded, onTap: () => openPage(const AdminBibleTriviaPage())),
        actionTile(title: 'Word Search Puzzle Bank', subtitle: 'Manage categories and puzzles', icon: Icons.grid_on_rounded, onTap: () => openPage(const AdminBibleWordSearchPage())),
      ],
    );
  }

  Widget publishSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const Text('Publish to NGN', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Choose what you want to publish. Your content tools are grouped here.'),
        const SizedBox(height: 18),
        publishGrid(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This account is not authorized as an N.G.N. administrator.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pages = [dashboardHome(), publishSection(), manageSection(), toolsSection()];
    final titles = ['Admin Home', 'Publish', 'Manage', 'Game Tools'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedSection]),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(child: pages[selectedSection]),
      floatingActionButton: selectedSection == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => selectedSection = 1),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Publish'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedSection,
        onDestinationSelected: (index) => setState(() => selectedSection = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_box_rounded), label: 'Publish'),
          NavigationDestination(icon: Icon(Icons.folder_open_rounded), label: 'Manage'),
          NavigationDestination(icon: Icon(Icons.extension_rounded), label: 'Games'),
        ],
      ),
    );
  }
}
