import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';

class ImSoundCard extends StatelessWidget {
  final String word;
  final String? ipa;
  final String? tip;
  final ThemeResult theme;
  final bool isPlaying;
  final int listensRemaining;
  final bool slowMode;
  final bool hasAnswered;
  final bool isCorrectAnswer;
  final VoidCallback onPlayAudio;
  final VoidCallback onSlowModeToggle;

  const ImSoundCard({
    super.key,
    required this.word,
    required this.ipa,
    required this.tip,
    required this.theme,
    required this.isPlaying,
    required this.listensRemaining,
    required this.slowMode,
    required this.hasAnswered,
    required this.isCorrectAnswer,
    required this.onPlayAudio,
    required this.onSlowModeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassTile(
      padding: EdgeInsets.all(28.r),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: hasAnswered
          ? (isCorrectAnswer
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : const Color(0xFFF43F5E).withValues(alpha: 0.5))
          : theme.primaryColor.withValues(alpha: 0.3),
      color: isDark
          ? theme.primaryColor.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.5),
      child: Column(
        children: [
          // Listen Button Row (Normal + Slow + Counter)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              // Main Listen Button
              ScaleButton(
                onTap: listensRemaining > 0 ? onPlayAudio : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: listensRemaining > 0
                        ? LinearGradient(
                            colors: [
                              theme.primaryColor.withValues(alpha: 0.9),
                              theme.primaryColor,
                            ],
                          )
                        : null,
                    color: listensRemaining > 0
                        ? null
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: listensRemaining > 0
                        ? [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying)
                        HarmonicWaves(
                          color: Colors.white,
                          height: 24.h,
                          width: 40.w,
                        ).animate().fadeIn()
                      else
                        Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 22.r,
                        ),
                      SizedBox(width: 8.w),
                      Text(
                        "LISTEN",
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Slow Mode Toggle
              ScaleButton(
                onTap: onSlowModeToggle,
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: slowMode
                        ? theme.primaryColor.withValues(alpha: 0.2)
                        : (isDark ? Colors.white10 : Colors.black12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: slowMode ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text("🐢", style: TextStyle(fontSize: 18.sp)),
                ),
              ),

              // Listen counter
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      size: 14.r,
                      color: listensRemaining > 0
                          ? theme.primaryColor
                          : Colors.grey,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "×$listensRemaining",
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: listensRemaining > 0
                            ? theme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Word Display (with shake on wrong)
          Builder(
            builder: (context) {
              final wordWidget = Text(
                word,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w900,
                  color: hasAnswered && !isCorrectAnswer
                      ? const Color(0xFFF43F5E)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  letterSpacing: 4,
                ),
              );

              if (hasAnswered && !isCorrectAnswer) {
                return wordWidget
                    .animate(onPlay: (c) => c.forward())
                    .shake(hz: 4, offset: const Offset(8, 0), duration: 500.ms);
              }
              return wordWidget;
            },
          ),

          // IPA Badge
          if (ipa != null) ...[
            SizedBox(height: 12.h),
            Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    ipa!,
                    style: GoogleFonts.notoSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ],

          // Slow mode indicator
          if (slowMode) ...[
            SizedBox(height: 8.h),
            Text(
              "🐢 Slow mode ON",
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}
