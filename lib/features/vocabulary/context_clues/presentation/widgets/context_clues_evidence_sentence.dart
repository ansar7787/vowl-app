import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContextCluesEvidenceSentence extends StatelessWidget {
  final String sentence;
  final Color color;
  final bool isCompact;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;

  const ContextCluesEvidenceSentence({
    super.key,
    required this.sentence,
    required this.color,
    required this.isCompact,
    required this.isAnswered,
    this.isCorrect,
    this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    final parts = sentence.split("[TARGET]");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 15.w : 30.w),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            _buildTextSpan(parts[0]),
            WidgetSpan(
              child: _buildRedactedBlock(),
              alignment: PlaceholderAlignment.middle,
            ),
            if (parts.length > 1) _buildTextSpan(parts[1]),
          ],
        ),
      ),
    );
  }

  TextSpan _buildTextSpan(String text) {
    final words = text.split(" ");
    return TextSpan(
      children: words.map((word) {
        return TextSpan(
          text: "$word ",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCompact ? 14.sp : 20.sp,
            height: isCompact ? 1.3 : 1.6,
            color: Colors.black.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRedactedBlock() {
    if (isAnswered) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isCorrect == true
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          border: Border.all(
            color: isCorrect == true ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Text(
          selectedOption?.toUpperCase() ?? "???",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCompact ? 14.sp : 20.sp,
            fontWeight: FontWeight.bold,
            color: isCorrect == true ? Colors.green : Colors.red,
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
    }

    return Container(
          width: isCompact ? 70.w : 100.w,
          height: isCompact ? 18.h : 24.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(2.r),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white10);
  }
}
