import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/question_generator.dart';
import '../services/prefs_keys.dart';
import '../game/word_list.dart';
import '../services/haptics.dart';
import '../widgets/bit_row.dart';
import '../widgets/hex_word_keyboard.dart';
import '../widgets/new_best_banner.dart';
import '../widgets/num_pad.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _dimGreen => AppColors.g2;
Color get _muteGreen => AppColors.g1;
Color get _yellow => AppColors.amber;
Color get _red => AppColors.red;

enum _SBMode { match, reverse, addition, xor, hexWord }

extension _SBModeKey on _SBMode {
  /// The prefs mode id this Speed Burst mode stores under. Spelled out rather
  /// than derived from [name] so the on-disk ids live in one registry.
  String get prefsMode => const {
        _SBMode.match:   GameModes.speedMatch,
        _SBMode.reverse: GameModes.speedReverse,
        _SBMode.addition:GameModes.speedAddition,
        _SBMode.xor:     GameModes.speedXor,
        _SBMode.hexWord: GameModes.speedHexWord,
      }[this]!;
}

extension _SBModeLabel on _SBMode {
  String get label => const {
        _SBMode.match:   'MATCH',
        _SBMode.reverse: 'REVERSE',
        _SBMode.addition:'ADDITION',
        _SBMode.xor:     'XOR',
        _SBMode.hexWord: 'HEX WORD',
      }[this]!;

  String get subtitle => const {
        _SBMode.match:   'decimal → binary',
        _SBMode.reverse: 'binary → decimal',
        _SBMode.addition:'row_a + row_b = target',
        _SBMode.xor:     'a ⊕ b = ?',
        _SBMode.hexWord: 'ascii hex → type the word',
      }[this]!;
}

class SpeedBurstScreen extends StatefulWidget {
  const SpeedBurstScreen({super.key});

  @override
  State<SpeedBurstScreen> createState() => _SpeedBurstScreenState();
}

class _SpeedBurstScreenState extends State<SpeedBurstScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();

  bool _selecting = true;
  bool _finished = false;

  _SBMode _mode = _SBMode.match;
  QuestionGenerator? _generator;
  SharedPreferences? _prefs;

  int _timeLeft = 60;
  Timer? _countdownTimer;

  int _solved = 0;
  int _highScore = 0;
  bool _newHighScore = false;
  bool _questionSolved = false;
  bool _newBestFlash = false;
  bool _newBestFlashed = false;
  Timer? _newBestTimer;

  // Shared question target (match / reverse / addition / xor answer)
  int _target = 0;

  // Match
  List<int> _bits = [];

  // Reverse
  String _reverseEntry = '';
  bool _reverseWrong = false;

  // Addition
  List<int> _bitsA = [];
  List<int> _bitsB = [];

  // XOR
  List<int> _xorA = [];
  List<int> _xorB = [];
  List<int> _xorC = [];

  // HexWord
  List<String> _hwPool = [];
  int _hwPoolIdx = 0;
  String _hwWord = '';
  List<String> _hwCachedHexPairs = [];
  int _hwRevealed = 0;
  bool _hwWrong = false;
  Timer? _hwWrongTimer;

  late AnimationController _flashController;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _flashAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hwWrongTimer?.cancel();
    _newBestTimer?.cancel();
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _startMode(_SBMode mode) async {
    final key = mode.prefsMode;
    final prefs = await SharedPreferences.getInstance();
    QuestionGenerator? gen;
    List<String> hwPool = [];
    if (mode == _SBMode.hexWord) {
      hwPool = kWordList.where((w) => w.length <= 6).toList()..shuffle();
    } else {
      gen = await QuestionGenerator.create(
        mode: key,
        minTarget: mode == _SBMode.addition ? 2 : 0,
      );
    }
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _generator = gen;
      _prefs = prefs;
      _highScore = prefs.getInt(PrefsKeys.highScore(key)) ?? 0;
      _solved = 0;
      _timeLeft = 60;
      _questionSolved = false;
      _newHighScore = false;
      _selecting = false;
      _finished = false;
      _hwPool = hwPool;
      _hwPoolIdx = 0;
      _newBestFlash = false;
      _newBestFlashed = false;
    });
    _loadQuestion();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 1) {
        _countdownTimer?.cancel();
        _onTimeUp();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _onTimeUp() {
    final key = _mode.prefsMode;
    final isNew = _solved > _highScore;
    if (isNew) {
      _highScore = _solved;
      _prefs?.setInt(PrefsKeys.highScore(key), _highScore);
    }
    setState(() {
      _timeLeft = 0;
      _finished = true;
      _newHighScore = isNew;
    });
  }

  void _loadQuestion() {
    if (_mode == _SBMode.hexWord) {
      if (_hwPoolIdx >= _hwPool.length) {
        _hwPool.shuffle();
        _hwPoolIdx = 0;
      }
      final word = _hwPool[_hwPoolIdx++];
      final pairs = word.codeUnits
          .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
          .toList();
      setState(() {
        _questionSolved = false;
        _reverseWrong = false;
        _hwWrong = false;
        _hwWord = word;
        _hwCachedHexPairs = pairs;
        _hwRevealed = 0;
      });
      return;
    }
    final gen = _generator!;
    // next() applies a deferred tier advance, so the bit width must be read
    // after it — otherwise a boundary question renders in the previous tier's
    // width and its target cannot be represented.
    final target = gen.next();
    final bits = gen.currentBits;
    int? xorSeed;
    if (_mode == _SBMode.xor) {
      final maxVal = (1 << bits) - 1;
      xorSeed = _random.nextInt(maxVal + 1);
    }
    setState(() {
      _questionSolved = false;
      _reverseWrong = false;
      _hwWrong = false;
      _target = target;
      _reverseEntry = '';
      switch (_mode) {
        case _SBMode.match:
          _bits = List.filled(bits, 0);
        case _SBMode.reverse:
          _bits = _toBits(target, bits);
        case _SBMode.addition:
          _bitsA = List.filled(bits, 0);
          _bitsB = List.filled(bits, 0);
        case _SBMode.xor:
          _xorA = _toBits(xorSeed!, bits);
          _xorB = _toBits(xorSeed ^ target, bits);
          _xorC = List.filled(bits, 0);
        case _SBMode.hexWord:
          break;
      }
    });
  }

  void _tapHwLetter(String letter) {
    if (_questionSolved || _finished || _hwWord.isEmpty) return;
    if (letter == _hwWord[_hwRevealed].toUpperCase()) {
      Haptics.selectionClick();
      setState(() => _hwRevealed++);
      if (_hwRevealed == _hwWord.length) _onCorrect();
    } else {
      Haptics.lightImpact();
      _hwWrongTimer?.cancel();
      setState(() => _hwWrong = true);
      _hwWrongTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _hwWrong = false);
      });
    }
  }

  void _onCorrect() {
    if (_questionSolved || _finished) return;
    Haptics.mediumImpact();
    setState(() {
      _questionSolved = true;
      _solved++;
    });
    _flashController.forward(from: 0);
    _generator?.recordSolved();
    if (_mode == _SBMode.hexWord) {
      final total = (_prefs?.getInt(PrefsKeys.hexWordTotal) ?? 0) + 1;
      _prefs?.setInt(PrefsKeys.hexWordTotal, total);
    }
    final speedKey = PrefsKeys.correctCount(_mode.prefsMode);
    _prefs?.setInt(speedKey, (_prefs?.getInt(speedKey) ?? 0) + 1);
    if (!_newBestFlashed && _highScore > 0 && _solved > _highScore) {
      _newBestFlashed = true;
      _newBestTimer?.cancel();
      setState(() => _newBestFlash = true);
      _newBestTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _newBestFlash = false);
      });
    }
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && !_finished) _loadQuestion();
    });
  }

  List<int> _toBits(int v, int n) =>
      List.generate(n, (i) => (v >> (n - 1 - i)) & 1);

  int _val(List<int> b) {
    int v = 0;
    for (int i = 0; i < b.length; i++) {
      v += b[i] * (1 << (b.length - 1 - i));
    }
    return v;
  }

  void _toggleMatch(int i) {
    if (_questionSolved || _finished) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_bits)..[i] ^= 1;
    setState(() => _bits = nb);
    if (_val(nb) == _target) _onCorrect();
  }

  void _toggleAddA(int i) {
    if (_questionSolved || _finished) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_bitsA)..[i] ^= 1;
    setState(() => _bitsA = nb);
    if (_val(nb) + _val(_bitsB) == _target) _onCorrect();
  }

  void _toggleAddB(int i) {
    if (_questionSolved || _finished) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_bitsB)..[i] ^= 1;
    setState(() => _bitsB = nb);
    if (_val(_bitsA) + _val(nb) == _target) _onCorrect();
  }

  void _toggleXorC(int i) {
    if (_questionSolved || _finished) return;
    Haptics.selectionClick();
    final nb = List<int>.from(_xorC)..[i] ^= 1;
    setState(() => _xorC = nb);
    if (_val(nb) == _target) _onCorrect();
  }

  void _tapReverseDigit(String d) {
    if (_questionSolved || _finished) return;
    if (d == '⌫') {
      if (_reverseEntry.isNotEmpty) {
        setState(() => _reverseEntry = _reverseEntry.substring(0, _reverseEntry.length - 1));
      }
      return;
    }
    final next = _reverseEntry + d;
    final input = int.tryParse(next);
    if (input == _target) {
      _reverseEntry = next;
      _onCorrect();
    } else if (next.length >= _target.toString().length) {
      setState(() { _reverseWrong = true; _reverseEntry = ''; });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _reverseWrong = false);
      });
    } else {
      setState(() => _reverseEntry = next);
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_selecting) return _selectScreen();
    if (_finished) return _finishedScreen();
    return _playScreen();
  }

  AppBar _appBar() => AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: _dimGreen),
        title: Text('SPEED BURST',
            style: TextStyle(color: _green, fontSize: 15, letterSpacing: 4)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _muteGreen),
        ),
      );

  // ── Mode select ────────────────────────────────────────────────

  Widget _selectScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _appBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('SELECT MODE',
                style: TextStyle(
                    fontSize: 10, color: _dimGreen, letterSpacing: 5)),
            const SizedBox(height: 4),
            Text('60 SECONDS  ·  MAXIMIZE SOLVED',
                style: TextStyle(
                    fontSize: 10, color: _muteGreen, letterSpacing: 2)),
            const SizedBox(height: 32),
            for (final m in _SBMode.values) ...[
              _modeItem(m),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeItem(_SBMode m) {
    return GestureDetector(
      onTap: () => _startMode(m),
      child: Row(
        children: [
          Text('[${m.index + 1}]',
              style: TextStyle(
                  color: _green, fontSize: 13, letterSpacing: 1)),
          const SizedBox(width: 14),
          // The longest subtitle ("row_a + row_b = target") does not fit a
          // narrow phone unless the label column can give way.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _green, fontSize: 15, letterSpacing: 3)),
                Text(m.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _dimGreen, fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Play ───────────────────────────────────────────────────────

  Widget _playScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _appBar(),
      body: Stack(
        children: [
          _playBody(),
          IgnorePointer(
            child: FadeTransition(
              opacity: _flashAnim,
              child: Container(color: const Color(0x3300FF41)),
            ),
          ),
          if (_questionSolved)
            IgnorePointer(
              child: Center(
                child: Text('+1',
                    style: TextStyle(
                        fontSize: 52,
                        color: _green.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold)),
              ),
            ),
          NewBestBanner(visible: _newBestFlash),
        ],
      ),
    );
  }

  Widget _playBody() {
    final hud = [
      const SizedBox(height: 12),
      _timerSection(),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('SOLVED  ',
            style: TextStyle(fontSize: 10, color: _dimGreen, letterSpacing: 3)),
        Text('$_solved', style: TextStyle(fontSize: 20, color: _green)),
      ]),
    ];

    if (_mode == _SBMode.hexWord) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [...hud, const SizedBox(height: 20), _hwHexDisplay(), const SizedBox(height: 14), _hwLetterBoxes()]),
        ),
        const Spacer(),
        HexWordKeyboard(onTap: _tapHwLetter, disabled: _questionSolved, rowPadding: 2),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 14),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ...hud,
        const Spacer(),
        _gameContent(),
        const Spacer(),
      ]),
    );
  }

  Widget _timerSection() {
    final Color c = _timeLeft > 15
        ? _green
        : _timeLeft > 5
            ? _yellow
            : _red;
    return Column(
      children: [
        Text('$_timeLeft',
            style: TextStyle(
                fontSize: 52,
                color: c,
                fontWeight: FontWeight.bold,
                height: 1.0)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _timeLeft / 60.0,
          backgroundColor: _muteGreen,
          valueColor: AlwaysStoppedAnimation<Color>(c),
          minHeight: 2,
        ),
      ],
    );
  }

  Widget _gameContent() {
    switch (_mode) {
      case _SBMode.match:
        return _matchUI();
      case _SBMode.reverse:
        return _reverseUI();
      case _SBMode.addition:
        return _additionUI();
      case _SBMode.xor:
        return _xorUI();
      case _SBMode.hexWord:
        return const SizedBox.shrink();
    }
  }

  Widget _hwHexDisplay() {
    if (_hwWord.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: _hwCachedHexPairs
          .map((p) => Text(p,
              style: AppText.mono(
                  size: 20, color: AppColors.amber, weight: FontWeight.w600)))
          .toList(),
    );
  }

  Widget _hwLetterBoxes() {
    if (_hwWord.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (ctx, constraints) {
      final boxSlot =
          (constraints.maxWidth / _hwWord.length).clamp(0.0, 50.0);
      final boxW = (boxSlot - 4.0).clamp(0.0, 46.0);
      final fontSize = (boxW * 0.45).clamp(10.0, 18.0);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_hwWord.length, (i) {
          final isRev = i < _hwRevealed;
          final isCur = i == _hwRevealed && !_questionSolved;
          final borderColor = isRev
              ? AppColors.g3
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
              border: Border.all(color: borderColor, width: isCur ? 1.5 : 1),
              boxShadow: isRev ? AppGlow.sm : null,
            ),
            alignment: Alignment.center,
            child: Text(
              isRev ? _hwWord[i].toUpperCase() : '',
              style: AppText.mono(
                  size: fontSize,
                  color: isRev ? AppColors.g4 : borderColor,
                  weight: FontWeight.w700),
            ),
          );
        }),
      );
    });
  }

  Widget _matchUI() => Column(children: [
        Text('TARGET',
            style:
                TextStyle(fontSize: 11, color: _dimGreen, letterSpacing: 5)),
        const SizedBox(height: 4),
        Text('$_target',
            style: TextStyle(
                fontSize: 64,
                color: _green,
                fontWeight: FontWeight.bold,
                height: 1.0)),
        const SizedBox(height: 20),
        BitRow(
            bits: _bits,
            onToggle: _toggleMatch,
            enabled: !_questionSolved,
            glowing: _questionSolved),
      ]);

  Widget _reverseUI() => Column(children: [
        Text('DECODE',
            style:
                TextStyle(fontSize: 11, color: _dimGreen, letterSpacing: 5)),
        const SizedBox(height: 16),
        BitRow(bits: _bits, onToggle: (_) {}, enabled: false),
        const SizedBox(height: 16),
        Text(
          _reverseEntry.isEmpty ? '?' : _reverseEntry,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: _reverseWrong
                ? _red
                : (_reverseEntry.isEmpty ? _dimGreen : _green),
          ),
        ),
        const SizedBox(height: 12),
        NumPad(
          onTap: _tapReverseDigit,
          disabled: _questionSolved,
          keyWidth: 62,
          keyHeight: 40,
          hMargin: 4,
          rowPadding: 4,
        ),
      ]);

  Widget _additionUI() {
    final vA = _val(_bitsA), vB = _val(_bitsB);
    return Column(children: [
      Text('TARGET',
          style: TextStyle(fontSize: 11, color: _dimGreen, letterSpacing: 5)),
      const SizedBox(height: 4),
      Text('$_target',
          style: TextStyle(
              fontSize: 56,
              color: _green,
              fontWeight: FontWeight.bold,
              height: 1.0)),
      const SizedBox(height: 16),
      _addRowUI('A', _bitsA, vA, _toggleAddA),
      const SizedBox(height: 10),
      _addRowUI('B', _bitsB, vB, _toggleAddB),
    ]);
  }

  Widget _addRowUI(String lbl, List<int> bits, int v,
      void Function(int) onToggle) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(lbl,
            style:
                TextStyle(fontSize: 11, color: _dimGreen, letterSpacing: 2)),
        const SizedBox(width: 8),
        Text('= $v',
            style: TextStyle(fontSize: 16, color: _dimGreen)),
      ]),
      const SizedBox(height: 4),
      BitRow(
          bits: bits,
          onToggle: onToggle,
          enabled: !_questionSolved,
          glowing: _questionSolved),
    ]);
  }

  Widget _xorUI() {
    final vC = _val(_xorC);
    return Column(children: [
      Text('A  ⊕  B  =  C',
          style:
              TextStyle(fontSize: 12, color: _dimGreen, letterSpacing: 3)),
      const SizedBox(height: 14),
      _xorRowUI('A', _xorA),
      const SizedBox(height: 6),
      _xorRowUI('B', _xorB),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(height: 1, width: 260, color: _muteGreen),
      ),
      Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
              width: 20,
              child: Text('C',
                  style: TextStyle(
                      fontSize: 11, color: _dimGreen, letterSpacing: 2))),
          const SizedBox(width: 8),
          Expanded(
            child: BitRow(
                bits: _xorC,
                onToggle: _toggleXorC,
                enabled: !_questionSolved,
                glowing: _questionSolved),
          ),
        ]),
        const SizedBox(height: 6),
        Text('= $vC',
            style: TextStyle(fontSize: 16, color: _dimGreen)),
      ]),
    ]);
  }

  Widget _xorRowUI(String lbl, List<int> bits) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
          width: 20,
          child: Text(lbl,
              style: TextStyle(
                  fontSize: 11, color: _dimGreen, letterSpacing: 2))),
      const SizedBox(width: 8),
      Expanded(
        child: BitRow(bits: bits, onToggle: (_) {}, enabled: false),
      ),
    ]);
  }

  // ── Finished ───────────────────────────────────────────────────

  Widget _finishedScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _appBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("TIME'S UP",
                style: TextStyle(
                    fontSize: 16, color: _dimGreen, letterSpacing: 6)),
            const SizedBox(height: 20),
            Text('$_solved',
                style: TextStyle(
                    fontSize: 96,
                    color: _green,
                    fontWeight: FontWeight.bold,
                    height: 1.0)),
            Text('SOLVED',
                style: TextStyle(
                    fontSize: 11, color: _dimGreen, letterSpacing: 5)),
            const SizedBox(height: 28),
            if (_newHighScore)
              Text('NEW BEST  ▲',
                  style: TextStyle(
                      fontSize: 13, color: _green, letterSpacing: 4))
            else
              Text('BEST  $_highScore',
                  style: TextStyle(
                      fontSize: 13, color: _dimGreen, letterSpacing: 3)),
            const SizedBox(height: 44),
            _btn('PLAY AGAIN', _green, () => _startMode(_mode)),
            const SizedBox(height: 14),
            _btn('CHANGE MODE', _dimGreen,
                () => setState(() {
                      _selecting = true;
                      _finished = false;
                    })),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Text(label,
            style: TextStyle(
                fontSize: 14, color: color, letterSpacing: 4)),
      ),
    );
  }
}
