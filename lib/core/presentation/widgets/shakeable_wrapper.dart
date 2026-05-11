import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShakeableWrapper extends StatelessWidget {
  final int shakeCount;
  final Widget child;

  const ShakeableWrapper({
    super.key,
    required this.shakeCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(shakeCount),
      effects: shakeCount > 0
          ? [
              ShakeEffect(
                hz: 10,
                offset: const Offset(6, 0),
                duration: 400.ms,
              ),
              TintEffect(
                color: Colors.red.withValues(alpha: 0.05),
                duration: 400.ms,
              ),
            ]
          : [],
      child: child,
    );
  }
}
