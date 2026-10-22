import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SyllableStressInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const SyllableStressInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  String _formatInstruction(String raw) {
    final text = raw.trim();
    if (text.isEmpty ||
        text.toUpperCase().contains('STRIKE THE DRUM') ||
        text.toUpperCase().contains('CONTAINING THE STRESSED SYLLABLE')) {
      return 'Tap the stressed syllable';
    }
    if (text.toUpperCase().contains('RECORD YOURSELF SAYING THE WORD') ||
        text.toUpperCase().contains('GREAT JOB! NOW RECORD')) {
      return 'Speak the word with the correct stress';
    }
    // If text is in all-caps, convert to readable sentence case
    if (text == text.toUpperCase() && text.length > 8) {
      final lower = text.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = _formatInstruction(instruction);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.graphic_eq_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              cleanText,
              textAlign: TextAlign.center,
              maxLines: null,
              softWrap: true,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.graphic_eq_rounded,
            size: 16.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
