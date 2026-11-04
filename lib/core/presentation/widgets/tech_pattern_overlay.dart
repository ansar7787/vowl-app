import 'package:flutter/material.dart';

/// Clean overlay component.
///
/// Previously rendered a dense 4px crosshatch grid (~400+ canvas line draws per card)
/// which created visual clutter and moiré noise on mobile displays.
/// Now returns [SizedBox.shrink] so prompt cards stay clean, distraction-free,
/// and high-contrast while maintaining 100% backward compatibility.
class TechPatternOverlay extends StatelessWidget {
  final double opacity;
  final Color color;

  const TechPatternOverlay({
    super.key,
    this.opacity = 0.05,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
