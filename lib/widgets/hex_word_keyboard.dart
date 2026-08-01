import 'package:flutter/material.dart';
import '../theme.dart';

class HexWordKeyboard extends StatelessWidget {
  final void Function(String) onTap;
  final bool disabled;
  final double rowPadding;

  const HexWordKeyboard({
    super.key,
    required this.onTap,
    this.disabled = false,
    this.rowPadding = 3,
  });

  static const _keyRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static const _keyMargin = 2.0;
  static const _maxKeyWidth = 32.0;
  static const _keyHeight = 42.0;

  @override
  Widget build(BuildContext context) {
    // The top row is the widest at ten keys; at the preferred 32px that needs
    // 360px, which does not fit a 320px phone. Size the keys to the row that
    // has the most of them so every row stays aligned and nothing overflows.
    final widestRow = _keyRows
        .map((r) => r.length)
        .reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth.isFinite
            ? constraints.maxWidth / widestRow
            : _maxKeyWidth + _keyMargin * 2;
        final keyWidth = (slot - _keyMargin * 2)
            .clamp(18.0, _maxKeyWidth)
            .toDouble();
        final textSize = (keyWidth * 0.375).clamp(9.0, 12.0);

        return Column(
          children: _keyRows
              .map(
                (row) => Padding(
                  padding: EdgeInsets.symmetric(vertical: rowPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row
                        .map(
                          (l) => Semantics(
                            button: true,
                            enabled: !disabled,
                            label: l,
                            excludeSemantics: true,
                            onTap: disabled ? null : () => onTap(l),
                            child: GestureDetector(
                              onTap: () => onTap(l),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: _keyMargin,
                                ),
                                width: keyWidth,
                                height: _keyHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: disabled
                                        ? AppColors.g1
                                        : AppColors.g2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  l,
                                  style: AppText.mono(
                                    size: textSize,
                                    color: disabled
                                        ? AppColors.g1
                                        : AppColors.g3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
