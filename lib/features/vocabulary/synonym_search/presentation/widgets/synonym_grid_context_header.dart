import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Compact Mastery target card with CEFR tier, non-spoiler audio, and live
/// blank letter slots that fill dynamically as tiles are traced on the grid.
class SynonymGridContextHeader extends StatelessWidget {
  final VocabularyQuest quest;
  final int level;
  final String normalizedTarget;
  final String currentSpelledWord;
  final bool isHintActive;
  final Color primaryColor;

  const SynonymGridContextHeader({
    super.key,
    required this.quest,
    required this.level,
    required this.normalizedTarget,
    required this.currentSpelledWord,
    required this.isHintActive,
    required this.primaryColor,
  });

  String get _nonSpoilerAudioText {
    final targetWord = (quest.word ?? '').trim();
    final def = (quest.definition ?? '').trim();
    if (def.isNotEmpty) {
      return '$targetWord. $def';
    }
    return targetWord;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cefr = SynonymCefrHelper.cefrForLevel(level);
    final rawContext = (quest.contextSentence ?? '').trim();
    final clueText = rawContext.isNotEmpty
        ? rawContext
        : (quest.definition ?? '').trim();
    final hintText = (quest.hint ?? '').trim().isNotEmpty
        ? quest.hint!.trim()
        : (quest.collocations?.isNotEmpty == true
              ? 'Commonly paired with: ${quest.collocations!.first}'
              : '');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.cardCompact),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.92)
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.28 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'FIND SYNONYM • $cefr',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.slate50 : primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      quest.word ?? '',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              TtsSpeakerButtonWidget(
                key: const Key('mastery_nonspoiler_tts'),
                text: _nonSpoilerAudioText,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
          if (clueText.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _ContextClueWithLiveSlot(
              clueText: clueText,
              targetLength: normalizedTarget.length,
              currentSpelled: currentSpelledWord,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ] else ...[
            SizedBox(height: 8.h),
            _LiveLetterSlotsRow(
              targetLength: normalizedTarget.length,
              currentSpelled: currentSpelledWord,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ],
          if (isHintActive && hintText.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(
                  alpha: isDark ? 0.20 : 0.12,
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 15.sp,
                    color: isDark ? AppColors.amber400 : AppColors.amber600,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      hintText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate100 : AppColors.slate800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextClueWithLiveSlot extends StatelessWidget {
  final String clueText;
  final int targetLength;
  final String currentSpelled;
  final Color primaryColor;
  final bool isDark;

  const _ContextClueWithLiveSlot({
    required this.clueText,
    required this.targetLength,
    required this.currentSpelled,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.slate200 : AppColors.slate700;
    final hasBlank = clueText.contains('___');

    if (!hasBlank) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clueText,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.35,
            ),
          ),
          SizedBox(height: 8.h),
          _LiveLetterSlotsRow(
            targetLength: targetLength,
            currentSpelled: currentSpelled,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
        ],
      );
    }

    final parts = clueText.split(RegExp(r'_{3,}'));
    final beforeWords = _tokenize(parts.isNotEmpty ? parts.first : '');
    final afterWords = parts.length > 1
        ? _tokenize(parts.sublist(1).join(' '))
        : const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4.w,
          runSpacing: 4.h,
          children: [
            for (final w in beforeWords)
              Text(
                w,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            _LiveLetterSlotsRow(
              targetLength: targetLength,
              currentSpelled: currentSpelled,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            for (final w in afterWords)
              Text(
                w,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<String> _tokenize(String chunk) {
    return chunk
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class _LiveLetterSlotsRow extends StatelessWidget {
  final int targetLength;
  final String currentSpelled;
  final Color primaryColor;
  final bool isDark;

  const _LiveLetterSlotsRow({
    required this.targetLength,
    required this.currentSpelled,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final slotCount = targetLength.clamp(1, 20);
    final compact = slotCount > 10;
    final boxWidth = compact ? 17.w : 21.w;
    final boxHeight = compact ? 22.h : 25.h;

    return Wrap(
      spacing: compact ? 3.w : 4.w,
      runSpacing: 4.h,
      children: List.generate(slotCount, (i) {
        final hasLetter = i < currentSpelled.length;
        final isCursor = i == currentSpelled.length;
        final ch = hasLetter ? currentSpelled[i] : '_';

        return Container(
          width: boxWidth,
          height: boxHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasLetter
                ? primaryColor.withValues(alpha: isDark ? 0.34 : 0.16)
                : (isDark
                      ? AppColors.slate900.withValues(alpha: 0.75)
                      : AppColors.slate100),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: hasLetter
                  ? primaryColor
                  : (isCursor
                        ? primaryColor.withValues(alpha: 0.70)
                        : (isDark ? AppColors.slate700 : AppColors.slate300)),
              width: (hasLetter || isCursor) ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            ch,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: compact ? 12.sp : 13.5.sp,
              fontWeight: FontWeight.w900,
              color: hasLetter
                  ? (isDark ? AppColors.slate50 : primaryColor)
                  : (isDark ? AppColors.slate400 : AppColors.slate500),
            ),
          ),
        );
      }),
    );
  }
}
