import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class CommunityStoriesWidget extends StatefulWidget {
  const CommunityStoriesWidget({super.key});

  @override
  State<CommunityStoriesWidget> createState() => _CommunityStoriesWidgetState();
}

class _CommunityStoriesWidgetState extends State<CommunityStoriesWidget> {
  final _supabase = Supabase.instance.client;
  bool _uploading = false;

  Stream<List<Map<String, dynamic>>> get _stories => _supabase
      .from('community_stories')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(60)
      .map((rows) => rows.map((row) => Map<String, dynamic>.from(row)).toList());

  Future<void> _addStory() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.isAnonymous || _uploading) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    if (!mounted) return;

    final file = picked.files.single;
    final ext = (file.extension ?? '').toLowerCase();
    const imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    const videoExtensions = {'mp4', 'mov', 'm4v'};
    final isImage = imageExtensions.contains(ext);
    final isVideo = videoExtensions.contains(ext);
    if (!isImage && !isVideo) {
      _message('Choose a JPG, PNG, WebP image or an MP4/MOV video.');
      return;
    }
    if (file.size > 25 * 1024 * 1024) {
      _message('Please choose a story smaller than 25 MB.');
      return;
    }

    final captionController = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a story caption'),
        content: TextField(
          controller: captionController,
          maxLength: 240,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write a short caption (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, captionController.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    captionController.dispose();
    if (caption == null || !mounted) return;

    final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      _message('The selected file could not be read. Please choose it again.');
      return;
    }

    final mime = isImage
        ? (ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext')
        : (ext == 'mov' ? 'video/quicktime' : 'video/mp4');
    final path = 'community-stories/${user.id}/${DateTime.now().microsecondsSinceEpoch}.$ext';

    setState(() => _uploading = true);
    try {
      await _supabase.storage.from('ngn-downloads').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );
      try {
        await _supabase.from('community_stories').insert({
          'author_id': user.id,
          'media_path': path,
          'media_type': isImage ? 'image' : 'video',
          'caption': caption.isEmpty ? null : caption,
        });
      } catch (_) {
        await _supabase.storage.from('ngn-downloads').remove([path]);
        rethrow;
      }
      _message('Your story has been posted. It will expire after 24 hours.');
    } catch (error) {
      _message('Could not post your story: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, dynamic>?> _profile(String id) async {
    final row = await _supabase
        .from('profiles')
        .select('display_name,avatar_url')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  void _openStory(Map<String, dynamic> story) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommunityStoryViewerPage(story: story)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    return SizedBox(
      height: 104,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stories,
        builder: (context, snapshot) {
          final now = DateTime.now();
          final active = (snapshot.data ?? []).where((story) {
            final expiry = DateTime.tryParse(story['expires_at']?.toString() ?? '');
            return expiry != null && expiry.isAfter(now);
          }).toList();

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: [
              SizedBox(
                width: 76,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _uploading ? null : _addStory,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                            child: _uploading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.add_rounded, size: 30, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(_uploading ? 'Posting…' : 'Your story', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              ...active.map((story) {
                final authorId = story['author_id'].toString();
                return SizedBox(
                  width: 76,
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _profile(authorId),
                    builder: (context, profileSnapshot) {
                      final profile = profileSnapshot.data;
                      final name = profile?['display_name']?.toString() ?? 'Member';
                      final avatar = profile?['avatar_url']?.toString() ?? '';
                      final own = authorId == currentUserId;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openStory(story),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: own ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.primary,
                                  width: 2.3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty ? Text(name.isEmpty ? 'N' : name[0].toUpperCase()) : null,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(own ? 'Your story' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class CommunityStoryViewerPage extends StatefulWidget {
  const CommunityStoryViewerPage({super.key, required this.story});
  final Map<String, dynamic> story;

  @override
  State<CommunityStoryViewerPage> createState() => _CommunityStoryViewerPageState();
}

class _CommunityStoryViewerPageState extends State<CommunityStoryViewerPage> {
  final _supabase = Supabase.instance.client;
  String? _url;
  String? _error;
  bool _loading = true;
  bool _deleting = false;
  int _viewCount = 0;
  VideoPlayerController? _video;

  String get _storyId => widget.story['id'].toString();
  String get _path => widget.story['media_path'].toString();
  bool get _isOwner => _supabase.auth.currentUser?.id == widget.story['author_id']?.toString();
  bool get _isVideo => widget.story['media_type'] == 'video';

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sign in to view Community stories.');
      if (!_isOwner) {
        try {
          await _supabase.from('community_story_views').insert({
            'story_id': _storyId,
            'viewer_id': user.id,
          });
        } on PostgrestException catch (error) {
          if (error.code != '23505') rethrow;
        }
      } else {
        final views = await _supabase
            .from('community_story_views')
            .select('id')
            .eq('story_id', _storyId);
        _viewCount = views.length;
      }

      final signed = await _supabase.storage.from('ngn-downloads').createSignedUrl(_path, 3600);
      if (_isVideo) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(signed));
        await controller.initialize();
        await controller.setLooping(true);
        await controller.play();
        _video = controller;
      }
      if (!mounted) return;
      setState(() {
        _url = signed;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showViewers() async {
    try {
      final views = await _supabase
          .from('community_story_views')
          .select('viewer_id,viewed_at')
          .eq('story_id', _storyId)
          .order('viewed_at', ascending: false);
      final ids = views.map((row) => row['viewer_id'].toString()).toSet().toList();
      final profiles = ids.isEmpty
          ? <Map<String, dynamic>>[]
          : await _supabase.from('profiles').select('id,display_name,avatar_url').inFilter('id', ids);
      final byId = {for (final profile in profiles) profile['id'].toString(): profile};
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text('${ids.length} people viewed your story', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (ids.isEmpty) const Text('No views yet.'),
              ...views.map((view) {
                final profile = byId[view['viewer_id'].toString()];
                final avatar = profile?['avatar_url']?.toString() ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty ? const Icon(Icons.person_outline) : null,
                  ),
                  title: Text(profile?['display_name']?.toString() ?? 'N.G.N. Member'),
                );
              }),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load story viewers: $error')));
    }
  }

  Future<void> _deleteStory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this story?'),
        content: const Text('The story and its uploaded media will be removed for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await _supabase.storage.from('ngn-downloads').remove([_path]);
      await _supabase.from('community_stories').delete().eq('id', _storyId);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete story: $error')));
      }
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_isOwner ? 'Your story' : 'Community story'),
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: _deleting ? null : _showViewers,
              tooltip: 'Viewers',
              icon: const Icon(Icons.visibility_outlined),
            ),
          if (_isOwner)
            IconButton(
              onPressed: _deleting ? null : _deleteStory,
              tooltip: 'Delete story',
              icon: _deleting ? const CircularProgressIndicator() : const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_isVideo && _video != null)
                        Center(
                          child: AspectRatio(
                            aspectRatio: _video!.value.aspectRatio,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      else if (_url != null)
                        InteractiveViewer(child: Image.network(_url!, fit: BoxFit.contain)),
                      if ((widget.story['caption']?.toString() ?? '').isNotEmpty)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 24,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: Text(widget.story['caption'].toString(), style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ),
                          ),
                        ),
                      if (_isOwner)
                        Positioned(
                          right: 18,
                          bottom: 20,
                          child: SafeArea(
                            child: Text('$_viewCount views', style: const TextStyle(color: Colors.white70)),
                          ),
                        ),
                    ],
                  ),
      ),
      floatingActionButton: _isVideo && _video != null && !_loading
          ? FloatingActionButton.small(
              onPressed: () => setState(() {
                _video!.value.isPlaying ? _video!.pause() : _video!.play();
              }),
              child: Icon(_video!.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}
