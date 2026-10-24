import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction header pill at the top of the situation speaking game screen.
class SituationSpeakingHeader extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Specific pedagogical instruction text.
  final String instruction;

  /// Creates a [SituationSpeakingHeader].
  const SituationSpeakingHeader({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        key: const Key('situation_speaking_header'),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.record_voice_over_rounded,
              size: 15.r,
              color: primaryColor,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                instruction.toUpperCase(),
                key: const Key('situation_speaking_header_text'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: 0.8,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
