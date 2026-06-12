import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A rotating radial-gradient vortex that acts as a drag-target bucket.
///
/// [index] (0–3) is now used to stagger rotation speeds so the four vortices
/// move at slightly different rates — previously it was accepted but never
/// read, making it dead code.
///
/// Accessibility: labeled as a drop zone so screen readers can identify it.
class SpeechVortex extends StatelessWidget {
  final int index;
  final String label;
  final Color color;
  final Alignment alignment;
  final bool isCompact;

  const SpeechVortex({
    super.key,
    required this.index,
    required this.label,
    required this.color,
    required this.alignment,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: index now drives the rotation speed — was unused before.
    // Each vortex rotates at a different rate (2600ms → 4200ms) for visual
    // richness and to avoid synchronised motion.
    final rotationMs = 2600 + index * 400;
    final size = isCompact ? 85.r : 120.r;
    final margin = isCompact ? 4.r : 10.r;

    return Align(
      alignment: alignment,
      child: Semantics(
        label: '${label.toUpperCase()} drop zone',
        child: Container(
          width: size,
          height: size,
          margin: EdgeInsets.all(margin),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.6),
                          color.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: Duration(milliseconds: rotationMs)),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 8.sp : 10.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
