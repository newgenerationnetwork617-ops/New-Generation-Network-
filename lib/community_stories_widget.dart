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
  int _commentCount = 0;
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

      final comments = await _supabase
          .from('community_story_comments')
          .select('id')
          .eq('story_id', _storyId);
      _commentCount = comments.length;

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

  Future<List<Map<String, dynamic>>> _fetchComments() async {
    final rows = await _supabase
        .from('community_story_comments')
        .select('id,author_id,body,created_at')
        .eq('story_id', _storyId)
        .order('created_at', ascending: true);
    final comments = List<Map<String, dynamic>>.from(rows);
    final ids = comments.map((row) => row['author_id'].toString()).toSet().toList();
    final profiles = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _supabase.from('profiles').select('id,display_name,avatar_url').inFilter('id', ids);
    final byId = {for (final profile in profiles) profile['id'].toString(): profile};
    return comments.map((comment) {
      final profile = byId[comment['author_id'].toString()];
      return {
        ...comment,
        'display_name': profile?['display_name']?.toString() ?? 'N.G.N. Member',
        'avatar_url': profile?['avatar_url']?.toString() ?? '',
      };
    }).toList();
  }

  Future<void> _showComments() async {
    final controller = TextEditingController();
    Future<List<Map<String, dynamic>>> commentsFuture = _fetchComments();
    bool sending = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * .72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Story comments', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'Replies are visible to everyone who can view this story. They are not private chats.',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: commentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Could not load comments: ${snapshot.error}'));
                        }
                        final comments = snapshot.data ?? [];
                        if (comments.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No comments yet. Be the first to respond.'),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final avatar = comment['avatar_url']?.toString() ?? '';
                            final canDelete = comment['author_id']?.toString() == _supabase.auth.currentUser?.id || _isOwner;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty ? const Icon(Icons.person_outline) : null,
                              ),
                              title: Text(comment['display_name']?.toString() ?? 'N.G.N. Member', style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(comment['body']?.toString() ?? ''),
                              ),
                              trailing: canDelete
                                  ? PopupMenuButton<String>(
                                      tooltip: 'Comment options',
                                      onSelected: (value) async {
                                        if (value != 'delete') return;
                                        try {
                                          await _supabase.from('community_story_comments').delete().eq('id', comment['id']);
                                          final refreshed = _fetchComments();
                                          if (sheetContext.mounted) setSheetState(() => commentsFuture = refreshed);
                                          final updated = await refreshed;
                                          if (mounted) setState(() => _commentCount = updated.length);
                                        } catch (error) {
                                          if (sheetContext.mounted) {
                                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                                              SnackBar(content: Text('Could not remove comment: $error')),
                                            );
                                          }
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'delete', child: Text('Remove comment')),
                                      ],
                                    )
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (!_isOwner) ...[
                    const Divider(height: 1),
                    Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLength: 280,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Write a short response…',
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Post comment',
                          onPressed: sending ? null : () async {
                            final body = controller.text.trim();
                            final user = _supabase.auth.currentUser;
                            if (body.isEmpty || user == null) return;
                            setSheetState(() => sending = true);
                            try {
                              await _supabase.from('community_story_comments').insert({
                                'story_id': _storyId,
                                'author_id': user.id,
                                'body': body,
                              });
                              controller.clear();
                              final refreshed = _fetchComments();
                              if (sheetContext.mounted) setSheetState(() => commentsFuture = refreshed);
                              final updated = await refreshed;
                              if (mounted) setState(() => _commentCount = updated.length);
                            } catch (error) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('Could not post comment: $error')),
                                );
                              }
                            } finally {
                              if (sheetContext.mounted) setSheetState(() => sending = false);
                            }
                          },
                          icon: sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
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
    final caption = widget.story['caption']?.toString() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF081321),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isOwner ? 'Your story' : 'Community story',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Text('New Generation Network',
                style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: _deleting ? null : _deleteStory,
              tooltip: 'Delete story',
              icon: _deleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 42),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _loadStory();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF14283E), Color(0xFF081321), Color(0xFF050B13)],
                        ),
                      ),
                    ),
                    Center(
                      child: _isVideo && _video != null
                          ? AspectRatio(
                              aspectRatio: _video!.value.aspectRatio,
                              child: VideoPlayer(_video!),
                            )
                          : _url != null
                              ? InteractiveViewer(
                                  minScale: .8,
                                  maxScale: 4,
                                  child: Image.network(
                                    _url!,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) => progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                          ),
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white70,
                                      size: 48,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                    if (caption.isNotEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 92,
                        child: SafeArea(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xE6101D2C),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: .16)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 6)),
                              ],
                            ),
                            child: Text(
                              caption,
                              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isOwner) ...[
                              OutlinedButton.icon(
                                onPressed: _showViewers,
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                label: Text('$_viewCount views'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xCC10243A),
                                  side: BorderSide(color: Colors.white.withValues(alpha: .28)),
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            OutlinedButton.icon(
                              onPressed: _showComments,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              label: Text(_isOwner ? 'Comments ($_commentCount)' : 'Leave a comment ($_commentCount)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xCC10243A),
                                side: BorderSide(color: Colors.white.withValues(alpha: .28)),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _isVideo && _video != null && !_loading && _error == null
          ? FloatingActionButton.small(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF10243A),
              onPressed: () => setState(() {
                _video!.value.isPlaying ? _video!.pause() : _video!.play();
              }),
              child: Icon(_video!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            )
          : null,
    );
  }
}
