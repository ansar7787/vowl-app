import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Instruction header displaying gameplay rules for the describe situation writing exercise.
class DescribeSituationInstruction extends StatelessWidget {
  /// The primary theme accent color for icons and accents.
  final Color primaryColor;

  /// Optional fallback instruction text describing the exercise rules.
  final String? instruction;

  /// Creates a [DescribeSituationInstruction] widget.
  const DescribeSituationInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = context.tr(
      'games.describeSituationWriting_instruction',
      fallback:
          instruction ?? "Tap the emojis to reveal keywords, then describe the situation.",
    );

    return Semantics(
      label: 'Instruction: $displayText',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.edit_note_rounded,
                size: 20.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
                  ),
                ),
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: null,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    letterSpacing: 0.2,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Balanced spacer icon so text is geometrically centered
            ExcludeSemantics(
              child: Icon(
                Icons.edit_note_rounded,
                size: 20.r,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
