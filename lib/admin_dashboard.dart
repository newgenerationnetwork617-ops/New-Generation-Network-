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

    return Scaffold(
      appBar: AppBar(
        title: const Text('N.G.N. Admin Dashboard'),
        actions: [
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Content Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Manage N.G.N. content from inside the app.'),
          const SizedBox(height: 24),
          _AdminAction(
            title: 'Manage Existing Content',
            icon: Icons.edit_note_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminContentManagerPage())),
          ),
          _AdminAction(
            title: 'Bible Character Bank',
            icon: Icons.person_search_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBibleCharactersPage())),
          ),
          _AdminAction(
            title: 'Bible Trivia Question Bank',
            icon: Icons.quiz_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBibleTriviaPage())),
          ),
          _AdminAction(
            title: 'Word Search Puzzle Bank',
            icon: Icons.grid_on_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBibleWordSearchPage())),
          ),
          _AdminAction(
            title: 'Community Moderation',
            icon: Icons.groups_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCommunityPage())),
          ),
          _AdminAction(
            title: 'Media Storage',
            icon: Icons.cloud_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStoragePage())),
          ),
          const SizedBox(height: 8),
          _AdminAction(
            title: 'Daily Bible Verse',
            icon: Icons.menu_book_rounded,
            onTap: addBibleVerse,
          ),
          _AdminAction(
            title: 'Daily Devotional',
            icon: Icons.auto_stories_rounded,
            onTap: addDevotional,
          ),
          _AdminAction(
            title: 'Teachings & Sermons',
            icon: Icons.play_circle_fill_rounded,
            onTap: addTeaching,
          ),
          _AdminAction(
            title: 'Upload Teaching Book',
            icon: Icons.menu_book_rounded,
            onTap: addTeachingBook,
          ),
          _AdminAction(
            title: 'Announcements',
            icon: Icons.campaign_rounded,
            onTap: addAnnouncement,
          ),
          _AdminAction(
            title: 'Events',
            icon: Icons.event_rounded,
            onTap: addEvent,
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
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
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
