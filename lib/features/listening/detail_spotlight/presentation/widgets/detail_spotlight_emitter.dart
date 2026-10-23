import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Central sound emitter button node for the detail spotlight challenge.
class DetailSpotlightEmitter extends StatelessWidget {
  /// Callback triggered when the emitter button is tapped.
  final VoidCallback onTap;

  /// Theme accent color.
  final Color color;

  /// Optional celebratory emoji revealed upon correct choice.
  final String? emoji;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Creates a [DetailSpotlightEmitter] button.
  const DetailSpotlightEmitter({
    super.key,
    required this.onTap,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Semantics(
      label: 'Play audio detail',
      button: true,
      excludeSemantics: true,
      child: ScaleButton(
        key: const Key('detail_spotlight_emitter_btn'),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12.r,
                spreadRadius: 2.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isCorrectState == true && emoji != null
              ? (reduceMotion
                  ? Text(
                      emoji!,
                      key: const Key('detail_spotlight_emoji'),
                      style: TextStyle(fontSize: 32.r),
                    )
                  : Text(
                      emoji!,
                      key: const Key('detail_spotlight_emoji'),
                      style: TextStyle(fontSize: 32.r),
                    )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutCubic))
              : Icon(Icons.volume_up_rounded, color: color, size: 36.r),
        ),
      ),
    );
  }
}
