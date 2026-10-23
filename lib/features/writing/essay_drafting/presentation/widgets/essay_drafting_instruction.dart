import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner presenting the drafting task requirements.
class EssayDraftingInstruction extends StatelessWidget {
  /// The primary theme accent color for borders and text highlights.
  final Color primaryColor;

  /// Instruction text guiding the essay drafting activity.
  final String instruction;

  /// Creates an [EssayDraftingInstruction] widget.
  const EssayDraftingInstruction({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
      ),
      child: Text(
        instruction,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: isDark ? Colors.white.withValues(alpha: 0.95) : primaryColor,
        ),
      ),
    );
  }
}
