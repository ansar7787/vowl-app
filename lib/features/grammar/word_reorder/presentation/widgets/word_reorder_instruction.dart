import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WordReorderInstruction extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

  const WordReorderInstruction({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  String _formatInstruction(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.toUpperCase() == 'REORDER WORDS') {
      return 'Put the words in the right order';
    }
    // If the text is screaming in all-caps, convert to clean sentence case
    if (text == text.toUpperCase() && text.length > 1) {
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _formatInstruction(instruction);

    return Container(
      key: const ValueKey('word_reorder_instruction'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.sort_rounded, size: 16.sp, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
