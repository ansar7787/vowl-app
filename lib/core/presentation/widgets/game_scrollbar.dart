import 'package:flutter/material.dart';

/// Custom interactive scrollbar with theme-adaptive styling.
class GameScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final Color? thumbColor;
  final double? thickness;

  const GameScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbColor,
    this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RawScrollbar(
      controller: controller,
      thumbColor: thumbColor ?? (isDark ? Colors.white24 : Colors.black26),
      radius: const Radius.circular(10),
      thickness: thickness ?? 4,
      mainAxisMargin: 24,
      minThumbLength: 36,
      interactive: true,
      child: child,
    );
  }
}
