import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TenseMasteryInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const TenseMasteryInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  String get _displayInstruction {
    final text = instruction?.trim();
    if (text == null || text.isEmpty) {
      return "Select the correct tense";
    }
    // Normalize legacy/buzzwordy prompts if present
    final lower = text.toLowerCase();
    if (lower.contains("timeline") || lower.contains("shift through time")) {
      return "Select the correct tense";
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _displayInstruction,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, size: 16.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                _displayInstruction,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.3,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
