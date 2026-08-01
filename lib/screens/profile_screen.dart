import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _playerName = 'PLAYER';
  int _totalCorrect = 0;
  int _bestStreak = 0;
  int _tier = 1;
  int _dailyStreak = 0;
  Map<String, int> _bests = {};
  Map<String, int> _speedBests = {};
  Map<String, int> _counts = {};
  Map<String, int> _speedCounts = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _playerName   = (prefs.getString('player_name') ?? 'PLAYER').toUpperCase();
      _totalCorrect = prefs.getInt('total_correct') ?? 0;
      _bestStreak   = prefs.getInt('best_streak_ever') ?? 0;
      _tier         = (prefs.getInt('match_current_tier') ?? 0) + 1;
      _dailyStreak  = prefs.getInt('daily_streak') ?? 0;
      _bests = {
        'MATCH':    prefs.getInt('match_high_score') ?? 0,
        'REVERSE':  prefs.getInt('reverse_high_score') ?? 0,
        'ADDITION': prefs.getInt('addition_high_score') ?? 0,
        'XOR':      prefs.getInt('xor_high_score') ?? 0,
        'HEX MATCH':prefs.getInt('hex_high_score') ?? 0,
        'HEX WORD': prefs.getInt('hex_word_high_score') ?? 0,
      };
      _counts = {
        'MATCH':    prefs.getInt('match_correct_count') ?? 0,
        'REVERSE':  prefs.getInt('reverse_correct_count') ?? 0,
        'ADDITION': prefs.getInt('addition_correct_count') ?? 0,
        'XOR':      prefs.getInt('xor_correct_count') ?? 0,
        'HEX MATCH':prefs.getInt('hex_correct_count') ?? 0,
        'HEX WORD': prefs.getInt('hex_word_correct_count') ?? 0,
      };
      _speedBests = {
        'MATCH':    prefs.getInt('speed_match_high_score') ?? 0,
        'REVERSE':  prefs.getInt('speed_reverse_high_score') ?? 0,
        'ADDITION': prefs.getInt('speed_addition_high_score') ?? 0,
        'XOR':      prefs.getInt('speed_xor_high_score') ?? 0,
        'HEX WORD': prefs.getInt('speed_hexWord_high_score') ?? 0,
      };
      _speedCounts = {
        'MATCH':    prefs.getInt('speed_match_correct_count') ?? 0,
        'REVERSE':  prefs.getInt('speed_reverse_correct_count') ?? 0,
        'ADDITION': prefs.getInt('speed_addition_correct_count') ?? 0,
        'XOR':      prefs.getInt('speed_xor_correct_count') ?? 0,
        'HEX WORD': prefs.getInt('speed_hexWord_correct_count') ?? 0,
      };
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('STATS', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _agentHeader(),
                const SizedBox(height: 24),
                Container(height: 1, color: AppColors.g1),
                const SizedBox(height: 24),
                _coreStats(),
                const SizedBox(height: 28),
                _divider('TIER PROGRESS  ·  MATCH'),
                const SizedBox(height: 14),
                _tierRow(),
                const SizedBox(height: 28),
                _divider('DAILY'),
                const SizedBox(height: 14),
                _statRow('DAILY STREAK', _dailyStreak > 0 ? '×$_dailyStreak' : '—'),
                const SizedBox(height: 28),
                _divider('BEST SCORES'),
                const SizedBox(height: 14),
                ..._bests.entries.map((e) => _statRow(
                      e.key,
                      e.value > 0 ? '${e.value}' : '—',
                      subtitle: _countSubtitle(_counts[e.key] ?? 0),
                    )),
                const SizedBox(height: 28),
                _divider('SPEED BURST'),
                const SizedBox(height: 14),
                ..._speedBests.entries.map((e) => _statRow(
                      e.key,
                      e.value > 0 ? '${e.value}' : '—',
                      subtitle: _countSubtitle(_speedCounts[e.key] ?? 0),
                    )),
              ],
            ),
    );
  }

  Widget _agentHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('AGENT', style: AppText.kicker(color: AppColors.g2)),
        const SizedBox(width: 14),
        Text(_playerName,
            style: AppText.mono(
                size: 22, color: AppColors.g4, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _coreStats() {
    return Row(
      children: [
        Expanded(child: _bigStat('TOTAL CORRECT', '$_totalCorrect')),
        Container(width: 1, height: 56, color: AppColors.g1),
        Expanded(child: _bigStat('BEST STREAK', '×$_bestStreak')),
      ],
    );
  }

  Widget _bigStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppText.kicker()),
        const SizedBox(height: 6),
        Text(value, style: AppText.hudValue(color: AppColors.g4).copyWith(fontSize: 28)),
      ],
    );
  }

  Widget _tierRow() {
    const totalTiers = 6;
    final progress = (_tier - 1) / (totalTiers - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('T$_tier', style: AppText.mono(size: 13, color: AppColors.g4)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(border: Border.all(color: AppColors.g1)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.g3,
                        boxShadow: AppGlow.sm,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('T$totalTiers', style: AppText.mono(size: 13, color: AppColors.g2)),
          ],
        ),
        if (_tier < totalTiers) ...[
          const SizedBox(height: 6),
          Text('TIER $_tier OF $totalTiers',
              style: AppText.kicker(color: AppColors.g1).copyWith(letterSpacing: 2)),
        ] else ...[
          const SizedBox(height: 6),
          Text('MAX TIER REACHED',
              style: AppText.kicker(color: AppColors.g4).copyWith(letterSpacing: 2)),
        ],
      ],
    );
  }

  Widget _divider(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.kicker()),
        const SizedBox(height: 6),
        Container(height: 1, color: AppColors.g1),
      ],
    );
  }

  String? _countSubtitle(int count) {
    if (count <= 0) return null;
    return '$count SOLVED';
  }

  Widget _statRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppText.mono(size: 12, color: AppColors.g2)),
              Text(value,
                  style: AppText.mono(
                      size: 13,
                      color: value == '—' ? AppColors.g1 : AppColors.g3,
                      weight: FontWeight.w600)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppText.kicker(color: AppColors.g1)
                    .copyWith(letterSpacing: 2)),
          ],
        ],
      ),
    );
  }
}
