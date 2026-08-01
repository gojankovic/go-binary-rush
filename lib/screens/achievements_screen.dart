import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class _Achievement {
  final String glyph;
  final String name;
  final String sub;
  final int goal;
  final int progress;

  const _Achievement({
    required this.glyph,
    required this.name,
    required this.sub,
    required this.goal,
    required this.progress,
  });

  bool get unlocked => progress >= goal;
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _playerName = 'PLAYER';
  List<_Achievement> _achievements = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final playerName     = (prefs.getString('player_name') ?? 'PLAYER').toUpperCase();
    final totalCorrect   = prefs.getInt('total_correct') ?? 0;
    final bestStreak     = prefs.getInt('best_streak_ever') ?? 0;
    final matchTier      = (prefs.getInt('match_current_tier') ?? 0) + 1;
    final speedBest      = prefs.getInt('speed_match_high_score') ?? 0;
    final dailyStreak    = prefs.getInt('daily_streak') ?? 0;
    final hwTotal        = prefs.getInt('hex_word_total') ?? 0;
    final hwPerfect      = prefs.getInt('hex_word_perfect_count') ?? 0;
    final hwSpeedBest    = prefs.getInt('speed_hexWord_high_score') ?? 0;

    if (!mounted) return;
    setState(() {
      _playerName = playerName;
      _achievements = [
        _Achievement(
          glyph: '◉', name: 'FIRST BIT',
          sub: 'get your first correct answer',
          goal: 1, progress: totalCorrect,
        ),
        _Achievement(
          glyph: '✦', name: '50 CORRECT',
          sub: '50 total correct answers',
          goal: 50, progress: totalCorrect,
        ),
        _Achievement(
          glyph: '✦', name: '200 CORRECT',
          sub: '200 total correct answers',
          goal: 200, progress: totalCorrect,
        ),
        _Achievement(
          glyph: '✦', name: 'VETERAN',
          sub: '1000 total correct answers',
          goal: 1000, progress: totalCorrect,
        ),
        _Achievement(
          glyph: '∞', name: 'STREAK ×5',
          sub: '5 in a row, any mode',
          goal: 5, progress: bestStreak,
        ),
        _Achievement(
          glyph: '∞', name: 'STREAK ×10',
          sub: '10 in a row, any mode',
          goal: 10, progress: bestStreak,
        ),
        _Achievement(
          glyph: '◆', name: 'TIER CLIMBER',
          sub: 'reach Tier 3 in MATCH',
          goal: 3, progress: matchTier,
        ),
        _Achievement(
          glyph: '⚡', name: 'SPEED DEMON',
          sub: 'score 100+ in Speed Burst',
          goal: 100, progress: speedBest,
        ),
        _Achievement(
          glyph: '◈', name: 'DAILY ×3',
          sub: '3 consecutive daily challenges',
          goal: 3, progress: dailyStreak,
        ),
        _Achievement(
          glyph: '◈', name: 'DAILY ×7',
          sub: 'complete daily 7 days in a row',
          goal: 7, progress: dailyStreak,
        ),
        _Achievement(
          glyph: '◈', name: 'DAILY ×30',
          sub: '30-day daily challenge streak',
          goal: 30, progress: dailyStreak,
        ),
        _Achievement(
          glyph: '⌨', name: 'FIRST WORD',
          sub: 'solve your first HEX WORD',
          goal: 1, progress: hwTotal,
        ),
        _Achievement(
          glyph: '⌨', name: 'WORDSMITH',
          sub: 'solve 10 HEX WORD puzzles',
          goal: 10, progress: hwTotal,
        ),
        _Achievement(
          glyph: '⌨', name: 'LEXICON',
          sub: 'solve 50 HEX WORD puzzles',
          goal: 50, progress: hwTotal,
        ),
        _Achievement(
          glyph: '⌨', name: 'CLEAN READ',
          sub: 'solve a word with no wrong letters',
          goal: 1, progress: hwPerfect,
        ),
        _Achievement(
          glyph: '⚡', name: 'HEX SPEED',
          sub: 'solve 10+ words in Speed Burst HEX WORD',
          goal: 10, progress: hwSpeedBest,
        ),
      ];
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _achievements.where((a) => a.unlocked).length;
    final total = _achievements.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('ACHIEVEMENTS', style: AppText.label()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$unlocked/$total',
                  style: AppText.mono(size: 12, color: AppColors.g2)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('AGENT', style: AppText.kicker(color: AppColors.g2)),
                    const SizedBox(width: 14),
                    Text(_playerName,
                        style: AppText.mono(
                            size: 18,
                            color: AppColors.g4,
                            weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                _progressBar(unlocked, total),
                const SizedBox(height: 24),
                ..._achievements.map(_achItem),
              ],
            ),
    );
  }

  Widget _progressBar(int unlocked, int total) {
    final pct = total == 0 ? 0.0 : unlocked / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$unlocked', style: AppText.hudValue(color: AppColors.g4)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(border: Border.all(color: AppColors.g1)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: Container(
                        decoration: BoxDecoration(
                            color: AppColors.g3, boxShadow: AppGlow.sm)),
                  ),
                ),
              ),
            ),
            Text('$total', style: AppText.mono(size: 13, color: AppColors.g2)),
          ],
        ),
      ],
    );
  }

  Widget _achItem(_Achievement a) {
    final color = a.unlocked ? AppColors.g4 : AppColors.g2;
    final subColor = a.unlocked ? AppColors.g2 : AppColors.g1;
    final progressText = a.unlocked
        ? '✓'
        : '${a.progress.clamp(0, a.goal)}/${a.goal}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
            color: a.unlocked ? AppColors.g2 : AppColors.g1),
        boxShadow: a.unlocked ? AppGlow.sm : null,
      ),
      child: Row(
        children: [
          Text(a.glyph,
              style: TextStyle(
                  fontSize: 20,
                  color: color,
                  shadows: a.unlocked
                      ? AppGlow.sm.map((s) =>
                              Shadow(color: s.color, blurRadius: s.blurRadius))
                          .toList()
                      : null)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: AppText.mono(size: 13, color: color, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(a.sub, style: AppText.mono(size: 10, color: subColor)),
              ],
            ),
          ),
          Text(progressText,
              style: AppText.mono(
                  size: 12,
                  color: a.unlocked ? AppColors.g4 : AppColors.g1,
                  weight: a.unlocked ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}
