import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

/// Post-completion view displaying mastery metrics, word pronunciation, definition review, and practice mode entry.
class WordMixerCompletedView extends StatelessWidget {
  final WordMixerPuzzle? puzzle;
  final int streak;
  final VoidCallback onGoBack;
  final VoidCallback onPracticeMore;
  final Color primaryColor;
  final HapticService? hapticService;
  final TtsService? ttsService;
  final bool isPracticeMode;

  const WordMixerCompletedView({
    super.key,
    required this.puzzle,
    required this.streak,
    required this.onGoBack,
    required this.onPracticeMore,
    this.primaryColor = IllustrationColors.richPurple,
    this.hapticService,
    this.ttsService,
    this.isPracticeMode = false,
  });

  void _speakWord(String word) {
    if (word.isEmpty) return;
    try {
      (hapticService ?? (di.sl.isRegistered<HapticService>() ? di.sl<HapticService>() : null))?.light();
      (ttsService ?? (di.sl.isRegistered<TtsService>() ? di.sl<TtsService>() : null))?.speak(word);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final word = puzzle?.word ?? '';
    final definition = puzzle?.cleanHint ?? '';

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with animated gradient
            Container(
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.emerald500, AppColors.emerald600],
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
                      'home.practice_complete',
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
                      'home.practice_complete_desc',
                      fallback: 'Great job! Keep practicing to build your vocabulary.',
                    )
                  : context.tr(
                      'home.come_back_tomorrow',
                      fallback: 'You solved today\'s word. Come back tomorrow for a new challenge!',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),

            // Solved Word Card with Pronunciation Speaker
            if (word.isNotEmpty) ...[
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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
                          onPressed: () => _speakWord(word),
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: primaryColor,
                            size: 22.r,
                          ),
                          tooltip: context.tr('common.listen', fallback: 'Pronounce'),
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
                    if (definition.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Text(
                        definition,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
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
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                    if (puzzle != null && puzzle!.hasSynonyms) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        alignment: WrapAlignment.center,
                        children: puzzle!.synonyms.map((s) => Chip(
                          label: Text(s, style: TextStyle(fontSize: 10.sp)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
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
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
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

            // Streak card
            if (streak > 0) ...[
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 24.sp)),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$streak ${context.tr('home.day_streak', fallback: 'Day Streak')}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.tr('home.keep_it_going', fallback: 'Keep your daily streak alive!'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
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

            // Practice Another Word CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPracticeMore,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(
                  context.tr('home.practice_more_words', fallback: 'Practice Another Word'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Return button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onGoBack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  context.tr('common.go_back', fallback: 'Back to Home'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
