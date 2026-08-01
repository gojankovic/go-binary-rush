import 'package:flutter/material.dart';
import '../theme.dart';

class NumPad extends StatelessWidget {
  final void Function(String) onTap;
  final bool disabled;
  final double keyWidth;
  final double keyHeight;
  final double hMargin;
  final double rowPadding;
  final Color? activeTextColor;

  const NumPad({
    super.key,
    required this.onTap,
    this.disabled = false,
    this.keyWidth = 70,
    this.keyHeight = 44,
    this.hMargin = 6,
    this.rowPadding = 6,
    this.activeTextColor,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['⌫', '0', ''],
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = disabled ? AppColors.g1 : AppColors.g2;
    final textColor = disabled
        ? AppColors.g1
        : (activeTextColor ?? AppColors.g4);
    final textSize = (keyHeight * 0.41).clamp(14.0, 20.0);
    return Column(
      children: _rows
          .map(
            (row) => Padding(
              padding: EdgeInsets.only(bottom: rowPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row
                    .map(
                      (d) => d.isEmpty
                          ? SizedBox(width: keyWidth + hMargin * 2)
                          : Semantics(
                              button: true,
                              enabled: !disabled,
                              label: d == '⌫' ? 'backspace' : d,
                              excludeSemantics: true,
                              onTap: disabled ? null : () => onTap(d),
                              child: GestureDetector(
                                onTap: disabled ? null : () => onTap(d),
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: hMargin,
                                  ),
                                  width: keyWidth,
                                  height: keyHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    d,
                                    style: AppText.mono(
                                      size: textSize,
                                      color: textColor,
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
  }
}
