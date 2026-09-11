import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioTrueFalseInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const AudioTrueFalseInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    String mainText = instruction;
    String subText = '';

    final match = RegExp(r'([.?!])\s+(.*)').firstMatch(instruction);
    if (match != null) {
      mainText = instruction.substring(0, match.start + 1);
      subText = match.group(2) ?? '';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          mainText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
        if (subText.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            subText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
