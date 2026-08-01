import 'package:flutter/material.dart';
import '../widgets/bit_row.dart';
import '../theme.dart';

Color get _green => AppColors.g4;
Color get _dimGreen => AppColors.g2;
Color get _muteGreen => AppColors.g1;
Color get _yellow => AppColors.amber;

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  List<int> _toBits(int value, int n) =>
      List.generate(n, (i) => (value >> (n - 1 - i)) & 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('REFERENCE', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _muteGreen),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('PLACE VALUES'),
            const SizedBox(height: 12),
            _placeValues(),
            const SizedBox(height: 32),
            _section('4-BIT TABLE  (0 – 15)'),
            const SizedBox(height: 12),
            _fourBitTable(),
            const SizedBox(height: 32),
            _section('XOR TRUTH TABLE'),
            const SizedBox(height: 12),
            _xorTable(),
            const SizedBox(height: 32),
            _section('HEX WORD  ·  ASCII  a – z'),
            const SizedBox(height: 12),
            _asciiTable(),
            const SizedBox(height: 8),
            Text('hex pair  →  letter  (lowercase, UTF-8)',
                style: TextStyle(
                    fontSize: 9, color: _dimGreen, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 10, color: _dimGreen, letterSpacing: 4)),
        const SizedBox(height: 6),
        Container(height: 1, color: _muteGreen),
      ],
    );
  }

  Widget _placeValues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int bits = 4; bits <= 8; bits += 1) ...[
          Text('$bits-bit',
              style: TextStyle(
                  fontSize: 11, color: _dimGreen, letterSpacing: 1)),
          const SizedBox(height: 6),
          BitRow(
            bits: List.filled(bits, 1),
            onToggle: (_) {},
            enabled: false,
            showLabels: true,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _fourBitTable() {
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: List.generate(16, (i) {
        final bits = _toBits(i, 4);
        final bitStr = bits.join('');
        return SizedBox(
          width: 130,
          // The cell width is fixed so the columns line up; scale the row down
          // rather than overflow it when the glyphs are wider than assumed.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
            children: [
              Text(bitStr,
                  style: TextStyle(
                      fontSize: 15, color: _green, letterSpacing: 3)),
              Text('  =  ',
                  style: TextStyle(fontSize: 13, color: _dimGreen)),
              Text('$i',
                  style: TextStyle(fontSize: 15, color: _green)),
            ],
            ),
          ),
        );
      }),
    );
  }

  Widget _asciiTable() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(26, (i) {
        final code = 0x61 + i;
        final hex = code.toRadixString(16).toUpperCase();
        final char = String.fromCharCode(code);
        return SizedBox(
          width: 68,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(hex,
                    style: TextStyle(
                        fontSize: 13, color: _yellow, letterSpacing: 1)),
                Text('  $char',
                    style: TextStyle(
                        fontSize: 13, color: _green, letterSpacing: 1)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _xorTable() {
    const pairs = [
      [0, 0, 0],
      [0, 1, 1],
      [1, 0, 1],
      [1, 1, 0],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in pairs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${row[0]}  ⊕  ${row[1]}  =  ${row[2]}',
              style: TextStyle(
                  fontSize: 18, color: _green, letterSpacing: 4),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'XOR = 1 when bits differ,  0 when equal',
          style: TextStyle(fontSize: 10, color: _dimGreen, letterSpacing: 1),
        ),
      ],
    );
  }
}
