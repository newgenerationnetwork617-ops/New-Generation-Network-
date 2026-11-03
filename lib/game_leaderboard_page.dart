import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameLeaderboardPage extends StatefulWidget {
  const GameLeaderboardPage({super.key, required this.gameId, required this.gameTitle});
  final String gameId;
  final String gameTitle;

  @override
  State<GameLeaderboardPage> createState() => _GameLeaderboardPageState();
}

class _GameLeaderboardPageState extends State<GameLeaderboardPage> {
  static const _blue = Color(0xFF0B5ED7);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return [];
    final rows = await client
        .from('game_leaderboard')
        .select('user_id, display_name, best_score, player_rank')
        .eq('game_id', widget.gameId)
        .order('best_score', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.gameTitle} Leaderboard')),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sign in with your Community account to view the global leaderboard and submit your scores. You can still play this game offline without signing in.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(children: [
                      const SizedBox(height: 100),
                      const Center(child: Text('Leaderboard could not be loaded. Check your connection and try again.')),
                      Center(child: TextButton(onPressed: _refresh, child: const Text('Retry'))),
                    ]);
                  }
                  final rows = snapshot.data ?? [];
                  final mine = rows.where((r) => r['user_id'] == user.id).toList();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: _blue,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(children: [
                            const Icon(Icons.emoji_events_rounded, color: Color(0xFFD4AF37), size: 38),
                            const SizedBox(height: 8),
                            const Text('YOUR GLOBAL POSITION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(
                              mine.isEmpty ? 'Not ranked yet' : '#${mine.first['player_rank']}',
                              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              mine.isEmpty ? 'Complete a round and submit a score.' : 'Best score: ${mine.first['best_score']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('TOP PLAYERS', style: TextStyle(color: _blue, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No scores have been posted yet. Be among the first!', textAlign: TextAlign.center),
                        ),
                      ...rows.asMap().entries.map((entry) {
                        final row = entry.value;
                        final isMe = row['user_id'] == user.id;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isMe ? _blue : Colors.black12,
                              child: Text('${row['player_rank']}', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w900)),
                            ),
                            title: Text(row['display_name']?.toString().trim().isNotEmpty == true ? row['display_name'].toString() : 'NGN Player'),
                            subtitle: isMe ? const Text('Your account') : null,
                            trailing: Text('${row['best_score']} pts', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
