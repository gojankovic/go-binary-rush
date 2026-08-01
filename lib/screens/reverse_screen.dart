import 'dart:async';
import 'package:flutter/material.dart';
import '../game/binary.dart';
import '../game/question_generator.dart';
import '../game/score_engine.dart';
import '../services/haptics.dart';
import '../widgets/bit_row.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_pips.dart';
import '../widgets/new_best_banner.dart';
import '../widgets/num_pad.dart';
import 'success_feedback.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _dimGreen => AppColors.g2;
Color get _muteGreen => AppColors.g1;
Color get _red => AppColors.red;

class ReverseScreen extends StatefulWidget {
  const ReverseScreen({super.key});

  @override
  State<ReverseScreen> createState() => _ReverseScreenState();
}

class _ReverseScreenState extends State<ReverseScreen>
    with SingleTickerProviderStateMixin, SuccessFeedback {
  QuestionGenerator? _generator;
  ScoreEngine? _scoreEngine;
  int _target = 0;
  List<int> _bits = [];
  bool _solved = false;
  bool _wrong = false;
  bool _loaded = false;
  int _lapSolved = 0;
  int _lastEarned = 0;

  static const int _lapSize = GamePips.lapSize;

  String _inputEntry = '';
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
      QuestionGenerator.create(mode: 'reverse'),
      ScoreEngine.create(mode: 'reverse'),
    ]);
    final gen = results[0] as QuestionGenerator;
    final score = results[1] as ScoreEngine;
    final target = gen.next();
    if (!mounted) return;
    setState(() {
      _generator = gen;
      _scoreEngine = score;
      _target = target;
      _bits = intToBits(target, gen.currentBits);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _tapDigit(String d) {
    if (_solved) return;
    if (d == '⌫') {
      if (_inputEntry.isNotEmpty) {
        setState(
          () => _inputEntry = _inputEntry.substring(0, _inputEntry.length - 1),
        );
      }
      return;
    }
    final next = _inputEntry + d;
    final input = int.tryParse(next);
    if (input == _target) {
      _inputEntry = next;
      _onCorrect();
    } else if (next.length >= _target.toString().length) {
      _scoreEngine!.onWrong();
      setState(() {
        _wrong = true;
        _inputEntry = '';
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrong = false);
      });
    } else {
      setState(() => _inputEntry = next);
    }
  }

  void _onCorrect() {
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
    final target = gen.next();
    setState(() {
      _target = target;
      _bits = intToBits(target, gen.currentBits);
      _solved = false;
      _wrong = false;
      _inputEntry = '';
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
        iconTheme: IconThemeData(color: _dimGreen),
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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    GameHud(gen: gen, score: score),
                    const SizedBox(height: 12),
                    GamePips(lapSolved: _lapSolved, solved: _solved),
                    const SizedBox(height: 16),
                    Text(
                      'DECODE',
                      style: AppText.kicker(
                        color: AppColors.g2,
                      ).copyWith(letterSpacing: 5),
                    ),
                    const SizedBox(height: 16),
                    BitRow(bits: _bits, onToggle: (_) {}, enabled: false),
                  ],
                ),
              ),
              // The entry block is the only part with slack: on a short phone
              // the HUD, bit row and keypad together leave it less room than
              // its natural height, so scale it down instead of overflowing.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DECIMAL VALUE?',
                        style: AppText.kicker(
                          color: AppColors.g2,
                        ).copyWith(letterSpacing: 3),
                      ),
                      const SizedBox(height: 12),
                      _valueDisplay(),
                      const SizedBox(height: 8),
                      AnimatedOpacity(
                        opacity: _wrong ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 100),
                        child: Text(
                          'WRONG',
                          style: AppText.mono(
                            size: 13,
                            color: _red,
                          ).copyWith(letterSpacing: 5),
                        ),
                      ),
                      if (_solved) ...[const SizedBox(height: 16), _feedback()],
                    ],
                  ),
                ),
              ),
              NumPad(onTap: _tapDigit, disabled: _solved),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
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

  Widget _valueDisplay() {
    final text = _inputEntry.isEmpty ? '?' : _inputEntry;
    final color = _wrong ? _red : (_inputEntry.isEmpty ? _dimGreen : _green);
    return Text(
      text,
      style: TextStyle(
        fontSize: 52,
        color: color,
        fontFamily: 'JetBrains Mono',
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _feedback() {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _pulseAnim,
            child: Text(
              '[ OK ]  ✓  +$_lastEarned PTS  ·  ×${_scoreEngine!.streak}',
              style: AppText.mono(size: 13, color: AppColors.g4),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _next,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
            child: Text(
              'NEXT  →',
              style: AppText.mono(
                size: 13,
                color: AppColors.g3,
                weight: FontWeight.w600,
              ).copyWith(letterSpacing: 4),
            ),
          ),
        ),
      ],
    );
  }
}
