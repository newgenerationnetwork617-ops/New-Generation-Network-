import 'package:flutter/material.dart';

/// Premium, reusable level-selection screen shared by the NGN games.
class GameLevelHub extends StatelessWidget {
  const GameLevelHub({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.currentLevel,
    required this.totalLevels,
    required this.onSelectLevel,
    this.accent = const Color(0xFFFFC94A),
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int currentLevel;
  final int totalLevels;
  final ValueChanged<int> onSelectLevel;
  final Color accent;

  static const _background = Color(0xFF081629);
  static const _surface = Color(0xFF151F30);
  static const _muted = Color(0xFF9AA8BA);

  @override
  Widget build(BuildContext context) {
    // Guard the level selector against invalid configuration so a zero-level
    // game cannot crash while building the progress screen.
    final safeTotalLevels = totalLevels < 1 ? 1 : totalLevels;
    final safeCurrent = currentLevel.clamp(1, safeTotalLevels);
    final progress = totalLevels < 1 ? 0.0 : (safeCurrent - 1) / safeTotalLevels;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B2B43), Color(0xFF111B2B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: .08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: accent, size: 25),
                        ),
                        const Spacer(),
                        Text('$safeCurrent / $safeTotalLevels',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 20),
                      Text('YOUR PROGRESS',
                        style: TextStyle(color: accent, fontSize: 10,
                          letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      Text(subtitle,
                        style: const TextStyle(color: Colors.white, fontSize: 21,
                          height: 1.25, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: _background,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                          ),
                          onPressed: () => onSelectLevel(safeCurrent),
                          child: Text('CONTINUE  ·  LEVEL $safeCurrent',
                            style: const TextStyle(fontWeight: FontWeight.w900,
                              letterSpacing: .5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  Text('ALL LEVELS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                      letterSpacing: 1.1, fontSize: 12)),
                  Spacer(),
                  Text('Complete levels to unlock the next',
                    style: TextStyle(color: _muted, fontSize: 10)),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final level = index + 1;
                    final unlocked = level <= safeCurrent;
                    final completed = level < safeCurrent;
                    return Material(
                      color: completed
                          ? const Color(0xFF1D3B39)
                          : unlocked ? _surface : const Color(0xFF101825),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: unlocked ? () => onSelectLevel(level) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: completed ? const Color(0xFF3C9B7B)
                                : unlocked ? accent.withValues(alpha: .55)
                                : Colors.white.withValues(alpha: .06)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (completed)
                                const Icon(Icons.check_rounded,
                                  color: Color(0xFF70C7A7), size: 16)
                              else if (!unlocked)
                                const Icon(Icons.lock_outline_rounded,
                                  color: _muted, size: 14)
                              else
                                Icon(Icons.play_arrow_rounded, color: accent, size: 16),
                              const SizedBox(height: 3),
                              Text('$level',
                                style: TextStyle(
                                  color: unlocked ? Colors.white : _muted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: safeTotalLevels,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
