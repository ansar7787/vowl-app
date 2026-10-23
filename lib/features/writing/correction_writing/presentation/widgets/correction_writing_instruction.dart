import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Instruction badge displayed at the top of the Correction Writing challenge.
class CorrectionWritingInstruction extends StatelessWidget {
  /// Raw instruction prompt text.
  final String instruction;

  /// Theme accent color.
  final Color primaryColor;

  /// Creates a [CorrectionWritingInstruction] badge.
  const CorrectionWritingInstruction({
    super.key,
    required this.instruction,
    required this.primaryColor,
  });

  String _cleanInstruction(BuildContext context) {
    final raw = context.tr(
      'games.correctionWriting_instruction',
      fallback: instruction,
    );
    final lower = raw.trim().toLowerCase();
    // Replace robotic/academic phrasing with natural, clear human English
    if (lower == 'correct the grammatical error in the sentence.' ||
        lower.isEmpty) {
      return 'Find and fix the mistake in the sentence.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _cleanInstruction(context);

    return Semantics(
      label: 'Instruction: $displayText',
      child: Container(
        key: const Key('correction_writing_instruction'),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: null,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
              letterSpacing: 0.1,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

