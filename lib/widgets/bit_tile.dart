import 'package:flutter/material.dart';
import '../theme.dart';

Color get _active => AppColors.g4;
Color get _activeBg => AppColors.g0;
Color get _inactiveBorder => AppColors.g1;
Color get _inactiveText => AppColors.g2;

class BitTile extends StatefulWidget {
  final int value;
  final VoidCallback onTap;
  final bool glowing;
  final double size;

  /// What this tile is called to a screen reader. [BitRow] passes the bit's
  /// place value, which is the only thing that distinguishes one tile from
  /// the next.
  final String semanticLabel;

  const BitTile({
    super.key,
    required this.value,
    required this.onTap,
    this.glowing = false,
    this.size = 64,
    this.semanticLabel = 'bit',
  });

  @override
  State<BitTile> createState() => _BitTileState();
}

class _BitTileState extends State<BitTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool on = widget.value == 1;
    final double fontSize = widget.size * 0.47;

    return Semantics(
      button: true,
      toggled: on,
      label: widget.semanticLabel,
      value: on ? '1' : '0',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: _tile(on, fontSize),
    );
  }

  Widget _tile(bool on, double fontSize) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.82 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? _activeBg : Colors.black,
            border: Border.all(
              color: on ? _active : _inactiveBorder,
              width: on ? 2 : 1,
            ),
            boxShadow: (on && widget.glowing) ? AppGlow.md : null,
          ),
          child: Text(
            widget.value.toString(),
            style: TextStyle(
              fontSize: fontSize,
              color: on ? _active : _inactiveText,
              fontWeight: on ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
