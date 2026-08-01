import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game/question_generator.dart';
import '../game/score_engine.dart';
import '../services/haptics.dart';
import '../widgets/bit_row.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_pips.dart';
import '../widgets/new_best_banner.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _dimGreen => AppColors.g2;
Color get _muteGreen => AppColors.g1;

class XorScreen extends StatefulWidget {
  const XorScreen({super.key});

  @override
  State<XorScreen> createState() => _XorScreenState();
}

class _XorScreenState extends State<XorScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();

  QuestionGenerator? _generator;
  ScoreEngine? _scoreEngine;
  List<int> _bitsA = [];
  List<int> _bitsB = [];
  List<int> _bitsC = [];
  int _xorTarget = 0;
  bool _solved = false;
  bool _loaded = false;
  double _flashOpacity = 0.0;
  int _lapSolved = 0;
  int _lastEarned = 0;
  Timer? _advanceTimer;
  bool _newBestFlash = false;
  Timer? _newBestTimer;

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
      QuestionGenerator.create(mode: 'xor'),
      ScoreEngine.create(mode: 'xor'),
    ]);
    final gen = results[0] as QuestionGenerator;
    final score = results[1] as ScoreEngine;
    if (!mounted) return;
    setState(() {
      _generator = gen;
      _scoreEngine = score;
      _loaded = true;
    });
    _newQuestion();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _newBestTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _newQuestion() {
    final gen = _generator!;
    final xorTarget = gen.next();
    final bits = gen.currentBits;
    final maxVal = (1 << bits) - 1;
    final a = _random.nextInt(maxVal + 1);
    final b = a ^ xorTarget;
    setState(() {
      _xorTarget = xorTarget;
      _bitsA = _toBits(a, bits);
      _bitsB = _toBits(b, bits);
      _bitsC = List.filled(bits, 0);
      _solved = false;
    });
  }

  List<int> _toBits(int value, int numBits) =>
      List.generate(numBits, (i) => (value >> (numBits - 1 - i)) & 1);

  int _computeValue(List<int> bits) {
    int val = 0;
    for (int i = 0; i < bits.length; i++) {
      val += bits[i] * (1 << (bits.length - 1 - i));
    }
    return val;
  }

  void _toggleC(int index) {
    if (_solved) return;
    Haptics.selectionClick();
    final newC = List<int>.from(_bitsC);
    newC[index] = newC[index] == 0 ? 1 : 0;
    setState(() => _bitsC = newC);
    if (_computeValue(newC) == _xorTarget) _triggerSuccess();
  }

  void _triggerSuccess() {
    Haptics.mediumImpact();
    final earned = _scoreEngine!.onCorrect();
    final newBest = _scoreEngine!.consumeNewBestFlash();
    setState(() {
      _solved = true;
      _flashOpacity = 1.0;
      _lastEarned = earned;
      if (newBest) _newBestFlash = true;
    });
    if (newBest) {
      _newBestTimer?.cancel();
      _newBestTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _newBestFlash = false);
      });
    }
    _pulseController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _flashOpacity = 0.0);
    });
    _advanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _next();
    });
  }

  void _next() {
    _advanceTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _lapSolved = (_lapSolved + 1) % _lapSize);
    _newQuestion();
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
    final valC = _computeValue(_bitsC);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: _dimGreen),
        title: Text('GO BINARY RUSH',
            style: TextStyle(color: _green, fontSize: 15, letterSpacing: 4)),
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
                Text('A  ⊕  B  =  C',
                    style: AppText.kicker(color: AppColors.g2)
                        .copyWith(letterSpacing: 4, fontSize: 13)),
                const SizedBox(height: 28),
                _fixedRow(label: 'A', bits: _bitsA),
                const SizedBox(height: 8),
                _fixedRow(label: 'B', bits: _bitsB),
                _divider(),
                _playerRow(valC),
                const SizedBox(height: 36),
                _feedback(),
                const Spacer(),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashOpacity,
              duration: const Duration(milliseconds: 60),
              child: Container(color: AppColors.g3.withValues(alpha: 0.13)),
            ),
          ),
          NewBestBanner(visible: _newBestFlash),
        ],
      ),
    );
  }

  Widget _fixedRow({required String label, required List<int> bits}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: AppText.kicker(color: AppColors.g2)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BitRow(bits: bits, onToggle: (_) {}, enabled: false),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 28),
          Container(height: 1, width: 260, color: _muteGreen),
        ],
      ),
    );
  }

  Widget _playerRow(int valC) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              child: Text('C', style: AppText.kicker(color: AppColors.g2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BitRow(
                bits: _bitsC,
                onToggle: _toggleC,
                enabled: !_solved,
                glowing: _solved,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '= $valC',
          style: AppText.mono(
              size: 18,
              color: _solved ? AppColors.g4 : AppColors.g2),
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
            child: Text('NEXT  →',
                style: AppText.mono(
                    size: 13, color: AppColors.g3, weight: FontWeight.w600)
                    .copyWith(letterSpacing: 4)),
          ),
        ),
      ],
    );
  }
}
