import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// A rotating radial-gradient vortex that acts as a drag-target bucket.
///
/// [index] (0–3) is now used to stagger rotation speeds so the four vortices
/// move at slightly different rates — previously it was accepted but never
/// read, making it dead code.
///
/// Accessibility: labeled as a drop zone so screen readers can identify it.
class SpeechVortex extends StatelessWidget {
  /// The index position of this vortex (0–3).
  final int index;

  /// The category label for the part of speech.
  final String label;

  /// The accent color associated with this vortex category.
  final Color color;

  /// The alignment position of the vortex on screen.
  final Alignment alignment;

  /// Whether compact dimensions should be used for small screens.
  final bool isCompact;

  /// Optional callback invoked when the vortex is tapped.
  final VoidCallback? onTap;

  /// Creates a [SpeechVortex] widget.
  const SpeechVortex({
    super.key,
    required this.index,
    required this.label,
    required this.color,
    required this.alignment,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rotationMs = 2600 + index * 400;
    final size = isCompact ? 85.r : 115.r;
    final margin = isCompact ? 6.r : 12.r;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final circle = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        key: ValueKey('speech_vortex_$index'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
          label: '${label.toUpperCase()} category',
          child: Container(
            width: size,
            height: size,
            margin: EdgeInsets.all(margin),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (reduceMotion)
                  circle
                else
                  circle
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: Duration(milliseconds: rotationMs)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isCompact ? 11.sp : 13.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
