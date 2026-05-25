import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';

class SpeechContextCard extends StatelessWidget {
  final GrammarQuest quest;
  final Color primaryColor;
  final bool isDark;

  const SpeechContextCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(22.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          children: [
            if (quest.sentence != null) ...[
              Text(
                quest.sentence!,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                quest.question ?? "Identify the function",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}
