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
import 'success_feedback.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _dimGreen => AppColors.g2;
Color get _muteGreen => AppColors.g1;

class AdditionScreen extends StatefulWidget {
  const AdditionScreen({super.key});

  @override
  State<AdditionScreen> createState() => _AdditionScreenState();
}

class _AdditionScreenState extends State<AdditionScreen>
    with SingleTickerProviderStateMixin, SuccessFeedback {
  QuestionGenerator? _generator;
  ScoreEngine? _scoreEngine;
  int _target = 0;
  List<int> _bitsA = [];
  List<int> _bitsB = [];
  bool _solved = false;
  bool _loaded = false;
  bool _hintAOn = false;
  bool _hintAUsed = false;
  bool _hintBOn = false;
  bool _hintBUsed = false;
  int _lapSolved = 0;
  int _lastEarned = 0;

  static const int _lapSize = GamePips.lapSize;

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
      QuestionGenerator.create(mode: 'addition', minTarget: 2),
      ScoreEngine.create(mode: 'addition'),
    ]);
    final gen = results[0] as QuestionGenerator;
    final score = results[1] as ScoreEngine;
    final target = gen.next();
    if (!mounted) return;
    setState(() {
      _generator = gen;
      _scoreEngine = score;
      _target = target;
      _bitsA = List.filled(gen.currentBits, 0);
      _bitsB = List.filled(gen.currentBits, 0);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggle(List<int> row, int index, void Function(List<int>) update) {
    if (_solved) return;
    Haptics.selectionClick();
    final newBits = List<int>.from(row);
    newBits[index] = newBits[index] == 0 ? 1 : 0;
    update(newBits);
    setState(() {});
    final valA = bitsToInt(_bitsA);
    final valB = bitsToInt(_bitsB);
    if (valA + valB == _target && valA > 0 && valB > 0) {
      _triggerSuccess();
    }
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
    final target = gen.next();
    setState(() {
      _target = target;
      _bitsA = List.filled(gen.currentBits, 0);
      _bitsB = List.filled(gen.currentBits, 0);
      _solved = false;
      _hintAOn = false;
      _hintAUsed = false;
      _hintBOn = false;
      _hintBUsed = false;
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
    final valA = bitsToInt(_bitsA);
    final valB = bitsToInt(_bitsB);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          GameHud(gen: gen, score: score),
          if (largeText) const SizedBox(height: 16) else const Spacer(),
          GamePips(lapSolved: _lapSolved, solved: _solved),
          const SizedBox(height: 20),
          _targetDisplay(),
          const SizedBox(height: 28),
          _rowSection(
            label: 'A',
            bits: _bitsA,
            value: valA,
            onToggle: (i) => _toggle(_bitsA, i, (b) => _bitsA = b),
            hintOn: _hintAOn,
          ),
          const SizedBox(height: 16),
          _rowSection(
            label: 'B',
            bits: _bitsB,
            value: valB,
            onToggle: (i) => _toggle(_bitsB, i, (b) => _bitsB = b),
            hintOn: _hintBOn,
          ),
          const SizedBox(height: 20),
          _hintArea(),
          const SizedBox(height: 16),
          _feedback(),
          if (largeText) const SizedBox(height: 16) else const Spacer(),
        ],
      ),
    );

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
          largeText ? SingleChildScrollView(child: content) : content,
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

  Widget _rowSection({
    required String label,
    required List<int> bits,
    required int value,
    required void Function(int) onToggle,
    required bool hintOn,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppText.kicker(
                color: AppColors.g2,
              ).copyWith(letterSpacing: 3),
            ),
            if (hintOn || _solved) ...[
              const SizedBox(width: 12),
              Text(
                '= $value',
                style: AppText.mono(
                  size: 18,
                  color: _solved ? AppColors.g4 : AppColors.g2,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        BitRow(
          bits: bits,
          onToggle: onToggle,
          enabled: !_solved,
          glowing: _solved,
        ),
      ],
    );
  }

  Widget _hintArea() {
    if (_solved) return const SizedBox.shrink();
    if (_hintAOn && _hintBOn) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_hintAOn) Expanded(child: _hintButton('SHOW A', _onHintA)),
        if (!_hintAOn && !_hintBOn) const SizedBox(width: 8),
        if (!_hintBOn) Expanded(child: _hintButton('SHOW B', _onHintB)),
      ],
    );
  }

  Widget _hintButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.6)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$label  ·  −1',
            maxLines: 1,
            style: AppText.kicker(
              color: AppColors.amber,
            ).copyWith(letterSpacing: 2),
          ),
        ),
      ),
    );
  }

  void _onHintA() {
    if (_hintAOn) return;
    setState(() {
      _hintAOn = true;
      if (!_hintAUsed) {
        _hintAUsed = true;
        _scoreEngine!.onHint(1);
      }
    });
  }

  void _onHintB() {
    if (_hintBOn) return;
    setState(() {
      _hintBOn = true;
      if (!_hintBUsed) {
        _hintBUsed = true;
        _scoreEngine!.onHint(1);
      }
    });
  }

  Widget _targetDisplay() {
    return Column(
      children: [
        Text(
          'TARGET',
          style: AppText.kicker(color: AppColors.g2).copyWith(letterSpacing: 5),
        ),
        const SizedBox(height: 4),
        Text('$_target', style: AppText.bigTarget()),
        const SizedBox(height: 6),
        Text(
          'A > 0   +   B > 0',
          style: AppText.kicker(color: AppColors.g2).copyWith(letterSpacing: 3),
        ),
      ],
    );
  }

  Widget _feedback() {
    if (!_solved) return const SizedBox.shrink();
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
