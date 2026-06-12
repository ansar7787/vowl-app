import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays a single instruction line for a grammar quest.
///
/// The `isMidnight` parameter that previously appeared here has been removed
/// because it was accepted in the constructor but never read in the build
/// method. If midnight-theme conditioning is needed in the future, add it back
/// alongside the actual implementation.
class GrammarInstruction extends StatelessWidget {
  final String instruction;
  final Color primaryColor;
  final bool isDark;

  const GrammarInstruction({
    super.key,
    required this.instruction,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Instruction: $instruction',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: primaryColor, size: 20.r),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                instruction,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.2),
    );
  }
}
