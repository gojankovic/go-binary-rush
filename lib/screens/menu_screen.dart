import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addition_screen.dart';
import 'daily_challenge_screen.dart';
import 'game_screen.dart';
import 'hex_screen.dart';
import 'hex_word_screen.dart';
import 'how_to_play_screen.dart';
import 'learn_screen.dart';
import 'reverse_screen.dart';
import 'speed_burst_screen.dart';
import 'xor_screen.dart';
import '../theme.dart';
import '../services/prefs_keys.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, int> _bestScores = {};
  int _tier = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bestScores = {
        'match':   prefs.getInt(PrefsKeys.highScore(GameModes.match)) ?? 0,
        'reverse': prefs.getInt(PrefsKeys.highScore(GameModes.reverse)) ?? 0,
        'addition':prefs.getInt(PrefsKeys.highScore(GameModes.addition)) ?? 0,
        'xor':     prefs.getInt(PrefsKeys.highScore(GameModes.xor)) ?? 0,
        'speed':   bestSpeedBurstScore(prefs),
        'hex':      prefs.getInt(PrefsKeys.highScore(GameModes.hex)) ?? 0,
        'hex_word': prefs.getInt(PrefsKeys.highScore(GameModes.hexWord)) ?? 0,
      };
      _tier = (prefs.getInt(PrefsKeys.currentTier(GameModes.match)) ?? 0) + 1;
    });
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('GO BINARY RUSH', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _welcomeBanner(),
          const SizedBox(height: 28),
          Text('SELECT MODE', style: AppText.kicker()),
          const SizedBox(height: 20),
          _ModeItem(
            index: 1, name: 'MATCH', sub: 'decimal  →  binary',
            best: _bestScores['match'],
            onTap: () => _push(const GameScreen()),
          ),
          _ModeItem(
            index: 2, name: 'REVERSE', sub: 'binary   →  decimal',
            best: _bestScores['reverse'],
            onTap: () => _push(const ReverseScreen()),
          ),
          _ModeItem(
            index: 3, name: 'ADDITION', sub: 'A + B = target',
            best: _bestScores['addition'],
            onTap: () => _push(const AdditionScreen()),
          ),
          _ModeItem(
            index: 4, name: 'XOR', sub: 'A ⊕ B = C',
            best: _bestScores['xor'],
            onTap: () => _push(const XorScreen()),
          ),
          _ModeItem(
            index: 5, name: 'SPEED BURST', sub: '60 second blitz',
            best: _bestScores['speed'],
            bestLabel: 'BEST ANY',
            onTap: () => _push(const SpeedBurstScreen()),
          ),
          _ModeItem(
            index: 6, name: 'HEX MATCH', sub: 'binary  →  hex',
            best: _bestScores['hex'],
            onTap: () => _push(const HexScreen()),
          ),
          _ModeItem(
            index: 7, name: 'HEX WORD', sub: 'ascii hex → type the word',
            best: _bestScores['hex_word'],
            onTap: () => _push(const HexWordScreen()),
          ),
          _ModeItem(
            index: 8, name: 'DAILY', sub: '10 questions · daily reset',
            best: null,
            onTap: () => _push(const DailyChallengeScreen()),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.g1),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HowToPlayScreen())),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('[?]',
                      style: AppText.mono(size: 13, color: AppColors.g2)),
                  const SizedBox(width: 14),
                  Text('HOW TO PLAY',
                      style: AppText.mono(size: 13, color: AppColors.g2)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LearnScreen())),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('[i]',
                      style: AppText.mono(size: 13, color: AppColors.g2)),
                  const SizedBox(width: 14),
                  Text('BINARY INTRODUCTION',
                      style: AppText.mono(size: 13, color: AppColors.g2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _welcomeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.g3, width: 2),
          top: BorderSide(color: AppColors.g1),
          right: BorderSide(color: AppColors.g1),
          bottom: BorderSide(color: AppColors.g1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Yields to the tier badge rather than overflowing when the text is
          // wider than assumed (large system text scale).
          Flexible(
            child: Text('WELCOME BACK',
                overflow: TextOverflow.ellipsis,
                style: AppText.kicker(color: AppColors.g2)
                    .copyWith(letterSpacing: 3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.g2),
            ),
            child: Text('TIER · T$_tier',
                style: AppText.mono(size: 10, color: AppColors.g3)),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final int index;
  final String name;
  final String sub;
  final int? best;
  final String bestLabel;
  final VoidCallback onTap;

  const _ModeItem({
    required this.index,
    required this.name,
    required this.sub,
    required this.best,
    required this.onTap,
    this.bestLabel = 'BEST',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('[$index]',
                style: AppText.mono(size: 13, color: AppColors.g3)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.label()),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.mono(size: 10, color: AppColors.g2)),
                ],
              ),
            ),
            if (best != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('★ $best',
                      style: AppText.mono(
                          size: 12,
                          color: best! > 0 ? AppColors.g3 : AppColors.g1)),
                  Text(bestLabel,
                      style: AppText.kicker(
                          color: best! > 0 ? AppColors.g2 : AppColors.g1)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
