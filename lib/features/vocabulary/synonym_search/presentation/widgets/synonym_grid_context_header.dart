import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Mastery target card with CEFR tier, non-spoiler audio, and live blank
/// letter boxes that fill as letters are selected on the grid.
class SynonymGridContextHeader extends StatelessWidget {
  final VocabularyQuest quest;
  final int level;
  final String normalizedTarget;
  final String currentSpelledWord;
  final bool isHintActive;
  final bool hideLengthUntilHint;
  final Color primaryColor;

  const SynonymGridContextHeader({
    super.key,
    required this.quest,
    required this.level,
    required this.normalizedTarget,
    required this.currentSpelledWord,
    required this.isHintActive,
    this.hideLengthUntilHint = false,
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
      padding: SynonymUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: SynonymUiTokens.cardSurface(isDark),
        borderRadius: BorderRadius.circular(SynonymUiTokens.cardRadius),
        border: Border.all(color: SynonymUiTokens.subtleBorder(isDark)),
        boxShadow: SynonymUiTokens.softCardShadow(isDark),
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
                      padding: SynonymUiTokens.badgePadding,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.24 : 0.11,
                        ),
                        borderRadius: BorderRadius.circular(
                          SynonymUiTokens.badgeRadius,
                        ),
                      ),
                      child: Text(
                        'Find synonym • $cefr',
                        style: SynonymUiTokens.badgeLabel(
                          color: isDark ? AppColors.slate50 : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      quest.word ?? '',
                      style: SynonymUiTokens.displayWord(
                        color: SynonymUiTokens.primaryText(isDark),
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
            SizedBox(height: 10.h),
            _ContextClueWithLiveSlot(
              clueText: clueText,
              targetLength: normalizedTarget.length,
              currentSpelled: currentSpelledWord,
              hideLength:
                  hideLengthUntilHint &&
                  !isHintActive &&
                  currentSpelledWord.isEmpty,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ] else ...[
            SizedBox(height: 10.h),
            if (hideLengthUntilHint &&
                !isHintActive &&
                currentSpelledWord.isEmpty)
              _RecallLengthHiddenPill(
                primaryColor: primaryColor,
                isDark: isDark,
              )
            else
              _LiveLetterSlotsRow(
                targetLength: normalizedTarget.length,
                currentSpelled: currentSpelledWord,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
          ],
          if (isHintActive && hintText.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: SynonymUiTokens.innerPanelPadding,
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(
                  alpha: isDark ? 0.20 : 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  SynonymUiTokens.controlRadius,
                ),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 16.sp,
                    color: isDark ? AppColors.amber400 : AppColors.amber600,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      hintText,
                      style: SynonymUiTokens.supportBody(
                        color: SynonymUiTokens.primaryText(isDark),
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
  final bool hideLength;
  final Color primaryColor;
  final bool isDark;

  const _ContextClueWithLiveSlot({
    required this.clueText,
    required this.targetLength,
    required this.currentSpelled,
    required this.hideLength,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = SynonymUiTokens.secondaryText(isDark);
    final hasBlank = clueText.contains('___');

    if (!hasBlank) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(clueText, style: SynonymUiTokens.sentenceBody(color: textColor)),
          SizedBox(height: 10.h),
          if (hideLength)
            _RecallLengthHiddenPill(primaryColor: primaryColor, isDark: isDark)
          else
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
          spacing: 5.w,
          runSpacing: 6.h,
          children: [
            for (final w in beforeWords)
              Text(w, style: SynonymUiTokens.sentenceBody(color: textColor)),
            if (hideLength)
              _RecallLengthHiddenPill(
                primaryColor: primaryColor,
                isDark: isDark,
              )
            else
              _LiveLetterSlotsRow(
                targetLength: targetLength,
                currentSpelled: currentSpelled,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            for (final w in afterWords)
              Text(w, style: SynonymUiTokens.sentenceBody(color: textColor)),
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

class _RecallLengthHiddenPill extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;

  const _RecallLengthHiddenPill({
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('recall_length_hidden_badge'),
      padding: SynonymUiTokens.badgePadding,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(SynonymUiTokens.badgeRadius),
        border: Border.all(color: primaryColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        '[ ? ]  Trace or tap Hint for length',
        style: SynonymUiTokens.badgeLabel(
          color: isDark ? AppColors.slate50 : primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
    final boxWidth = compact ? 19.w : 24.w;
    final boxHeight = compact ? 24.h : 28.h;

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
                ? primaryColor.withValues(alpha: isDark ? 0.30 : 0.14)
                : (isDark
                      ? AppColors.slate900.withValues(alpha: 0.75)
                      : AppColors.slate100),
            borderRadius: BorderRadius.circular(SynonymUiTokens.badgeRadius),
            border: Border.all(
              color: hasLetter
                  ? primaryColor
                  : (isCursor
                        ? primaryColor.withValues(alpha: 0.70)
                        : (isDark ? AppColors.slate700 : AppColors.slate300)),
              width: (hasLetter || isCursor) ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            ch,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: compact ? 12.sp : 14.sp,
              fontWeight: FontWeight.w600,
              color: hasLetter
                  ? (isDark ? AppColors.slate50 : primaryColor)
                  : SynonymUiTokens.mutedText(isDark),
            ),
          ),
        );
      }),
    );
  }
}
