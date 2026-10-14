import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

/// Redesigned production target card for Word Mixer.
///
/// Features:
/// 1. Top Badges: Category pill + Difficulty badge (flexible, zero overflow)
/// 2. Mystery Word Slot Hero: Visual preview of the unscramble target
/// 3. Metadata Pills: Part of speech, letter count, CEFR level
class WordMixerInfoCard extends StatelessWidget {
  final WordMixerPuzzle puzzle;
  final bool isPracticeMode;
  final Color primaryColor;

  const WordMixerInfoCard({
    super.key,
    required this.puzzle,
    this.isPracticeMode = false,
    this.primaryColor = IllustrationColors.richPurple,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF26123D).withValues(alpha: 0.65),
              const Color(0xFF0F172A).withValues(alpha: 0.85),
            ]
          : [
              Colors.white,
              const Color(0xFFFAF5FF),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: cardBgGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. Top Header Row: Category Badge + Difficulty Pill ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Challenge Badge
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shuffle_rounded,
                        color: primaryColor,
                        size: 14.r,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isPracticeMode
                                ? context.tr('home.practice_round', fallback: 'Practice Round')
                                : context.tr('home.daily_challenge', fallback: 'DAILY CHALLENGE'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Difficulty Pill (displays HARD, MEDIUM, etc.)
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
                  decoration: BoxDecoration(
                    color: puzzle.difficultyColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: puzzle.difficultyColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      puzzle.difficultyLabel.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: puzzle.difficultyColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── 2. Mystery Word Hero Indicator ────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.15),
                width: 1.w,
              ),
            ),
            child: Column(
              children: [
                // Mystery slot representations
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      puzzle.letterCount,
                      (index) => Container(
                        width: 28.r,
                        height: 36.r,
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 1.2.w,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr(
                      'home.unscramble_word',
                      fallback: 'Unscramble the letters to form the word',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ── 3. ESL Metadata Badges (POS + Letter count + CEFR) ─────────────
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              // Part of Speech Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  puzzle.partOfSpeech.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // Letter Count Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  '${puzzle.letterCount} ${context.tr('home.letters', fallback: 'letters')}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

              // CEFR Level Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.25),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  'CEFR ${puzzle.cefrLevel}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber500,
                  ),
                ),
              ),

              // Phonetic / Syllables Chip if available
              if (puzzle.hasPhonetic || puzzle.hasSyllables)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.emerald500.withValues(alpha: 0.25),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    puzzle.displayPhonetic,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
