import 'package:flutter/material.dart';

class GameScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const GameScrollbar({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RawScrollbar(
      controller: controller,
      thumbColor: isDark ? Colors.white24 : Colors.black26,
      radius: const Radius.circular(8),
      thickness: 3,
      fadeDuration: const Duration(milliseconds: 300),
      timeToFade: const Duration(milliseconds: 1000),
      interactive: true,
      child: child,
    );
  }
}
