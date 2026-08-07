import 'package:flutter/material.dart';

class GameScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const GameScrollbar({super.key, required this.child, this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RawScrollbar(
      controller: controller,
      thumbColor: isDark ? Colors.white24 : Colors.black26,
      radius: const Radius.circular(10),
      thickness: 4,
      mainAxisMargin: 24,
      minThumbLength: 36,
      interactive: true,
      child: child,
    );
  }
}
