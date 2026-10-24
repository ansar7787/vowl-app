import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// =============================================================================
// AudioFillBlanksInstruction
// =============================================================================

/// Instruction badge displayed at the top of the Audio Fill Blanks game screen.
class AudioFillBlanksInstruction extends StatelessWidget {
  /// Prompt text instructing the player what action to take.
  final String instruction;

  /// Theme accent color applied to the badge border and text.
  final Color color;

  /// Creates an [AudioFillBlanksInstruction] badge.
  const AudioFillBlanksInstruction({
    super.key,
    required this.instruction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: instruction,
      excludeSemantics: true, // children already covered by parent label
      child: Container(
        constraints: BoxConstraints(maxWidth: 360.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              instruction,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.35,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Swipe or tap to uncover the sentence',
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.75),
                height: 1.3,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
