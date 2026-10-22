import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeedVarianceInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const SpeedVarianceInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  String _cleanInstruction(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return "Listen and identify the speaking speed";
    }
    // Clean up robotic or AI phrasing if encountered
    if (text.toLowerCase().contains("confirm by speaking")) {
      return "Now say the sentence aloud";
    }
    // Normalize all-caps to clean sentence case for professional feel
    if (text == text.toUpperCase() && text.length > 3 && !text.contains('/')) {
      final lower = text.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = _cleanInstruction(instruction);

    return Container(
      constraints: BoxConstraints(maxWidth: 380.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.speed_rounded, size: 16.r, color: color),
          SizedBox(width: 10.w),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Text(
                cleanText,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: null,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.2,
                  height: 1.3,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Symmetrical invisible icon to guarantee true visual centering even when text wraps onto 2 lines
          Icon(Icons.speed_rounded, size: 16.r, color: Colors.transparent),
        ],
      ),
    );
  }
}
