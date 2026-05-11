import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'vowel_length_visualizer.dart';

class VowelFeedbackPanel extends StatelessWidget {
  final AccentQuest quest;
  final bool isCorrect;
  final bool isDark;
  final bool isMidnight;
  final ThemeResult theme;

  const VowelFeedbackPanel({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
    this.isMidnight = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isCorrect
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
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
                        : Icons.cancel_rounded,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isCorrect ? "Correct!" : "Not quite",
                    style: GoogleFonts.outfit(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                "${quest.word1} → ${quest.ipa1 ?? ''}",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                "${quest.word2} → ${quest.ipa2 ?? ''}",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (quest.hint != null) ...[
                SizedBox(height: 12.h),
                Text(
                  "💡 ${quest.hint}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: isDark ? Colors.lightBlueAccent : Colors.blue,
                  ),
                ),
              ],
              if (quest.mouthPosition != null) ...[
                SizedBox(height: 8.h),
                Text(
                  "👄 ${quest.mouthPosition}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: isDark ? Colors.amber : Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn().scale(),
        SizedBox(height: 20.h),
        VowelLengthVisualizer(quest: quest, theme: theme),
      ],
    );
  }
}
