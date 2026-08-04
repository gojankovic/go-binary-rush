import 'dart:async';

import 'package:flutter/material.dart';

import '../game/bit_flip.dart';
import '../game/question_generator.dart';
import '../game/score_engine.dart';
import '../services/haptics.dart';
import '../services/prefs_keys.dart';
import '../theme.dart';
import '../widgets/bit_row.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_pips.dart';
import '../widgets/new_best_banner.dart';
import 'success_feedback.dart';

class BitFlipScreen extends StatefulWidget {
  const BitFlipScreen({super.key});

  @override
  State<BitFlipScreen> createState() => _BitFlipScreenState();
}

class _BitFlipScreenState extends State<BitFlipScreen>
    with SingleTickerProviderStateMixin, SuccessFeedback {
  static const _lapSize = 10;

  QuestionGenerator? _generator;
  ScoreEngine? _scoreEngine;
  BitFlipQuestion? _question;
  List<int> _bits = const [];
  int _moves = 0;
  int _lapSolved = 0;
  int _lastEarned = 0;
  bool _solved = false;
  bool _loaded = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initGame();
  }

  Future<void> _initGame() async {
    final results = await Future.wait([
      QuestionGenerator.create(mode: GameModes.bitFlip),
      ScoreEngine.create(mode: GameModes.bitFlip),
    ]);
    final generator = results[0] as QuestionGenerator;
    final score = results[1] as ScoreEngine;
    final question = _generateQuestion(generator);
    if (!mounted) return;
    setState(() {
      _generator = generator;
      _scoreEngine = score;
      _applyQuestion(question);
      _loaded = true;
    });
  }

  BitFlipQuestion _generateQuestion(QuestionGenerator generator) {
    final target = generator.next();
    return generateBitFlipQuestion(bits: generator.currentBits, target: target);
  }

  void _applyQuestion(BitFlipQuestion question) {
    _question = question;
    _bits = question.startBits;
    _moves = 0;
    _solved = false;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleBit(int index) {
    if (_solved) return;
    Haptics.selectionClick();
    final nextBits = List<int>.from(_bits)..[index] ^= 1;
    setState(() {
      _bits = nextBits;
      _moves++;
    });
    if (_question!.isSolved(nextBits)) _triggerSuccess();
  }

  void _triggerSuccess() {
    Haptics.mediumImpact();
    final bonus = bitFlipBonus(
      moves: _moves,
      optimalMoves: _question!.optimalMoves,
    );
    final earned = _scoreEngine!.onCorrect(bonus: bonus);
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
    setState(() {
      _applyQuestion(_generateQuestion(_generator!));
      _lapSolved = (_lapSolved + 1) % _lapSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.g4)),
      );
    }

    final question = _question!;
    final perfect = _moves == question.optimalMoves;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.g2),
        title: Text('BIT FLIP', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 14),
                GameHud(gen: _generator!, score: _scoreEngine!),
                const Spacer(),
                GamePips(lapSolved: _lapSolved, solved: _solved),
                const SizedBox(height: 16),
                Text('TARGET', style: AppText.kicker(color: AppColors.g2)),
                const SizedBox(height: 4),
                Text('${question.target}', style: AppText.bigTarget()),
                const SizedBox(height: 14),
                Text(
                  'START ${question.start}  ·  PAR ${question.optimalMoves}',
                  style: AppText.mono(size: 11, color: AppColors.g2),
                ),
                const SizedBox(height: 12),
                BitRow(
                  bits: _bits,
                  onToggle: _toggleBit,
                  enabled: !_solved,
                  glowing: _solved,
                ),
                const SizedBox(height: 12),
                Text(
                  'MOVES $_moves',
                  style: AppText.mono(
                    size: 12,
                    color: _moves > question.optimalMoves
                        ? AppColors.amber
                        : AppColors.g3,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 82,
                  child: _solved
                      ? _feedback(perfect: perfect)
                      : const SizedBox.shrink(),
                ),
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

  Widget _feedback({required bool perfect}) {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _pulseAnim,
            child: Text(
              perfect
                  ? 'PERFECT  +$_lastEarned PTS'
                  : 'SOLVED  +$_lastEarned PTS',
              style: AppText.mono(size: 13, color: AppColors.g4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _next,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
            decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
            child: Text('NEXT  →', style: AppText.label()),
          ),
        ),
      ],
    );
  }
}
