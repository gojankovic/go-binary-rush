import 'dart:async';
import 'package:flutter/material.dart';
import '../game/question_generator.dart';
import '../game/score_engine.dart';
import '../services/haptics.dart';
import '../widgets/bit_row.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_pips.dart';
import '../widgets/new_best_banner.dart';
import 'success_feedback.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _muteGreen => AppColors.g1;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, SuccessFeedback {
  QuestionGenerator? _generator;
  ScoreEngine? _scoreEngine;
  int _target = 0;
  List<int> _bits = [];
  bool _solved = false;
  bool _loaded = false;
  bool _hintOn = false;
  bool _hintUsed = false;
  int? _lastToggled;
  int _lapSolved = 0;
  int _lastEarned = 0;

  static const int _lapSize = 10;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initGame();
  }

  Future<void> _initGame() async {
    final results = await Future.wait([
      QuestionGenerator.create(mode: 'match'),
      ScoreEngine.create(mode: 'match'),
    ]);
    final gen = results[0] as QuestionGenerator;
    final score = results[1] as ScoreEngine;
    if (!mounted) return;
    setState(() {
      _generator = gen;
      _scoreEngine = score;
      _target = gen.next();
      _bits = List.filled(gen.currentBits, 0);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _computeValue(List<int> bits) {
    int val = 0;
    for (int i = 0; i < bits.length; i++) {
      val += bits[i] * (1 << (bits.length - 1 - i));
    }
    return val;
  }

  void _toggleBit(int index) {
    if (_solved) return;
    Haptics.selectionClick();
    final newBits = List<int>.from(_bits);
    newBits[index] = newBits[index] == 0 ? 1 : 0;
    setState(() {
      _bits = newBits;
      _lastToggled = index;
    });
    if (_computeValue(newBits) == _target) _triggerSuccess();
  }

  void _triggerSuccess() {
    Haptics.mediumImpact();
    final earned = _scoreEngine!.onCorrect();
    _generator!.recordSolved();
    setState(() {
      _solved = true;
      _lastEarned = earned;
    });
    _pulseController.repeat(reverse: true);
    runSuccessFeedback(
      newBest: _scoreEngine!.consumeNewBestFlash(),
      onAdvance: _next,
    );
  }

  void _next() {
    cancelPendingAdvance();
    _pulseController.stop();
    _pulseController.reset();
    final gen = _generator!;
    setState(() {
      _target = gen.next();
      _bits = List.filled(gen.currentBits, 0);
      _solved = false;
      _hintOn = false;
      _hintUsed = false;
      _lastToggled = null;
      _lapSolved = (_lapSolved + 1) % _lapSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    final score = _scoreEngine!;
    final gen = _generator!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E6E2E)),
        title: Text(
          'GO BINARY RUSH',
          style: TextStyle(color: _green, fontSize: 15, letterSpacing: 4),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _muteGreen),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                GameHud(gen: gen, score: score),
                const Spacer(),
                GamePips(lapSolved: _lapSolved, solved: _solved),
                const SizedBox(height: 20),
                _targetDisplay(),
                const SizedBox(height: 32),
                if (_hintOn || _solved) ...[
                  _weightsRow(),
                  const SizedBox(height: 8),
                ],
                BitRow(
                  bits: _bits,
                  onToggle: _toggleBit,
                  enabled: !_solved,
                  glowing: _solved,
                ),
                const SizedBox(height: 16),
                _hintArea(),
                const SizedBox(height: 32),
                _feedback(),
                const Spacer(),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: flashOpacity,
              duration: const Duration(milliseconds: 60),
              child: Container(color: AppColors.g3.withValues(alpha: 0.13)),
            ),
          ),
          NewBestBanner(visible: newBestFlash),
        ],
      ),
    );
  }

  double _tileWidth(int n) {
    if (n <= 4) return 72;
    if (n <= 5) return 64;
    if (n <= 6) return 56;
    if (n <= 7) return 50;
    return 44;
  }

  Widget _weightsRow() {
    final n = _bits.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(n, (i) {
        final weight = 1 << (n - 1 - i);
        final isOn = _bits[i] == 1;
        final isLive = !_solved && _lastToggled == i;
        final color = isLive
            ? AppColors.amber
            : isOn
                ? AppColors.g4
                : AppColors.g1;
        return SizedBox(
          width: _tileWidth(n),
          child: Text(
            '$weight',
            textAlign: TextAlign.center,
            style: AppText.mono(size: 10, color: color),
          ),
        );
      }),
    );
  }

  Widget _hintArea() {
    if (_solved) return _livePreview();
    if (_hintOn) return _livePreview();
    return GestureDetector(
      onTap: () {
        setState(() {
          _hintOn = true;
          if (!_hintUsed) {
            _hintUsed = true;
            _scoreEngine!.onHint();
          }
        });
      },
      child: Text(
        '[ HINT  ·  −2 ]',
        style: AppText.kicker(color: AppColors.amber).copyWith(letterSpacing: 3),
      ),
    );
  }

  Widget _livePreview() {
    final n = _bits.length;
    final parts = <Widget>[];
    for (int i = 0; i < n; i++) {
      final weight = 1 << (n - 1 - i);
      final isOn = _bits[i] == 1;
      if (i > 0) {
        parts.add(Text(' + ',
            style: AppText.mono(size: 11, color: AppColors.g1)));
      }
      parts.add(Text(
        '${_bits[i]}·$weight',
        style: AppText.mono(size: 11, color: isOn ? AppColors.g4 : AppColors.g1),
      ));
    }
    final value = _computeValue(_bits);
    final sumColor = _solved
        ? AppColors.g5
        : value == _target
            ? AppColors.g4
            : AppColors.g2;
    parts.add(Text(' = ', style: AppText.mono(size: 11, color: AppColors.g1)));
    parts.add(Text(
      '$value',
      style: AppText.mono(size: 14, color: sumColor, weight: FontWeight.w700),
    ));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: parts,
    );
  }

  Widget _targetDisplay() {
    return Column(
      children: [
        Text('TARGET', style: AppText.kicker(color: AppColors.g2)
            .copyWith(letterSpacing: 5)),
        const SizedBox(height: 8),
        Text('$_target', style: AppText.bigTarget()),
      ],
    );
  }

  Widget _feedback() {
    if (_solved) {
      final score = _scoreEngine!;
      return Column(
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _pulseAnim,
              child: Text(
                '[ OK ]  ✓  +$_lastEarned PTS  ·  ×${score.streak}',
                style: AppText.mono(size: 13, color: AppColors.g4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _next,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.g2),
              ),
              child: Text('NEXT  →',
                  style: AppText.mono(size: 13, color: AppColors.g3,
                      weight: FontWeight.w600)
                      .copyWith(letterSpacing: 4)),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
