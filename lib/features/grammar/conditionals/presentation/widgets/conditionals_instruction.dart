import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConditionalsInstruction extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

  const ConditionalsInstruction({
    super.key,
    required this.primaryColor,
    this.instruction = "Select the correct result",
  });

  static String _formatInstruction(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toUpperCase() == "FUSE THE CONSEQUENCE") {
      return "Select the correct result";
    }
    // If text is in ALL CAPS, convert to readable sentence case
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 2) {
      final lower = trimmed.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _formatInstruction(instruction);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 15.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.2,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
