import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/score_engine.dart';
import '../services/prefs_keys.dart';
import '../services/haptics.dart';
import '../game/word_list.dart';
import '../widgets/game_pips.dart';
import '../widgets/hex_word_keyboard.dart';
import '../widgets/new_best_banner.dart';
import '../theme.dart';

class HexWordScreen extends StatefulWidget {
  const HexWordScreen({super.key});

  @override
  State<HexWordScreen> createState() => _HexWordScreenState();
}

class _HexWordScreenState extends State<HexWordScreen>
    with SingleTickerProviderStateMixin {
  ScoreEngine? _score;
  SharedPreferences? _prefs;

  static const int _minWordLen = 3;
  static const int _maxWordLen = 8;
  static const int _wordsPerStep = 10;

  List<String> _pool = [];
  int _poolIdx = 0;
  int _currentMaxLen = 0;
  String _word = '';
  List<String> _cachedHexPairs = [];
  int _revealed = 0;
  bool _solved = false;
  bool _wrongThisWord = false;

  int _lapSolved = 0;
  int _lastEarned = 0;
  bool _wrongFlash = false;
  Timer? _advanceTimer;
  Timer? _wrongTimer;
  bool _newBestFlash = false;
  Timer? _newBestTimer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _init();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _wrongTimer?.cancel();
    _newBestTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final results = await Future.wait([
      ScoreEngine.create(mode: 'hex_word'),
      SharedPreferences.getInstance(),
    ]);
    final score = results[0] as ScoreEngine;
    final prefs = results[1] as SharedPreferences;
    if (!mounted) return;
    setState(() {
      _score = score;
      _prefs = prefs;
    });
    _loadWord();
  }

  void _refreshPoolForCurrentRamp() {
    final p = _prefs;
    if (p == null) return;
    final total = p.getInt(PrefsKeys.hexWordTotal) ?? 0;
    final ramp = ((total ~/ _wordsPerStep) + _minWordLen)
        .clamp(_minWordLen, _maxWordLen);
    if (ramp == _currentMaxLen && _pool.isNotEmpty) return;
    _currentMaxLen = ramp;
    _pool = kWordList
        .where((w) => w.length >= _minWordLen && w.length <= ramp)
        .toList()
      ..shuffle(Random());
    _poolIdx = 0;
    p.setInt(PrefsKeys.hexWordMaxLen, ramp);
  }

  void _loadWord() {
    _refreshPoolForCurrentRamp();
    if (_pool.isEmpty) return;
    final word = _pool[_poolIdx % _pool.length];
    setState(() {
      _word = word;
      _cachedHexPairs = word.codeUnits
          .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
          .toList();
      _revealed = 0;
      _solved = false;
      _wrongFlash = false;
      _wrongThisWord = false;
    });
  }

  void _tapLetter(String letter) {
    if (_solved || _score == null || _word.isEmpty) return;
    final expected = _word[_revealed].toUpperCase();
    if (letter == expected) {
      Haptics.selectionClick();
      setState(() => _revealed++);
      if (_revealed == _word.length) _triggerSolved();
    } else {
      _score!.onWrongLetter();
      _score!.onWrong();
      Haptics.lightImpact();
      _wrongTimer?.cancel();
      setState(() {
        _wrongFlash = true;
        _wrongThisWord = true;
      });
      _wrongTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _wrongFlash = false);
      });
    }
  }

  void _triggerSolved() {
    final earned = _score!.onCorrect();
    final newBest = _score!.consumeNewBestFlash();
    Haptics.mediumImpact();
    _pulseCtrl.forward(from: 0);
    setState(() {
      _solved = true;
      _lastEarned = earned;
      if (newBest) _newBestFlash = true;
    });
    if (newBest) {
      _newBestTimer?.cancel();
      _newBestTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _newBestFlash = false);
      });
    }
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 700), _next);
    _saveProgress();
  }

  void _saveProgress() {
    final p = _prefs;
    if (p == null) return;
    final total = (p.getInt(PrefsKeys.hexWordTotal) ?? 0) + 1;
    p.setInt(PrefsKeys.hexWordTotal, total);
    if (!_wrongThisWord) {
      final perfect = (p.getInt(PrefsKeys.hexWordPerfectCount) ?? 0) + 1;
      p.setInt(PrefsKeys.hexWordPerfectCount, perfect);
    }
  }

  void _next() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    final nextIdx = _poolIdx + 1;
    if (nextIdx >= _pool.length) _pool.shuffle(Random());
    setState(() {
      _lapSolved = (_lapSolved + 1) % GamePips.lapSize;
      _poolIdx = nextIdx % _pool.length;
    });
    _loadWord();
  }

  @override
  Widget build(BuildContext context) {
    if (_score == null) {
      return const Scaffold(
          backgroundColor: Colors.black, body: SizedBox.shrink());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.g2),
        title: Text('HEX WORD', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: Stack(children: [
        Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _hud(),
          ),
          Container(height: 1, color: AppColors.g1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GamePips(lapSolved: _lapSolved, solved: _solved),
          ),
          Container(height: 1, color: AppColors.g1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ASCII  HEX', style: AppText.kicker()),
                  const SizedBox(height: 14),
                  _hexDisplay(),
                  const SizedBox(height: 22),
                  _letterBoxes(),
                  const SizedBox(height: 14),
                  SizedBox(height: 18, child: _solved ? _feedback() : null),
                ],
              ),
            ),
          ),
          Container(height: 1, color: AppColors.g1),
          const SizedBox(height: 10),
          HexWordKeyboard(onTap: _tapLetter, disabled: _solved),
          const SizedBox(height: 10),
          _nextButton(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
        ),
        NewBestBanner(visible: _newBestFlash),
      ]),
    );
  }

  Widget _hud() {
    final score = _score!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _tierCell(),
        _hudCell('SCORE', '${score.score}'),
        _hudCell('STREAK', '×${score.streak}'),
        _hudCell('BEST', '${score.highScore}'),
      ],
    );
  }

  Widget _tierCell() {
    final int tierCount = _maxWordLen - _minWordLen + 1;
    final int tier =
        (_currentMaxLen - _minWordLen + 1).clamp(1, tierCount);
    final int total = _prefs?.getInt(PrefsKeys.hexWordTotal) ?? 0;
    final String progress = tier >= tierCount
        ? 'MAX'
        : '${total % _wordsPerStep}/$_wordsPerStep';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('TIER', style: AppText.kicker()),
        const SizedBox(height: 2),
        Text('T$tier', style: AppText.hudValue()),
        Text(progress,
            style: AppText.mono(size: 9, color: AppColors.g2)),
      ],
    );
  }

  Widget _hudCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppText.kicker()),
        const SizedBox(height: 2),
        Text(value, style: AppText.hudValue()),
      ],
    );
  }

  Widget _hexDisplay() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: _cachedHexPairs
          .map((p) => Text(
                p,
                style: AppText.mono(
                    size: 22,
                    color: AppColors.amber,
                    weight: FontWeight.w600),
              ))
          .toList(),
    );
  }

  Widget _letterBoxes() {
    if (_word.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (ctx, constraints) {
      final boxSlot =
          (constraints.maxWidth / _word.length).clamp(0.0, 50.0);
      final boxW = (boxSlot - 4.0).clamp(0.0, 46.0);
      final fontSize = (boxW * 0.45).clamp(10.0, 18.0);

      return ScaleTransition(
        scale: _pulseAnim,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_word.length, (i) {
            final isRevealed = i < _revealed;
            final isCurrent = i == _revealed && !_solved;
            final letter = isRevealed ? _word[i].toUpperCase() : '';

            final Color borderColor;
            final Color textColor;
            if (isRevealed) {
              borderColor = AppColors.g3;
              textColor = AppColors.g4;
            } else if (isCurrent && _wrongFlash) {
              borderColor = AppColors.red;
              textColor = AppColors.red;
            } else if (isCurrent) {
              borderColor = AppColors.g2;
              textColor = AppColors.g2;
            } else {
              borderColor = AppColors.g1;
              textColor = AppColors.g1;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: boxW,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                    color: borderColor, width: isCurrent ? 1.5 : 1),
                boxShadow: isRevealed ? AppGlow.sm : null,
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: AppText.mono(
                    size: fontSize,
                    color: textColor,
                    weight: FontWeight.w700),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _feedback() {
    final score = _score!;
    return Text(
      '[ OK ] ✓  +$_lastEarned PTS  ·  ×${score.streak}',
      style: AppText.mono(size: 11, color: AppColors.g3),
    );
  }

  Widget _nextButton() {
    return GestureDetector(
      onTap: _next,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
        child: Text('NEXT', style: AppText.label()),
      ),
    );
  }
}
