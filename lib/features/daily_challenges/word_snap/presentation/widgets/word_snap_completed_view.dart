import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_top_bar.dart';

/// Screen view displayed when today's Word Snap challenge has been completed.
class WordSnapCompletedView extends StatelessWidget {
  final WordSnapPuzzle? puzzle;
  final int streak;
  final Color primaryColor;
  final SoundService soundService;
  final HapticService hapticService;
  final VoidCallback onPracticeAgain;
  final bool isPracticeMode;

  const WordSnapCompletedView({
    super.key,
    required this.puzzle,
    required this.streak,
    required this.primaryColor,
    required this.soundService,
    required this.hapticService,
    required this.onPracticeAgain,
    this.isPracticeMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final word = puzzle?.word ?? '';
    final def = puzzle?.cleanDefinition ?? '';

    return Column(
      children: [
        WordSnapTopBar(streak: streak),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 16.h,
            ).copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 24.h,
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),

                // Success icon badge
                Container(
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.emerald500,
                        Color(0xFF059669),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald500.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 38.r,
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  isPracticeMode
                      ? context.tr(
                          'vocabulary.practice_complete',
                          fallback: 'Practice Complete!',
                        )
                      : context.tr(
                          'home.already_completed_title',
                          fallback: 'Challenge Complete!',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  isPracticeMode
                      ? context.tr(
                          'vocabulary.practice_complete_desc',
                          fallback: 'Well done! Keep practicing to strengthen your vocabulary.',
                        )
                      : context.tr(
                          'home.come_back_tomorrow',
                          fallback: 'Come back tomorrow for a new challenge!',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),

                // Solved Word & Meaning Card
                if (word.isNotEmpty) ...[
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  word,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            IconButton(
                              onPressed: () {
                                hapticService.selection();
                                soundService.playTts(word.toLowerCase());
                              },
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: primaryColor,
                                size: 22.r,
                              ),
                              tooltip: 'Listen to pronunciation',
                            ),
                          ],
                        ),
                        // ESL Badges (POS + CEFR)
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 4.h,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (puzzle?.partOfSpeech != null && puzzle!.partOfSpeech.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  puzzle!.partOfSpeech.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            if (puzzle?.cefrLevel != null && puzzle!.cefrLevel.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.amber500.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  'CEFR ${puzzle!.cefrLevel}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.amber500,
                                  ),
                                ),
                              ),
                            if (puzzle != null && (puzzle!.hasPhonetic || puzzle!.hasSyllables))
                              Text(
                                puzzle!.displayPhonetic,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                        if (def.isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Text(
                            def,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.45,
                            ),
                          ),
                        ],
                        if (puzzle != null && puzzle!.hasExample) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '"${puzzle!.exampleSentence}"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontStyle: FontStyle.italic,
                                fontSize: 13.sp,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                        if (puzzle != null && puzzle!.hasSynonyms) ...[
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            alignment: WrapAlignment.center,
                            children: puzzle!.synonyms.map((s) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                        if (puzzle != null && puzzle!.tags.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            alignment: WrapAlignment.center,
                            children: puzzle!.tags.map((tag) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Streak Card
                if (streak > 0) ...[
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.amber500.withValues(alpha: 0.12),
                          AppColors.red500.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 26.sp)),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$streak ${context.tr('home.day_streak', fallback: 'Day Streak')}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.slate900,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                context.tr(
                                  'home.keep_it_going',
                                  fallback: 'Keep it going!',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 24.h),

                // Practice Again Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      hapticService.selection();
                      onPracticeAgain();
                    },
                    icon: Icon(Icons.refresh_rounded, color: primaryColor),
                    label: Text(
                      context.tr('games.practice_another', fallback: 'Practice Another Word'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Return Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.tr('games.back_to_home', fallback: 'Back to Home'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
