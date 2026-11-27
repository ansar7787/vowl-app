import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_tts_helper.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_translatable_block.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Non-intrusive Practice banner shown after repeated misses, letting the
/// learner peek at examples without losing progress or return to full Learn.
class SynonymPracticeLearnCueBanner extends StatelessWidget {
  final String pairLabel;
  final Color primaryColor;
  final VoidCallback onSeeExample;

  const SynonymPracticeLearnCueBanner({
    super.key,
    required this.pairLabel,
    required this.primaryColor,
    required this.onSeeExample,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.slate50 : primaryColor;

    return Container(
      width: double.infinity,
      padding: SynonymUiTokens.innerPanelPadding,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 18.sp, color: fg),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Need a quick refresher on $pairLabel?',
              style: SynonymUiTokens.supportBody(
                color: SynonymUiTokens.primaryText(isDark),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ScaleButton(
            key: const Key('practice_see_example_btn'),
            debounceDuration: const Duration(milliseconds: 120),
            onTap: onSeeExample,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(
                  SynonymUiTokens.controlRadius,
                ),
              ),
              child: Text(
                'See example',
                style: SynonymUiTokens.badgeLabel(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet showing the matching Learn pair refresher over Practice.
class SynonymPracticeLearnPeekSheet extends StatelessWidget {
  final SynonymLearnItem item;
  final Color primaryColor;
  final VoidCallback onOpenFullLearn;

  const SynonymPracticeLearnPeekSheet({
    super.key,
    required this.item,
    required this.primaryColor,
    required this.onOpenFullLearn,
  });

  static String pairKey(String baseWord, String synonym) =>
      '${baseWord.trim().toLowerCase()}__${synonym.trim().toLowerCase()}';

  static SynonymLearnItem resolveItem({
    required Map<String, SynonymLearnItem> lookup,
    required SynonymPracticeExercise exercise,
    required int level,
  }) {
    final hit = lookup[pairKey(exercise.baseWord, exercise.targetSynonym)];
    if (hit != null) return hit;
    final cleanBase = exercise.baseWord.trim();
    final cleanSyn = exercise.targetSynonym.trim();
    return SynonymLearnItem(
      id: exercise.parentId,
      level: level,
      cefr: exercise.cefr,
      difficulty: 1,
      pairTitle: '$cleanBase ↔ $cleanSyn',
      baseWord: cleanBase,
      synonym: cleanSyn,
      partOfSpeech: 'Vocabulary',
      coreMeaning: exercise.prompt,
      whyDifferent: exercise.hint,
      makeovers: const [],
      cousinWords: const [],
    );
  }

  static Future<void> showForExercise(
    BuildContext context, {
    required SynonymPracticeExercise exercise,
    required Map<String, SynonymLearnItem> lookup,
    required int? reviewLevel,
    required int currentLevel,
    required Color primaryColor,
  }) {
    final router = GoRouter.maybeOf(context);
    final item = resolveItem(
      lookup: lookup,
      exercise: exercise,
      level: reviewLevel ?? currentLevel,
    );
    return show(
      context,
      item: item,
      primaryColor: primaryColor,
      onOpenFullLearn: () => router?.pushReplacement(
        '/learn?category=vocabulary&gameType=synonymSearch&level=$currentLevel',
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required SynonymLearnItem item,
    required Color primaryColor,
    required VoidCallback onOpenFullLearn,
  }) {
    SynonymTtsHelper.stopAll();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SynonymPracticeLearnPeekSheet(
        item: item,
        primaryColor: primaryColor,
        onOpenFullLearn: onOpenFullLearn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom > 0
        ? mq.viewPadding.bottom
        : mq.padding.bottom;
    final surface = isDark ? AppColors.slate900 : Colors.white;
    final naturalExample = item.makeovers
        .where((m) => m.isNaturalSwap)
        .map(
          (m) => m.spokenSentence.isNotEmpty
              ? m.spokenSentence
              : m.beforeSentence.replaceAll('___', m.swappedWord),
        )
        .firstOrNull;
    final translateSource = [
      item.coreMeaning,
      if (item.whyDifferent.isNotEmpty) item.whyDifferent,
      if (naturalExample != null && naturalExample.isNotEmpty) naturalExample,
    ].join('\n\n');

    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.78),
      padding: EdgeInsets.fromLTRB(
        20.w,
        14.h,
        20.w,
        math.max(16.0, 16.h) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: SynonymUiTokens.subtleBorder(isDark)),
      ),
      child: SynonymTranslatableArea(
        textToTranslate: translateSource,
        primaryColor: primaryColor,
        buttonSize: 18,
        builder: (context, translateAction, translatedBanner) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: SynonymUiTokens.subtleBorder(isDark),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.baseWord} ↔ ${item.synonym}',
                    style: SynonymUiTokens.displayWord(
                      color: SynonymUiTokens.primaryText(isDark),
                    ),
                  ),
                ),
                translateAction,
                SizedBox(width: 8.w),
                TtsSpeakerButtonWidget(
                  text:
                      '${item.baseWord}. ${item.synonym}. ${item.coreMeaning}',
                  color: primaryColor,
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.coreMeaning,
                      style: SynonymUiTokens.supportBody(
                        color: SynonymUiTokens.primaryText(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.whyDifferent.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800
                              : AppColors.slate50,
                          borderRadius: BorderRadius.circular(
                            SynonymUiTokens.controlRadius,
                          ),
                          border: Border.all(
                            color: SynonymUiTokens.subtleBorder(isDark),
                          ),
                        ),
                        child: Text(
                          item.whyDifferent,
                          style: SynonymUiTokens.supportBody(
                            color: SynonymUiTokens.secondaryText(isDark),
                          ),
                        ),
                      ),
                    ],
                    if (naturalExample != null &&
                        naturalExample.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(
                            alpha: isDark ? 0.16 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(
                            SynonymUiTokens.controlRadius,
                          ),
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                naturalExample,
                                style: SynonymUiTokens.supportBody(
                                  color: SynonymUiTokens.primaryText(isDark),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            TtsSpeakerButtonWidget(
                              text: naturalExample,
                              color: AppColors.emerald600,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                    ?translatedBanner,
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('peek_back_to_learn_btn'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOpenFullLearn();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.slate200
                          : AppColors.slate700,
                      side: BorderSide(
                        color: SynonymUiTokens.subtleBorder(isDark),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SynonymUiTokens.controlRadius,
                        ),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Back to Learn',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('peek_resume_practice_btn'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SynonymUiTokens.controlRadius,
                        ),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Back to Practice',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
