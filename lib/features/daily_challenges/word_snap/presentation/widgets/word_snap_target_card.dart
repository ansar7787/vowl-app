import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';

/// Redesigned target word card for the Word Snap challenge.
///
/// Clean visual hierarchy:
/// 1. Top Badges: Category badge + Difficulty / CEFR level
/// 2. Hero Word: Bold typography + Tactile TTS pronunciation button
/// 3. Metadata Pills: Part of speech, letter count, words to assemble count
/// 4. Action Prompt: Educational context
class WordSnapTargetCard extends StatelessWidget {
  final WordSnapPuzzle puzzle;
  final Color primaryColor;
  final SoundService soundService;
  final HapticService hapticService;

  const WordSnapTargetCard({
    super.key,
    required this.puzzle,
    required this.primaryColor,
    required this.soundService,
    required this.hapticService,
  });

  double _getAdaptiveFontSize(int length) {
    if (length >= 14) return 20.sp;
    if (length >= 11) return 24.sp;
    if (length >= 8) return 28.sp;
    return 32.sp;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final length = puzzle.letterCount;

    final cardBgGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF2E081D).withValues(alpha: 0.55),
              const Color(0xFF0F172A).withValues(alpha: 0.78),
            ]
          : [
              Colors.white,
              const Color(0xFFFDF2F8),
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
          // ── 1. Top Header Row: Category Badge + Difficulty/CEFR ───────────
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
                        Icons.extension_rounded,
                        color: primaryColor,
                        size: 14.r,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr('home.daily_challenge', fallback: 'DAILY CHALLENGE'),
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

              // Difficulty & CEFR Pill
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
                      '${puzzle.cefrLevel} • ${puzzle.difficultyLabel.toUpperCase()}',
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

          // ── 2. Hero Target Word + Audio Pronunciation ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    puzzle.word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: _getAdaptiveFontSize(length),
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // Audio Pronunciation Button
              Semantics(
                label: 'Listen to pronunciation of ${puzzle.word}',
                button: true,
                child: ScaleButton(
                  onTap: () {
                    hapticService.selection();
                    soundService.playTts(puzzle.word.toLowerCase());
                  },
                  child: Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: primaryColor,
                        size: 20.r,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (puzzle.hasPhonetic || puzzle.hasSyllables) ...[
            SizedBox(height: 4.h),
            Text(
              puzzle.displayPhonetic,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.black45,
                letterSpacing: 0.5,
              ),
            ),
          ],

          SizedBox(height: 14.h),

          // ── 3. Metadata Badges (POS + Letters + Words count) ──────────────
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
                  '$length ${context.tr('home.letters', fallback: 'letters')}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

              // Word count to assemble badge
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
                  '${puzzle.playableWords.length} words to assemble',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
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
