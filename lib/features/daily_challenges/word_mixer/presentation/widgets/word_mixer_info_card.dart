import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

/// Redesigned production info banner displaying CEFR level, Part of Speech,
/// difficulty metrics, and pedagogical orthography clues.
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Icon + Title + Difficulty
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.sort_by_alpha_rounded,
                  color: primaryColor,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPracticeMode
                          ? context.tr('home.practice_round', fallback: 'Practice Round')
                          : context.tr('home.daily_challenge', fallback: 'Daily Challenge'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr(
                        'home.unscramble_word',
                        fallback: 'Unscramble the letters to find the word',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Difficulty Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: puzzle.difficultyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: puzzle.difficultyColor.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  puzzle.difficultyLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: puzzle.difficultyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // ESL Educational Metrics Chips Row
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Part of Speech Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  puzzle.partOfSpeech.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // CEFR Level Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
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

              // Letter Count Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${puzzle.letterCount} ${context.tr('home.letters', fallback: 'letters')}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, duration: 400.ms);
  }
}
