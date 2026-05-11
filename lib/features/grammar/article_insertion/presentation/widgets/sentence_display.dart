import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'article_blank.dart';

class SentenceDisplay extends StatelessWidget {
  final String text;
  final String correctAnswer;
  final bool? isAnsweredCorrectly;
  final bool isDark;
  final Color primaryColor;

  const SentenceDisplay({
    super.key,
    required this.text,
    required this.correctAnswer,
    this.isAnsweredCorrectly,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!text.contains("___")) {
      return Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      );
    }

    final parts = text.split("___");
    final prefix = parts[0].trim();
    final suffix = parts.length > 1 ? parts[1].trim() : "";

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.w,
      runSpacing: 12.h,
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ArticleBlank(
          correctAnswer: correctAnswer,
          isAnsweredCorrectly: isAnsweredCorrectly,
          primaryColor: primaryColor,
        ),
        if (suffix.isNotEmpty)
          Text(
            suffix,
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
      ],
    );
  }
}
