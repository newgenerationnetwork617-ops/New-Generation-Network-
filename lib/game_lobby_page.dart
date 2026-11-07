import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'game_leaderboard_page.dart';
import 'game_level_hub.dart';

/// A proper landing screen for each NGN game. Gameplay never opens directly
/// from the games catalogue; players first see their profile, progress and rank.
class GameLobbyPage extends StatefulWidget {
  const GameLobbyPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gameId,
    required this.icon,
    required this.gamePage,
    required this.bestKey,
    this.levelKey,
    this.totalLevels,
  });

  final String title;
  final String subtitle;
  final String gameId;
  final IconData icon;
  final Widget gamePage;
  final String bestKey;
  final String? levelKey;
  final int? totalLevels;

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  static const _navy = Color(0xFF081629);
  static const _gold = Color(0xFFFFC94A);
  static const _blue = Color(0xFF1746A2);

  int _best = 0;
  int _currentLevel = 1;
  String _rank = 'UNRANKED';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    // Local progress is the source of truth for starting a game. Never make
    // gameplay wait for Supabase: the leaderboard is an optional online extra.
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (!mounted) return;

    setState(() {
      _best = prefs.getInt(widget.bestKey) ?? 0;
      _currentLevel = widget.levelKey == null
          ? 1
          : ((prefs.getInt(widget.levelKey!) ?? 0) + 1)
              .clamp(1, widget.totalLevels ?? 1);
      _rank = user == null ? 'GUEST' : 'OFFLINE';
      _loading = false;
    });

    if (user == null) return;

    // Fetch rank only after the lobby is already usable. A slow or missing
    // connection must never leave the player staring at a loading spinner.
    try {
      final row = await Supabase.instance.client
          .from('game_leaderboard')
          .select('player_rank')
          .eq('game_id', widget.gameId)
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
      final value = row?['player_rank'];
      if (mounted) {
        setState(() => _rank = value == null ? 'UNRANKED' : '#$value');
      }
    } catch (_) {
      if (mounted) setState(() => _rank = 'OFFLINE');
    }
  }

  String _playerName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Guest Player';
    final metadata = user.userMetadata ?? {};
    final name = metadata['display_name'] ??
        metadata['full_name'] ??
        metadata['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return user.email?.split('@').first ?? 'NGN Player';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'G';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _openGame({int? level}) async {
    if (level != null && widget.levelKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(widget.levelKey!, level - 1);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget.gamePage),
    );
    _loadProgress();
  }

  void _openLevels() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameLevelHub(
          title: widget.title,
          subtitle: 'Choose a level and keep growing',
          icon: widget.icon,
          currentLevel: _currentLevel,
          totalLevels: widget.totalLevels!,
          onSelectLevel: (level) {
            Navigator.pop(context);
            _openGame(level: level);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = _playerName();
    final avatar = user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture'];
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF081629) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: dark ? _navy : Colors.white,
        foregroundColor: dark ? Colors.white : const Color(0xFF172033),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameLeaderboardPage(
                  gameId: widget.gameId,
                  gameTitle: widget.title,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF172B49), Color(0xFF081629)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _gold.withValues(alpha: .35)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: _gold.withValues(alpha: .18),
                          backgroundImage: avatar is String && avatar.isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                          child: avatar is String && avatar.isNotEmpty
                              ? null
                              : Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    color: _gold,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PLAYER PROFILE',
                                style: TextStyle(
                                  color: _gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user == null
                                    ? 'Guest • Scores saved on this device'
                                    : 'Community player • Global scores enabled',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _gold.withValues(alpha: .4)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.military_tech_rounded,
                                  color: _gold, size: 19),
                              const SizedBox(height: 2),
                              Text(
                                _rank,
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: dark ? Colors.white70 : const Color(0xFF667085),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'BEST SCORE',
                          value: '$_best',
                          icon: Icons.stars_rounded,
                          dark: dark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: widget.totalLevels == null
                              ? 'ROUND MODE'
                              : 'CURRENT LEVEL',
                          value: widget.totalLevels == null
                              ? 'Ready'
                              : '$_currentLevel / ${widget.totalLevels}',
                          icon: Icons.flag_rounded,
                          dark: dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF151F30) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: .08)
                            : const Color(0xFFE4E8EF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _blue.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(widget.icon, color: _blue, size: 23),
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Text(
                                'READY WHEN YOU ARE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .6,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF2E9D75), size: 20),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.totalLevels == null
                              ? 'Start a fresh round. Questions and clues are shuffled when you begin again.'
                              : 'Your progress is saved. Choose an unlocked level, or continue from your current level.',
                          style: TextStyle(
                            color: dark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _navy,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            onPressed: widget.totalLevels == null
                                ? () => _openGame()
                                : _openLevels,
                            icon: Icon(widget.totalLevels == null
                                ? Icons.play_arrow_rounded
                                : Icons.grid_view_rounded),
                            label: Text(
                              widget.totalLevels == null
                                  ? 'START A NEW ROUND'
                                  : 'VIEW LEVELS & PLAY',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameLeaderboardPage(
                          gameId: widget.gameId,
                          gameTitle: widget.title,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('VIEW LEADERBOARD & RANKS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (user == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'You can play as a guest. Global rankings require a connected player account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark ? Colors.white54 : Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.dark,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF151F30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? Colors.white12 : const Color(0xFFE4E8EF),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFC94A), size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                        color: dark ? Colors.white54 : Colors.black45,
                      )),
                  const SizedBox(height: 4),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );
}
