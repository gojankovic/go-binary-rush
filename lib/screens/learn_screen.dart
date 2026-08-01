import 'package:flutter/material.dart';
import '../game/binary.dart';
import '../theme.dart';
import '../widgets/bit_row.dart';
import 'main_shell.dart';

class LearnScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const LearnScreen({super.key, this.isFirstLaunch = false});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;
  static const int _steps = 6;
  static const int _practiceTarget = 6;

  List<int> _bits = List.filled(4, 0);
  bool _practiceDone = false;

  void _toggleBit(int i) {
    if (_practiceDone) return;
    final nb = List<int>.from(_bits)..[i] ^= 1;
    setState(() => _bits = nb);
    if (bitsToInt(nb) == _practiceTarget) setState(() => _practiceDone = true);
  }

  void _nextPage() {
    if (_step < _steps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      setState(() => _step++);
    }
  }

  void _prevPage() {
    if (_step > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      setState(() => _step--);
    }
  }

  void _begin() {
    if (widget.isFirstLaunch) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const MainShell(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, a2, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: !widget.isFirstLaunch,
        iconTheme: IconThemeData(color: AppColors.g2),
        title: Text('LEARN', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _stepIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _page0(),
                _page1(),
                _page2(),
                _page3(),
                _page4(),
                _page5(),
              ],
            ),
          ),
          _bottomBar(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _stepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps, (i) {
        final active = i == _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 28 : 8,
          height: 4,
          color: active ? AppColors.g4 : AppColors.g1,
        );
      }),
    );
  }

  Widget _bottomBar() {
    final isLast = _step == _steps - 1;
    if (isLast) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: GestureDetector(
              onTap: _practiceDone ? _begin : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _practiceDone ? AppColors.g4 : AppColors.g1,
                    width: 1.5,
                  ),
                  boxShadow: _practiceDone ? AppGlow.sm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.isFirstLaunch ? 'BEGIN  →' : 'DONE  →',
                  style: AppText.mono(
                    size: 14,
                    color: _practiceDone ? AppColors.g4 : AppColors.g1,
                    weight: FontWeight.w600,
                  ).copyWith(letterSpacing: 4),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _prevPage,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Center(
                child: Text(
                  '← back',
                  style: AppText.kicker(color: AppColors.g1),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.g2),
              ),
              alignment: Alignment.center,
              child: Text('NEXT  →', style: AppText.label()),
            ),
          ),
        ),
        GestureDetector(
          onTap: _step > 0 ? _prevPage : (widget.isFirstLaunch ? _begin : null),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Center(
              child: Text(
                _step > 0
                    ? '← back'
                    : (widget.isFirstLaunch ? 'skip introduction →' : ''),
                style: AppText.kicker(color: AppColors.g1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pages ─────────────────────────────────────────────────────

  Widget _page0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT IS BINARY?',
            style: AppText.mono(
              size: 17,
              color: AppColors.g4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _para('Computers store everything as 0s and 1s.'),
          _para('Each 0 or 1 is called a BIT.'),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [0, 1, 0, 1].map((v) {
              final on = v == 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: on ? AppColors.g4 : AppColors.g1,
                    width: on ? 2 : 1,
                  ),
                  color: on ? AppColors.g0 : Colors.transparent,
                  boxShadow: on ? AppGlow.sm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$v',
                  style: AppText.mono(
                    size: 24,
                    color: on ? AppColors.g4 : AppColors.g1,
                    weight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          _para('A group of 4 bits represents values from 0 to 15.'),
          _para('In this game you read, write, and decode binary numbers.'),
        ],
      ),
    );
  }

  Widget _page1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POSITIONAL VALUES',
            style: AppText.mono(
              size: 17,
              color: AppColors.g4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _para('Each bit position has a fixed value — a power of 2:'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _posBox('8', '2³'),
              _posBox('4', '2²'),
              _posBox('2', '2¹'),
              _posBox('1', '2⁰'),
            ],
          ),
          const SizedBox(height: 28),
          _para('Leftmost bit = largest value.'),
          _para('Each position is double the one to its right:'),
          _para('  1 → 2 → 4 → 8 → 16 → 32 → ...'),
          const SizedBox(height: 12),
          _para('When a bit is ON  (1) → add its value.'),
          _para('When a bit is OFF (0) → add nothing.'),
        ],
      ),
    );
  }

  Widget _page2() {
    const exBits = [0, 1, 1, 0];
    const values = [8, 4, 2, 1];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXAMPLE: 6 IN BINARY',
            style: AppText.mono(
              size: 17,
              color: AppColors.g4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _para('To represent 6, turn on the bits that add up to 6:'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final on = exBits[i] == 1;
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: on ? AppColors.g4 : AppColors.g1,
                        width: on ? 2 : 1,
                      ),
                      color: on ? AppColors.g0 : Colors.transparent,
                      boxShadow: on ? AppGlow.sm : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${exBits[i]}',
                      style: AppText.mono(
                        size: 24,
                        color: on ? AppColors.g4 : AppColors.g1,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    on ? '+${values[i]}' : '  ×  ',
                    style: AppText.mono(
                      size: 12,
                      color: on ? AppColors.g3 : AppColors.g1,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '4 + 2 = 6',
              style: AppText.mono(
                size: 22,
                color: AppColors.g4,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _para('0×8 + 1×4 + 1×2 + 0×1 = 4 + 2 = 6'),
          _para('Only the ON bits contribute their values.'),
        ],
      ),
    );
  }

  Widget _page3() {
    const nibbles = [
      ('0000', '0'),
      ('0001', '1'),
      ('0010', '2'),
      ('0011', '3'),
      ('0100', '4'),
      ('0101', '5'),
      ('0110', '6'),
      ('0111', '7'),
      ('1000', '8'),
      ('1001', '9'),
      ('1010', 'A'),
      ('1011', 'B'),
      ('1100', 'C'),
      ('1101', 'D'),
      ('1110', 'E'),
      ('1111', 'F'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEXADECIMAL',
            style: AppText.mono(
              size: 17,
              color: AppColors.g4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _para('Hex uses 16 symbols instead of 10:'),
          _para('  0 1 2 3 4 5 6 7 8 9 A B C D E F'),
          _para('A=10, B=11, C=12, D=13, E=14, F=15'),
          const SizedBox(height: 20),
          _para('4 bits fit exactly into one hex digit:'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: nibbles.map((n) {
              final isAlpha = int.tryParse(n.$2) == null;
              return Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isAlpha ? AppColors.g2 : AppColors.g1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      n.$1,
                      style: AppText.mono(size: 9, color: AppColors.g2),
                    ),
                    Text(
                      '= ${n.$2}',
                      style: AppText.mono(
                        size: 9,
                        color: isAlpha ? AppColors.amber : AppColors.g3,
                        weight: isAlpha ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _para('Example:  1010 1111  →  AF  →  175'),
        ],
      ),
    );
  }

  Widget _page4() {
    const examples = [
      ('H', '72', '48'),
      ('e', '101', '65'),
      ('l', '108', '6C'),
      ('l', '108', '6C'),
      ('o', '111', '6F'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASCII',
            style: AppText.mono(
              size: 17,
              color: AppColors.g4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _para('ASCII assigns a number to every character.'),
          _para('Each number fits in 8 bits = 2 hex digits.'),
          const SizedBox(height: 20),
          _para('Example — the word "Hello":'),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(56),
              2: FixedColumnWidth(56),
            },
            children: [
              TableRow(
                children: [_tHead('CHAR'), _tHead('DEC'), _tHead('HEX')],
              ),
              ...examples.map(
                (e) => TableRow(
                  children: [
                    _tCell(e.$1, AppColors.g4),
                    _tCell(e.$2, AppColors.g2),
                    _tCell(e.$3, AppColors.amber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _para('In HEX WORD mode you see the hex pairs'),
          _para('and decode the hidden word letter by letter.'),
        ],
      ),
    );
  }

  Widget _page5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR TURN',
            style: AppText.mono(
              size: 17,
              color: AppColors.g4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _para('Toggle the bits to match the target number.'),
          const SizedBox(height: 28),
          Center(child: Text('$_practiceTarget', style: AppText.bigTarget())),
          const SizedBox(height: 28),
          BitRow(
            bits: _bits,
            onToggle: _toggleBit,
            enabled: !_practiceDone,
            glowing: _practiceDone,
            showLabels: true,
          ),
          const SizedBox(height: 28),
          Center(
            child: AnimatedOpacity(
              opacity: _practiceDone ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                'CORRECT!  YOU ARE READY.',
                style: AppText.mono(
                  size: 12,
                  color: AppColors.g4,
                  weight: FontWeight.w600,
                ).copyWith(letterSpacing: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posBox(String val, String exp) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
      child: Column(
        children: [
          Text(
            val,
            textAlign: TextAlign.center,
            style: AppText.mono(
              size: 18,
              color: AppColors.g3,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exp,
            textAlign: TextAlign.center,
            style: AppText.mono(size: 10, color: AppColors.g1),
          ),
        ],
      ),
    );
  }

  Widget _tHead(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AppText.mono(size: 9, color: AppColors.g1)),
  );

  Widget _tCell(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: AppText.mono(size: 12, color: color, weight: FontWeight.w600),
    ),
  );

  Widget _para(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppText.mono(size: 12, color: AppColors.g2)),
    );
  }
}
