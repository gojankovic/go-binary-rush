import 'dart:async';
import 'package:flutter/material.dart';
import '../game/difficulty.dart';
import '../game/question_generator.dart';
import '../game/score_engine.dart';
import '../services/haptics.dart';
import '../widgets/bit_row.dart';
import '../widgets/new_best_banner.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _dimGreen => AppColors.g2;
Color get _muteGreen => AppColors.g1;
Color get _red => AppColors.red;

class HexScreen extends StatefulWidget {
  const HexScreen({super.key});

  @override
  State<HexScreen> createState() => _HexScreenState();
}

class _HexScreenState extends State<HexScreen>
    with SingleTickerProviderStateMixin {
  QuestionGenerator? _generator;
  ScoreEngine? _scoreEngine;
  int _target = 0;
  List<int> _bits = [];
  int? _highEntry;
  bool _solved = false;
  bool _wrong = false;
  bool _loaded = false;
  double _flashOpacity = 0.0;
  bool _newBestFlash = false;
  Timer? _newBestTimer;

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
      QuestionGenerator.create(mode: 'hex', tiers: kHexTiers),
      ScoreEngine.create(mode: 'hex'),
    ]);
    final gen = results[0] as QuestionGenerator;
    final score = results[1] as ScoreEngine;
    final target = gen.next();
    if (!mounted) return;
    setState(() {
      _generator = gen;
      _scoreEngine = score;
      _target = target;
      _bits = _toBits(target, gen.currentBits);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _newBestTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _is4bit => _generator!.currentBits == 4;

  List<int> _toBits(int value, int numBits) =>
      List.generate(numBits, (i) => (value >> (numBits - 1 - i)) & 1);

  String _h(int val) => val.toRadixString(16).toUpperCase();

  void _onKeypadTap(int digit) {
    if (_solved || _wrong) return;
    if (_is4bit) {
      if (digit == _target) {
        _triggerSuccess();
      } else {
        _onWrong();
      }
    } else {
      if (_highEntry == null) {
        setState(() => _highEntry = digit);
      } else {
        if (_highEntry! * 16 + digit == _target) {
          _triggerSuccess();
        } else {
          _onWrong();
        }
      }
    }
  }

  void _onBackspace() {
    if (_solved || _highEntry == null) return;
    setState(() => _highEntry = null);
  }

  void _triggerSuccess() {
    Haptics.mediumImpact();
    _scoreEngine!.onCorrect();
    _generator!.recordSolved();
    final newBest = _scoreEngine!.consumeNewBestFlash();
    setState(() {
      _solved = true;
      _flashOpacity = 1.0;
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
  }

  void _onWrong() {
    Haptics.lightImpact();
    _scoreEngine!.onWrong();
    setState(() {
      _wrong = true;
      _highEntry = null;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _wrong = false);
    });
  }

  void _next() {
    _pulseController.stop();
    _pulseController.reset();
    final gen = _generator!;
    final target = gen.next();
    setState(() {
      _target = target;
      _bits = _toBits(target, gen.currentBits);
      _highEntry = null;
      _solved = false;
      _wrong = false;
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
          'HEX MATCH',
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
                _hud(gen, score),
                const Spacer(),
                _bitDisplay(),
                const SizedBox(height: 32),
                _answerSlots(),
                const SizedBox(height: 28),
                _solved ? _correctFeedback() : _keypad(),
                const Spacer(),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashOpacity,
              duration: const Duration(milliseconds: 60),
              child: Container(color: const Color(0x2200FF41)),
            ),
          ),
          NewBestBanner(visible: _newBestFlash),
        ],
      ),
    );
  }

  Widget _bitDisplay() {
    return Column(
      children: [
        Text(
          'BINARY',
          style: TextStyle(fontSize: 11, color: _dimGreen, letterSpacing: 5),
        ),
        const SizedBox(height: 12),
        if (_is4bit)
          BitRow(
              bits: _bits, onToggle: (_) {}, enabled: false, glowing: _solved)
        else
          Column(
            children: [
              BitRow(
                  bits: _bits.sublist(0, 4),
                  onToggle: (_) {},
                  enabled: false,
                  glowing: _solved),
              const SizedBox(height: 8),
              BitRow(
                  bits: _bits.sublist(4),
                  onToggle: (_) {},
                  enabled: false,
                  glowing: _solved),
            ],
          ),
      ],
    );
  }

  Widget _answerSlots() {
    if (_is4bit) {
      return _slot(
        _solved ? _h(_target) : null,
        highlight: _solved,
      );
    }

    final hi = _solved
        ? _h(_target >> 4)
        : (_highEntry != null ? _h(_highEntry!) : null);
    final lo = _solved ? _h(_target & 0xF) : null;
    final hiHighlight = _solved || (_highEntry != null && !_wrong);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _slot(hi, highlight: hiHighlight),
        const SizedBox(width: 16),
        _slot(lo, highlight: _solved),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: _onBackspace,
          child: Text(
            '←',
            style: TextStyle(
              fontSize: 24,
              color: (!_solved && _highEntry != null) ? _green : _muteGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _slot(String? char, {bool highlight = false}) {
    final borderColor = _wrong ? _red : (highlight ? _green : _dimGreen);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: highlight ? 2 : 1),
      ),
      child: Text(
        char ?? '_',
        style: TextStyle(
          fontSize: 30,
          color: char != null ? _green : _muteGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _correctFeedback() {
    final hexStr = _is4bit
        ? '0x${_h(_target)}'
        : '0x${_h(_target >> 4)}${_h(_target & 0xF)}';
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _pulseAnim,
            child: Text(
              '= $hexStr',
              style:
                  TextStyle(fontSize: 22, color: _green, letterSpacing: 4),

            ),
          ),
        ),
        const SizedBox(height: 12),
        ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _pulseAnim,
            child: Text(
              'CORRECT',
              style: TextStyle(fontSize: 26, color: _green, letterSpacing: 8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _next,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: _green)),
            child: Text(
              'NEXT  →',
              style:
                  TextStyle(fontSize: 15, color: _green, letterSpacing: 5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _keypad() {
    const labels = '0123456789ABCDEF';
    return Column(
      children: [
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 0; col < 4; col++)
                  _keyCell(labels[row * 4 + col], row * 4 + col),
              ],
            ),
          ),
      ],
    );
  }

  Widget _keyCell(String label, int value) {
    return GestureDetector(
      onTap: () => _onKeypadTap(value),
      child: Container(
        width: 62,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: _dimGreen)),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 16, color: _green, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _hud(QuestionGenerator gen, ScoreEngine score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _tierStat(gen),
        _stat('SCORE', '${score.score}'),
        _stat('STREAK', '×${score.streak}'),
        _stat('BEST', '${score.highScore}'),
      ],
    );
  }

  Widget _tierStat(QuestionGenerator gen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('TIER',
            style:
                TextStyle(fontSize: 9, color: _dimGreen, letterSpacing: 2)),
        const SizedBox(height: 2),
        Text('T${gen.currentTier}',
            style: TextStyle(
                fontSize: 14, color: _green, letterSpacing: 1)),
        Text('${gen.tierSolvedCount}/${gen.tierCap}',
            style: TextStyle(
                fontSize: 8, color: _dimGreen, letterSpacing: 1)),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: _dimGreen, letterSpacing: 2)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, color: _green, letterSpacing: 1)),
      ],
    );
  }
}
