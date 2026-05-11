import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class WLPhraseDisplay extends StatelessWidget {
  final AccentQuest quest;
  final ThemeResult theme;
  final bool isDark;
  final bool isPlaying;
  final bool isMidnight;

  const WLPhraseDisplay({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    required this.isPlaying,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    // Split phrase to show each word clearly
    final words = (quest.word ?? "").split(" ");
    final correctOption = quest.options?[quest.correctAnswerIndex ?? 0] ?? "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (quest.phoneticHint != null && quest.phoneticHint!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                "[ ${quest.phoneticHint} ]",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24.w,
            runSpacing: 12.h,
            children: words.map((word) {
              return Text(
                word,
                style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 1.5,
                ),
              );
            }).toList(),
          ),
          if (isPlaying && words.length >= 2) ...[
            SizedBox(height: 24.h),
            Column(
              children: [
                Icon(
                      Icons.arrow_downward_rounded,
                      color: theme.primaryColor.withValues(alpha: 0.5),
                      size: 24.r,
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .moveY(
                      begin: -5,
                      end: 5,
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    )
                    .fadeIn(),
                SizedBox(height: 8.h),
                Text(
                  correctOption.replaceAll('|', ''),
                  style: GoogleFonts.outfit(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: theme.primaryColor,
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }
}
