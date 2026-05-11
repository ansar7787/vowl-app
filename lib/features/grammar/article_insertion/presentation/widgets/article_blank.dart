import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ArticleBlank extends StatelessWidget {
  final String correctAnswer;
  final bool? isAnsweredCorrectly;
  final Color primaryColor;

  const ArticleBlank({
    super.key,
    required this.correctAnswer,
    this.isAnsweredCorrectly,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = isAnsweredCorrectly == true;

    return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isCorrect
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isCorrect
                  ? const Color(0xFF10B981)
                  : primaryColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              if (isAnsweredCorrectly == null)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Text(
            isCorrect ? correctAnswer : "?",
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: isCorrect ? const Color(0xFF10B981) : primaryColor,
            ),
          ),
        )
        .animate(target: isCorrect ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 200.ms,
        )
        .then()
        .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1));
  }
}
