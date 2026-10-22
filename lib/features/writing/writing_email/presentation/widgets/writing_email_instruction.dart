import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class WritingEmailInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final String? formalityLevel;

  const WritingEmailInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.formalityLevel,
  });

  String _cleanInstruction(String raw) {
    final trimmed = raw.trim();
    // If text is shouting in ALL-CAPS from curriculum, normalize to clean sentence case
    if (trimmed.length > 4 && trimmed == trimmed.toUpperCase()) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final baseText = context.tr(
      'games.writingEmail_instruction',
      fallback: instruction != null
          ? _cleanInstruction(instruction!)
          : "Put the email parts in the correct order.",
    );
    final fullText = formalityLevel != null
        ? '$baseText (${formalityLevel!.toUpperCase()})'
        : baseText;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 1.2,
        ),
      ),
      child: Text(
        fullText,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          height: 1.35,
        ),
      ),
    );
  }
}
