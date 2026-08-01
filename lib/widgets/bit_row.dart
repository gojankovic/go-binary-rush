import 'package:flutter/material.dart';
import 'bit_tile.dart';
import '../theme.dart';

class BitRow extends StatelessWidget {
  final List<int> bits;
  final void Function(int index) onToggle;
  final bool enabled;
  final bool glowing;
  final bool showLabels;

  const BitRow({
    super.key,
    required this.bits,
    required this.onToggle,
    this.enabled = true,
    this.glowing = false,
    this.showLabels = false,
  });

  static const _supers = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷'];

  double _tileSize(int n) {
    if (n <= 4) return 64;
    if (n <= 5) return 56;
    if (n <= 6) return 48;
    if (n <= 7) return 42;
    return 36;
  }

  @override
  Widget build(BuildContext context) {
    final int n = bits.length;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double fallback = _tileSize(n);
        final double ts = constraints.maxWidth.isFinite
            ? ((constraints.maxWidth / n) - 8).clamp(20.0, fallback)
            : fallback;
        final double colWidth = ts + 8;
        final double labelSize = (ts * 0.2).clamp(10, 14);
        final double exponentSize = (ts * 0.17).clamp(9, 12);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                n,
                (i) => BitTile(
                  value: bits[i],
                  onTap: () => onToggle(i),
                  enabled: enabled,
                  glowing: glowing,
                  size: ts,
                  semanticLabel: 'bit worth ${1 << (n - 1 - i)}',
                ),
              ),
            ),
            if (showLabels) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(n, (i) {
                  final int power = n - 1 - i;
                  return SizedBox(
                    width: colWidth,
                    child: Column(
                      children: [
                        Text(
                          '${1 << power}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: labelSize,
                            color: AppColors.g2,
                          ),
                        ),
                        Text(
                          '2${_supers[power]}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: exponentSize,
                            color: AppColors.g1,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}
