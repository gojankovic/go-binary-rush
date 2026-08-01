import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/daily_challenge.dart';
import '../services/prefs_keys.dart';
import '../services/haptics.dart';
import '../services/notifications.dart';
import '../widgets/bit_row.dart';
import '../widgets/hex_word_keyboard.dart';
import '../widgets/num_pad.dart';
import '../theme.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  static const int _total = kDailyQuestionCount;

  SharedPreferences? _prefs;
  String _dateKey = '';
  List<DailyQuestion> _questions = const [];
  int _current = 0;
  List<bool?> _results = List.filled(_total, null);
  bool _solved = false;
  bool _done = false;
  bool _alreadyDone = false;
  bool _loaded = false;
  int _score = 0;
  int _bestScore = 0;
  int _dailyStreak = 0;
  Timer? _advanceTimer;

  // Attempt tracking (resets per question)
  int _attempts = 0;
  bool _failed = false;

  // Match state
  List<int> _bits = [];

  // Reverse state
  String _revEntry = '';
  bool _revWrong = false;
  Timer? _revWrongTimer;

  // HexWord state
  int _hwRevealed = 0;
  bool _hwWrong = false;
  Timer? _hwWrongTimer;
  List<String> _hwCachedHexPairs = [];

  // Addition state
  List<int> _addA = [];
  List<int> _addB = [];

  // XOR state
  List<int> _curXorA = [];
  List<int> _curXorB = [];
  List<int> _curXorC = [];

  // HEX MATCH state
  int? _hmHighEntry;
  bool _hmWrong = false;
  Timer? _hmWrongTimer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;

  DailyQuestion get _question => _questions[_current];
  DailyMode get _mode => _question.mode;
  int get _qBits => _question.bits;
  int get _target => _question.target;
  String get _word => _question.word;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _init();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _revWrongTimer?.cancel();
    _hwWrongTimer?.cancel();
    _hmWrongTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey = dailyDateKey(now);
    final questions = buildDailyQuestions(now);

    final alreadyDone = prefs.getBool(PrefsKeys.dailyDone(dateKey)) ?? false;
    final best = prefs.getInt(PrefsKeys.dailyBest(dateKey)) ?? 0;
    final dailyStreak = prefs.getInt(PrefsKeys.dailyStreak) ?? 0;

    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _dateKey = dateKey;
      _questions = questions;
      _results = List.filled(_total, null);
      _bestScore = best;
      _score = alreadyDone ? best : 0;
      _alreadyDone = alreadyDone;
      _dailyStreak = dailyStreak;
      _loaded = true;
    });

    if (!alreadyDone) _setupQuestion();
  }

  void _setupQuestion() {
    final q = _question;
    final hwPairs = q.mode == DailyMode.hexWord
        ? q.word.codeUnits
            .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
            .toList()
        : <String>[];
    setState(() {
      _attempts = 0;
      _failed = false;
      _solved = false;
      _revEntry = '';
      _revWrong = false;
      _hwRevealed = 0;
      _hwWrong = false;
      _hmHighEntry = null;
      _hmWrong = false;
      _hwCachedHexPairs = hwPairs;
      if (q.mode == DailyMode.match) {
        _bits = List.filled(q.bits, 0);
      } else if (q.mode == DailyMode.addition) {
        _addA = List.filled(q.bits, 0);
        _addB = List.filled(q.bits, 0);
      } else if (q.mode == DailyMode.xor) {
        _curXorA = _toBits(q.xorA, q.bits);
        _curXorB = _toBits(q.xorA ^ q.target, q.bits);
        _curXorC = List.filled(q.bits, 0);
      }
    });
  }

  // ── Match ──────────────────────────────────────────────────────

  int _val(List<int> bits) {
    int v = 0;
    for (int i = 0; i < bits.length; i++) {
      v += bits[i] * (1 << (bits.length - 1 - i));
    }
    return v;
  }

  List<int> _toBits(int value, int n) =>
      List.generate(n, (i) => (value >> (n - 1 - i)) & 1);

  void _toggleBit(int index) {
    if (_solved || _failed) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_bits)..[index] ^= 1;
    setState(() => _bits = nb);
    if (_val(nb) == _target) _triggerSuccess();
  }

  // ── Addition ───────────────────────────────────────────────────

  void _toggleAddA(int index) {
    if (_solved || _failed) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_addA)..[index] ^= 1;
    setState(() => _addA = nb);
    _checkAddition();
  }

  void _toggleAddB(int index) {
    if (_solved || _failed) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_addB)..[index] ^= 1;
    setState(() => _addB = nb);
    _checkAddition();
  }

  void _checkAddition() {
    final va = _val(_addA);
    final vb = _val(_addB);
    if (va > 0 && vb > 0 && va + vb == _target) _triggerSuccess();
  }

  // ── XOR ────────────────────────────────────────────────────────

  void _toggleXorC(int index) {
    if (_solved || _failed) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_curXorC)..[index] ^= 1;
    setState(() => _curXorC = nb);
    if (_val(nb) == _target) _triggerSuccess();
  }

  // ── HEX MATCH ──────────────────────────────────────────────────

  bool get _hmIs4bit => _qBits == 4;

  void _hmTap(int digit) {
    if (_solved || _failed || _hmWrong) return;
    if (_hmIs4bit) {
      if (digit == _target) {
        _triggerSuccess();
      } else {
        _hmOnWrong();
      }
    } else {
      if (_hmHighEntry == null) {
        setState(() => _hmHighEntry = digit);
      } else {
        if (_hmHighEntry! * 16 + digit == _target) {
          _triggerSuccess();
        } else {
          _hmOnWrong();
        }
      }
    }
  }

  void _hmBackspace() {
    if (_solved || _failed || _hmHighEntry == null) return;
    setState(() => _hmHighEntry = null);
  }

  void _hmOnWrong() {
    _attempts++;
    Haptics.lightImpact();
    _hmWrongTimer?.cancel();
    setState(() {
      _hmWrong = true;
      _hmHighEntry = null;
    });
    if (_attempts >= 3) {
      _hmWrongTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _triggerFail();
      });
    } else {
      _hmWrongTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _hmWrong = false);
      });
    }
  }

  // ── Reverse ────────────────────────────────────────────────────

  void _tapDigit(String d) {
    if (_solved || _failed || _revWrong) return;
    if (d == '⌫') {
      if (_revEntry.isNotEmpty) {
        setState(
            () => _revEntry = _revEntry.substring(0, _revEntry.length - 1));
      }
      return;
    }
    final next = _revEntry + d;
    final val = int.tryParse(next);
    if (val == _target) {
      _revEntry = next;
      _triggerSuccess();
    } else if (next.length >= _target.toString().length) {
      _attempts++;
      _revWrongTimer?.cancel();
      setState(() { _revWrong = true; _revEntry = next; });
      if (_attempts >= 3) {
        _revWrongTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) _triggerFail();
        });
      } else {
        _revWrongTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() { _revWrong = false; _revEntry = ''; });
        });
      }
    } else {
      setState(() => _revEntry = next);
    }
  }

  // ── HexWord ────────────────────────────────────────────────────

  void _tapLetter(String letter) {
    if (_solved || _failed || _word.isEmpty) return;
    if (letter == _word[_hwRevealed].toUpperCase()) {
      Haptics.selectionClick();
      setState(() => _hwRevealed++);
      if (_hwRevealed == _word.length) _triggerSuccess();
    } else {
      _attempts++;
      Haptics.lightImpact();
      _hwWrongTimer?.cancel();
      setState(() => _hwWrong = true);
      if (_attempts >= 3) {
        _hwWrongTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) _triggerFail();
        });
      } else {
        _hwWrongTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _hwWrong = false);
        });
      }
    }
  }

  // ── Success / flow ─────────────────────────────────────────────

  void _triggerSuccess() {
    Haptics.mediumImpact();
    _pulseCtrl.repeat(reverse: true);
    final newResults = List<bool?>.from(_results)..[_current] = true;
    _prefs!.setInt(PrefsKeys.totalCorrect,
        (_prefs!.getInt(PrefsKeys.totalCorrect) ?? 0) + 1);
    setState(() {
      _score += 10;
      _solved = true;
      _results = newResults;
    });
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 700), _next);
  }

  void _triggerFail() {
    Haptics.heavyImpact();
    _advanceTimer?.cancel();
    final newResults = List<bool?>.from(_results)..[_current] = false;
    setState(() {
      _failed = true;
      _results = newResults;
    });
    _advanceTimer = Timer(const Duration(milliseconds: 1500), _next);
  }

  void _next() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    if (_current + 1 >= _total) {
      _finish();
      return;
    }
    setState(() => _current++);
    _setupQuestion();
  }

  void _finish() {
    if (_score > _bestScore) {
      _bestScore = _score;
      _prefs!.setInt(PrefsKeys.dailyBest(_dateKey), _bestScore);
    }
    _prefs!.setBool(PrefsKeys.dailyDone(_dateKey), true);

    final streak = nextDailyStreak(
      currentStreak: _prefs!.getInt(PrefsKeys.dailyStreak) ?? 0,
      lastDate: _prefs!.getString(PrefsKeys.dailyLastDate) ?? '',
      today: DateTime.now(),
    );
    _prefs!.setInt(PrefsKeys.dailyStreak, streak);
    _prefs!.setString(PrefsKeys.dailyLastDate, _dateKey);

    final agent = _prefs!.getString(PrefsKeys.playerName) ?? '';
    Notifications.reschedule(agent.toUpperCase());

    setState(() {
      _done = true;
      _dailyStreak = streak;
    });
  }

  static String _rank(int score) {
    if (score >= 100) return 'S';
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    return 'D';
  }

  static String _rankLabel(int score) {
    if (score >= 100) return 'ELITE';
    if (score >= 80) return 'EXPERT';
    if (score >= 60) return 'ADVANCED';
    if (score >= 40) return 'LEARNING';
    return 'TRAINING';
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
          backgroundColor: Colors.black, body: SizedBox.shrink());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.g2),
        title: Text('DAILY CHALLENGE', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: _alreadyDone
          ? _buildAlreadyDone()
          : _done
              ? _buildResults()
              : _buildGame(),
    );
  }

  Widget _buildGame() {
    switch (_mode) {
      case DailyMode.hexWord:
        return _buildHexWordGame();
      case DailyMode.addition:
        return _buildAdditionGame();
      case DailyMode.xor:
        return _buildXorGame();
      case DailyMode.hexMatch:
        return _buildHexMatchGame();
      case DailyMode.match:
      case DailyMode.reverse:
        return _buildBinaryGame();
    }
  }

  // ── Addition game ──────────────────────────────────────────────

  Widget _buildAdditionGame() {
    final va = _val(_addA);
    final vb = _val(_addB);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _progressGrid(),
          const Spacer(),
          _modeLabel(),
          const SizedBox(height: 14),
          Text('$_target', style: AppText.bigTarget()),
          const SizedBox(height: 4),
          Text('A > 0   +   B > 0',
              style: AppText.kicker(color: AppColors.g2)
                  .copyWith(letterSpacing: 3)),
          const SizedBox(height: 18),
          _addRow('A', _addA, va, _toggleAddA),
          const SizedBox(height: 12),
          _addRow('B', _addB, vb, _toggleAddB),
          const SizedBox(height: 16),
          if (!_solved && !_failed)
            GestureDetector(
              onTap: _triggerFail,
              child: Text('GIVE UP →',
                  style: AppText.mono(size: 11, color: AppColors.g1)),
            ),
          const SizedBox(height: 12),
          SizedBox(height: 60, child: _binaryFeedback()),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _addRow(String label, List<int> bits, int v,
      void Function(int) onToggle) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: AppText.kicker(color: AppColors.g2)
                    .copyWith(letterSpacing: 3)),
            if (_solved) ...[
              const SizedBox(width: 12),
              Text('= $v',
                  style: AppText.mono(
                      size: 16, color: AppColors.g4, weight: FontWeight.w600)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        BitRow(
            bits: bits,
            onToggle: onToggle,
            enabled: !_solved && !_failed,
            glowing: _solved),
      ],
    );
  }

  // ── XOR game ───────────────────────────────────────────────────

  Widget _buildXorGame() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _progressGrid(),
          const Spacer(),
          _modeLabel(),
          const SizedBox(height: 14),
          Text('A  ⊕  B  =  C',
              style: AppText.kicker(color: AppColors.g3)
                  .copyWith(letterSpacing: 4, fontSize: 12)),
          const SizedBox(height: 14),
          _xorFixedRow('A', _curXorA),
          const SizedBox(height: 6),
          _xorFixedRow('B', _curXorB),
          const SizedBox(height: 10),
          Container(height: 1, width: 220, color: AppColors.g1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 20,
                  child: Text('C',
                      style: AppText.kicker(color: AppColors.g2))),
              const SizedBox(width: 8),
              Expanded(
                child: BitRow(
                    bits: _curXorC,
                    onToggle: _toggleXorC,
                    enabled: !_solved && !_failed,
                    glowing: _solved),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_solved && !_failed)
            GestureDetector(
              onTap: _triggerFail,
              child: Text('GIVE UP →',
                  style: AppText.mono(size: 11, color: AppColors.g1)),
            ),
          const SizedBox(height: 12),
          SizedBox(height: 60, child: _binaryFeedback()),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _xorFixedRow(String label, List<int> bits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            width: 20,
            child: Text(label, style: AppText.kicker(color: AppColors.g2))),
        const SizedBox(width: 8),
        Expanded(
          child: BitRow(bits: bits, onToggle: (_) {}, enabled: false),
        ),
      ],
    );
  }

  // ── HEX MATCH game ─────────────────────────────────────────────

  Widget _buildHexMatchGame() {
    final bits = _toBits(_target, _qBits);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _progressGrid(),
          const Spacer(),
          _modeLabel(),
          const SizedBox(height: 14),
          if (_hmIs4bit)
            BitRow(
                bits: bits,
                onToggle: (_) {},
                enabled: false,
                glowing: _solved)
          else
            Column(children: [
              BitRow(
                  bits: bits.sublist(0, 4),
                  onToggle: (_) {},
                  enabled: false,
                  glowing: _solved),
              const SizedBox(height: 6),
              BitRow(
                  bits: bits.sublist(4),
                  onToggle: (_) {},
                  enabled: false,
                  glowing: _solved),
            ]),
          const SizedBox(height: 20),
          _hmAnswerSlots(),
          if (!_solved && !_failed && _attempts > 0) ...[
            const SizedBox(height: 6),
            Text('ATT $_attempts / 3',
                style: AppText.mono(size: 10, color: AppColors.red)),
          ],
          const SizedBox(height: 16),
          if (!_solved && !_failed) _hmKeypad(),
          SizedBox(height: 60, child: _binaryFeedback()),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _hmAnswerSlots() {
    String? hi;
    String? lo;
    if (_solved || _failed) {
      hi = _hmIs4bit ? null : _target.toRadixString(16).padLeft(2, '0')
          .substring(0, 1).toUpperCase();
      lo = _hmIs4bit
          ? _target.toRadixString(16).toUpperCase()
          : _target.toRadixString(16).padLeft(2, '0')
              .substring(1).toUpperCase();
    } else {
      hi = _hmIs4bit
          ? null
          : _hmHighEntry?.toRadixString(16).toUpperCase();
      lo = null;
    }

    if (_hmIs4bit) {
      return _hmSlot(lo, highlight: _solved || _failed);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _hmSlot(hi,
            highlight:
                _solved || _failed || (_hmHighEntry != null && !_hmWrong)),
        const SizedBox(width: 12),
        _hmSlot(lo, highlight: _solved || _failed),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: _hmBackspace,
          child: Text('←',
              style: AppText.mono(
                  size: 20,
                  color: (!_solved && !_failed && _hmHighEntry != null)
                      ? AppColors.g4
                      : AppColors.g1)),
        ),
      ],
    );
  }

  Widget _hmSlot(String? char, {bool highlight = false}) {
    final borderColor =
        _hmWrong ? AppColors.red : (highlight ? AppColors.g4 : AppColors.g2);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: highlight ? 2 : 1),
      ),
      child: Text(char ?? '_',
          style: AppText.mono(
              size: 24,
              color: char != null ? AppColors.g4 : AppColors.g1,
              weight: FontWeight.w700)),
    );
  }

  Widget _hmKeypad() {
    const labels = '0123456789ABCDEF';
    return Column(
      children: [
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 0; col < 4; col++)
                  _hmKey(labels[row * 4 + col], row * 4 + col),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hmKey(String label, int value) {
    return GestureDetector(
      onTap: () => _hmTap(value),
      child: Container(
        width: 54,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
        child: Text(label,
            style: AppText.mono(
                size: 14, color: AppColors.g4, weight: FontWeight.w600)),
      ),
    );
  }

  // ── Binary game (match + reverse) ─────────────────────────────

  Widget _buildBinaryGame() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _progressGrid(),
          const Spacer(),
          _modeLabel(),
          const SizedBox(height: 14),
          if (_mode == DailyMode.match) _matchContent(),
          if (_mode == DailyMode.reverse) _reverseContent(),
          const SizedBox(height: 20),
          SizedBox(height: 90, child: _binaryFeedback()),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _matchContent() => Column(
        children: [
          Text('$_target', style: AppText.bigTarget()),
          const SizedBox(height: 36),
          BitRow(
              bits: _bits,
              onToggle: _toggleBit,
              enabled: !_solved && !_failed,
              glowing: _solved),
          if (!_solved && !_failed) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _triggerFail,
              child: Text('GIVE UP →',
                  style: AppText.mono(size: 11, color: AppColors.g1)),
            ),
          ],
        ],
      );

  Widget _reverseContent() {
    final bits = _toBits(_target, _qBits);
    return Column(
      children: [
        BitRow(bits: bits, onToggle: (_) {}, enabled: false, glowing: _solved),
        const SizedBox(height: 24),
        _revDisplay(),
        if (!_solved && !_failed && _attempts > 0) ...[
          const SizedBox(height: 6),
          Text('ATT $_attempts / 3',
              style: AppText.mono(size: 10, color: AppColors.red)),
        ],
        const SizedBox(height: 20),
        if (!_solved && !_failed)
          NumPad(onTap: _tapDigit, activeTextColor: AppColors.g3),
      ],
    );
  }

  Widget _revDisplay() {
    final text = _failed ? '$_target' : (_revEntry.isEmpty ? '?' : _revEntry);
    final color = _failed
        ? AppColors.red
        : _revWrong
            ? AppColors.red
            : _revEntry.isEmpty
                ? AppColors.g1
                : AppColors.g4;
    return Text(text,
        style: AppText.mono(size: 52, color: color, weight: FontWeight.w700));
  }

  Widget _binaryFeedback() {
    if (!_solved && !_failed) return const SizedBox.shrink();
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('FAILED',
              style: AppText.label().copyWith(
                  fontSize: 20,
                  letterSpacing: 8,
                  color: AppColors.red,
                  shadows: AppGlow.red
                      .map((s) => Shadow(
                          color: s.color, blurRadius: s.blurRadius))
                      .toList())),
          const SizedBox(height: 8),
          Text('correct: $_target',
              style: AppText.mono(size: 11, color: AppColors.g2)),
        ],
      );
    }
    final isLast = _current + 1 >= _total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _pulseAnim,
            child: Text('CORRECT',
                style:
                    AppText.label().copyWith(fontSize: 20, letterSpacing: 8)),
          ),
        ),
        const SizedBox(height: 12),
        _nextButton(isLast: isLast),
      ],
    );
  }

  // ── HexWord game ───────────────────────────────────────────────

  Widget _buildHexWordGame() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _progressGrid(),
              const SizedBox(height: 16),
              _modeLabel(),
              const SizedBox(height: 20),
              _hwHexDisplay(),
              const SizedBox(height: 18),
              _hwLetterBoxes(),
              const SizedBox(height: 12),
              SizedBox(
                  height: 20,
                  child: _solved
                      ? Text('CORRECT',
                          style: AppText.mono(size: 13, color: AppColors.g4))
                      : _failed
                          ? Text('FAILED',
                              style: AppText.mono(
                                  size: 13, color: AppColors.red))
                          : _attempts > 0
                              ? Text('ATT $_attempts / 3',
                                  style: AppText.mono(
                                      size: 10, color: AppColors.red))
                              : null),
            ],
          ),
        ),
        const Spacer(),
        HexWordKeyboard(onTap: _tapLetter, disabled: _solved || _failed),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: (_solved || _failed)
              ? _nextButton(
                  key: const ValueKey('next'),
                  isLast: _current + 1 >= _total)
              : const SizedBox(height: 46, key: ValueKey('ph')),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
      ],
    );
  }

  Widget _hwHexDisplay() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: _hwCachedHexPairs
          .map((p) => Text(p,
              style: AppText.mono(
                  size: 20, color: AppColors.amber, weight: FontWeight.w600)))
          .toList(),
    );
  }

  Widget _hwLetterBoxes() {
    if (_word.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (ctx, constraints) {
      final boxSlot =
          (constraints.maxWidth / _word.length).clamp(0.0, 50.0);
      final boxW = (boxSlot - 4.0).clamp(0.0, 46.0);
      final fontSize = (boxW * 0.45).clamp(10.0, 18.0);

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_word.length, (i) {
          final isRev = i < _hwRevealed;
          final isCur = i == _hwRevealed && !_solved;
          final letter = isRev ? _word[i].toUpperCase() : '';
          final borderColor = isRev
              ? AppColors.g3
              : (isCur && _hwWrong)
                  ? AppColors.red
                  : isCur
                      ? AppColors.g2
                      : AppColors.g1;
          final textColor = isRev
              ? AppColors.g4
              : (isCur && _hwWrong)
                  ? AppColors.red
                  : isCur
                      ? AppColors.g2
                      : AppColors.g1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: boxW,
            height: 40,
            decoration: BoxDecoration(
              border:
                  Border.all(color: borderColor, width: isCur ? 1.5 : 1),
              boxShadow: isRev ? AppGlow.sm : null,
            ),
            alignment: Alignment.center,
            child: Text(letter,
                style: AppText.mono(
                    size: fontSize,
                    color: textColor,
                    weight: FontWeight.w700)),
          );
        }),
      );
    });
  }

  // ── Shared widgets ─────────────────────────────────────────────

  Widget _progressGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_total, (i) {
        final done = _results[i] == true;
        final isCurrent = i == _current;

        final bool failed = _results[i] == false;

        final Color borderColor;
        final Color bgColor;
        final Widget inner;
        final List<BoxShadow>? glow;

        if (failed && !isCurrent) {
          borderColor = AppColors.red;
          bgColor = AppColors.red.withValues(alpha: 0.06);
          inner = Text('✗', style: AppText.mono(size: 9, color: AppColors.red));
          glow = AppGlow.red;
        } else if (done && !isCurrent) {
          borderColor = AppColors.g3;
          bgColor = AppColors.g0;
          inner = Text('✓', style: AppText.mono(size: 9, color: AppColors.g3));
          glow = AppGlow.sm;
        } else if (isCurrent && _failed) {
          borderColor = AppColors.red;
          bgColor = AppColors.red.withValues(alpha: 0.06);
          inner = Text('✗',
              style: AppText.mono(
                  size: 9, color: AppColors.red, weight: FontWeight.w700));
          glow = AppGlow.red;
        } else if (isCurrent && _solved) {
          borderColor = AppColors.g4;
          bgColor = AppColors.g0;
          inner = Text('✓',
              style: AppText.mono(
                  size: 9, color: AppColors.g4, weight: FontWeight.w700));
          glow = AppGlow.sm;
        } else if (isCurrent) {
          borderColor = AppColors.g3;
          bgColor = Colors.transparent;
          inner =
              Text('${i + 1}', style: AppText.mono(size: 9, color: AppColors.g3));
          glow = AppGlow.sm;
        } else {
          borderColor = AppColors.g1;
          bgColor = Colors.transparent;
          inner =
              Text('${i + 1}', style: AppText.mono(size: 8, color: AppColors.g1));
          glow = null;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            color: bgColor,
            boxShadow: glow,
          ),
          alignment: Alignment.center,
          child: inner,
        );
      }),
    );
  }

  Widget _modeLabel() {
    final label = switch (_mode) {
      DailyMode.match    => 'MATCH',
      DailyMode.reverse  => 'REVERSE',
      DailyMode.hexWord  => 'HEX WORD',
      DailyMode.addition => 'ADDITION',
      DailyMode.xor      => 'XOR',
      DailyMode.hexMatch => 'HEX MATCH',
    };
    final sub =
        _mode != DailyMode.hexWord ? '$_qBits-BIT  ·  ' : '';
    return Column(
      children: [
        Text(label,
            style: AppText.kicker(color: AppColors.g3)
                .copyWith(letterSpacing: 3)),
        Text('${sub}Q${_current + 1} OF $_total',
            style: AppText.kicker(color: AppColors.g1)),
      ],
    );
  }

  Widget _nextButton({bool isLast = false, Key? key}) {
    return GestureDetector(
      key: key,
      onTap: _next,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
        child:
            Text(isLast ? 'FINISH →' : 'NEXT →', style: AppText.label()),
      ),
    );
  }

  // ── Already done ───────────────────────────────────────────────

  Widget _buildAlreadyDone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TODAY'S RESULT", style: AppText.kicker()),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.g1),
          const SizedBox(height: 32),
          Text(_rank(_bestScore),
              style: AppText.mono(
                  size: 72, color: AppColors.g4, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_rankLabel(_bestScore),
              style: AppText.mono(size: 11, color: AppColors.g2)),
          const SizedBox(height: 12),
          Text('$_bestScore / ${_total * 10}',
              style:
                  AppText.hudValue(color: AppColors.g3).copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text('DAILY STREAK  ×$_dailyStreak',
              style: AppText.mono(size: 13, color: AppColors.amber)),
          const SizedBox(height: 48),
          Text('NEXT CHALLENGE', style: AppText.kicker()),
          const SizedBox(height: 8),
          const _CountdownTimer(),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration:
                  BoxDecoration(border: Border.all(color: AppColors.g2)),
              child: Text('BACK TO MENU', style: AppText.label()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────

  Widget _buildResults() {
    final rank = _rank(_score);
    final label = _rankLabel(_score);
    final isNewBest = _score >= _bestScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHALLENGE COMPLETE', style: AppText.kicker()),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.g1),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rank,
                  style: AppText.mono(
                      size: 72,
                      color: AppColors.g4,
                      weight: FontWeight.w700)),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppText.mono(size: 11, color: AppColors.g2)),
                    const SizedBox(height: 4),
                    Text('$_score / ${_total * 10}',
                        style: AppText.hudValue(color: AppColors.g3)
                            .copyWith(fontSize: 20)),
                    if (isNewBest)
                      Text('NEW BEST',
                          style: AppText.mono(size: 9, color: AppColors.g4)),
                    const SizedBox(height: 4),
                    Text('DAILY STREAK  ×$_dailyStreak',
                        style:
                            AppText.mono(size: 11, color: AppColors.amber)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _resultsGrid(),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration:
                  BoxDecoration(border: Border.all(color: AppColors.g2)),
              child: Text('BACK TO MENU', style: AppText.label()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsGrid() {
    const modeChar = {
      DailyMode.match:    'M',
      DailyMode.reverse:  'R',
      DailyMode.hexWord:  'W',
      DailyMode.addition: 'A',
      DailyMode.xor:      'X',
      DailyMode.hexMatch: 'H',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_total, (i) {
        final q = _questions[i];
        final isFailed = _results[i] == false;
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(
                color: isFailed ? AppColors.red : AppColors.g3),
            color: isFailed
                ? AppColors.red.withValues(alpha: 0.06)
                : AppColors.g0,
            boxShadow: isFailed ? AppGlow.red : AppGlow.sm,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  isFailed ? '✗' : '✓',
                  style: AppText.mono(
                      size: 13,
                      color: isFailed ? AppColors.red : AppColors.g4,
                      weight: FontWeight.w700)),
              Text(modeChar[q.mode]!,
                  style: AppText.mono(
                      size: 7,
                      color: isFailed ? AppColors.red.withValues(alpha: 0.6) : AppColors.g2)),
            ],
          ),
        );
      }),
    );
  }
}

// Live countdown to midnight
class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer();

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  String _time = '';

  @override
  void initState() {
    super.initState();
    _time = _format();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _time = _format());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(_time,
        style:
            AppText.hudValue(color: AppColors.g3).copyWith(fontSize: 28));
  }
}
