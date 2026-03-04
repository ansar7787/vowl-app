import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';

class ConsonantFeedbackPanel extends StatelessWidget {
  final AccentQuest quest;
  final bool isCorrect;
  final VoidCallback onPlayAgain;
  final bool isDark;
  final ThemeResult theme;

  const ConsonantFeedbackPanel({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.onPlayAgain,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    final hint = quest.hint ?? "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: statusColor,
                size: 32.r,
              ),
              SizedBox(width: 12.w),
              Text(
                isCorrect ? "CORRECT!" : "NOT QUITE",
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            "${quest.word?.replaceAll('[', '').replaceAll(']', '')} → ${quest.correctAnswer ?? quest.options?[quest.correctAnswerIndex ?? 0]}",
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (hint.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: theme.primaryColor,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "PEDAGOGICAL HINT",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    hint,
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24.h),
          _buildThroatTest(isDark),
          SizedBox(height: 24.h),
          ScaleButton(
            onTap: onPlayAgain,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    "LISTEN AGAIN",
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildThroatTest(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Colors.blue),
              SizedBox(width: 8.w),
              Text(
                "THROAT TEST",
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "Touch your throat while speaking. If it vibrates, it's voiced. If not, it's unvoiced.",
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
