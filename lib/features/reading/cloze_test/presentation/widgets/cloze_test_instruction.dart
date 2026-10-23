import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner presenting guidelines for the cloze test exercise.
class ClozeTestInstruction extends StatelessWidget {
  /// The primary theme accent color for borders and icons.
  final Color primaryColor;

  /// Optional fallback instruction text describing the cloze test.
  final String? instruction;

  /// Creates a [ClozeTestInstruction] widget.
  const ClozeTestInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = (instruction ?? '').trim();
    final displayText = raw.isNotEmpty
        ? raw
        : 'Choose the correct word to complete the sentence.';

    return Semantics(
      header: true,
      label: displayText,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 340.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 16.r,
                color: primaryColor,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : (primaryColor == Colors.white
                            ? const Color(0xFF1E293B)
                            : primaryColor),
                    height: 1.35,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
