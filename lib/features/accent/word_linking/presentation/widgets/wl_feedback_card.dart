import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class WLFeedbackCard extends StatelessWidget {
  final AccentQuest quest;
  final bool isDark;
  final bool isMidnight;
  final ThemeResult theme;
  final bool isCorrect;
  final bool isLastQuestion;
  final VoidCallback onPlayAudio;
  final VoidCallback onContinue;

  const WLFeedbackCard({
    super.key,
    required this.quest,
    required this.isDark,
    required this.theme,
    required this.isCorrect,
    this.isLastQuestion = false,
    required this.onPlayAudio,
    required this.onContinue,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final correctOption = quest.options?[quest.correctAnswerIndex ?? 0] ?? "";
    final words = (quest.word ?? "").split(" ");

    String transformation = "";
    if (words.length >= 2) {
      transformation =
          "${words[0].trim()} + ${words[1].trim()} → ${correctOption.replaceAll('|', '')}";
    }

    return Column(
      children: [
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.greenAccent.withValues(alpha: 0.05)
                : theme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isCorrect
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : theme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: isCorrect ? Colors.greenAccent : theme.primaryColor,
                    size: 24.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isCorrect ? "✔ CORRECT" : "LEARN LINKING",
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: isCorrect
                          ? Colors.greenAccent
                          : theme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (transformation.isNotEmpty)
                Column(
                  children: [
                    Text(
                      transformation,
                      style: GoogleFonts.outfit(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Connected Speech",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.amber,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        quest.hint ??
                            "In English, we often link the end of one word with the beginning of the next for smoother speech.",
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCorrect) ...[
                SizedBox(height: 16.h),
                ScaleButton(
                  onTap: onPlayAudio,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          color: theme.primaryColor,
                          size: 18.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "LISTEN AGAIN",
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: theme.primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        if (!isLastQuestion) ...[
          SizedBox(height: 24.h),
          ScaleButton(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "CONTINUE",
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
        ],
      ],
    );
  }
}
