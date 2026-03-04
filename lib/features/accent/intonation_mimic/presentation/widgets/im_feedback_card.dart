import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';

class ImFeedbackCard extends StatelessWidget {
  final AccentQuest quest;
  final String word;
  final String? ipa;
  final String? tip;
  final ThemeResult theme;
  final bool isCorrect;

  const ImFeedbackCard({
    super.key,
    required this.quest,
    required this.word,
    required this.ipa,
    required this.tip,
    required this.theme,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(28.r),
      borderColor: (isCorrect ? const Color(0xFF10B981) : Colors.amber)
          .withValues(alpha: 0.3),
      color: (isCorrect ? const Color(0xFF10B981) : Colors.amber).withValues(
        alpha: 0.05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.stars_rounded : Icons.lightbulb_rounded,
                color: isCorrect ? const Color(0xFF10B981) : Colors.amber,
                size: 24.r,
              ),
              SizedBox(width: 12.w),
              Text(
                isCorrect ? "EXCELLENT!" : "HINT",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isCorrect ? const Color(0xFF10B981) : Colors.amber,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (quest.hint != null)
            Text(
              quest.hint!,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
          if (tip != null) ...[
            SizedBox(height: 12.h),
            Divider(color: theme.primaryColor.withValues(alpha: 0.1)),
            SizedBox(height: 12.h),
            Text(
              "PRO TIP",
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: theme.primaryColor.withValues(alpha: 0.7),
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              tip!,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
