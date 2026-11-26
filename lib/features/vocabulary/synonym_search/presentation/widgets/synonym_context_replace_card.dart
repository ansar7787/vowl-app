import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Timed context-replacement round used mid-level in Mastery Phase to break
/// grid monotony and test sentence-level synonym selection directly.
class SynonymContextReplaceCard extends StatelessWidget {
  final VocabularyQuest quest;
  final int level;
  final String? selectedOption;
  final bool isHintActive;
  final Color primaryColor;
  final ValueChanged<String> onSelectOption;

  const SynonymContextReplaceCard({
    super.key,
    required this.quest,
    required this.level,
    required this.selectedOption,
    required this.isHintActive,
    required this.primaryColor,
    required this.onSelectOption,
  });

  String get _nonSpoilerAudioText {
    final target = (quest.word ?? '').trim();
    final def = (quest.definition ?? '').trim();
    return def.isNotEmpty ? '$target. $def' : target;
  }

  int? _eliminatedOptionIndex(List<String> options, String correctAnswer) {
    if (!isHintActive || options.length < 3) return null;
    final wrongIndices = <int>[];
    for (int i = 0; i < options.length; i++) {
      if (options[i].trim().toLowerCase() !=
          correctAnswer.trim().toLowerCase()) {
        wrongIndices.add(i);
      }
    }
    if (wrongIndices.isEmpty) return null;
    return wrongIndices[quest.id.hashCode.abs() % wrongIndices.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cefr = SynonymCefrHelper.cefrForLevel(level);
    final options = quest.options ?? const <String>[];
    final correctAnswer = (quest.correctAnswer ?? quest.synonym ?? '').trim();
    final eliminatedIdx = _eliminatedOptionIndex(options, correctAnswer);
    final clueText = (quest.contextSentence ?? '').trim();
    final hintText = (quest.hint ?? '').trim();

    return Container(
      key: const Key('synonym_context_replace_card'),
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
                        'Context match • $cefr',
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
                key: const Key('context_replace_tts'),
                text: _nonSpoilerAudioText,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Pick the word that fits "${quest.word ?? ''}" naturally in this sentence:',
            style: SynonymUiTokens.supportBody(
              color: SynonymUiTokens.mutedText(isDark),
            ),
          ),
          SizedBox(height: 10.h),
          _ContextPromptSentence(
            sentence: clueText,
            filledWord: selectedOption,
            isCorrect:
                selectedOption != null &&
                selectedOption!.trim().toLowerCase() ==
                    correctAnswer.toLowerCase(),
            primaryColor: primaryColor,
            isDark: isDark,
          ),
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
          SizedBox(height: 14.h),
          for (int i = 0; i < options.length; i++) ...[
            _ContextOptionTile(
              key: Key('context_replace_opt_$i'),
              label: options[i],
              isEliminated: i == eliminatedIdx,
              isSelected:
                  selectedOption != null &&
                  selectedOption!.toLowerCase() == options[i].toLowerCase(),
              isCorrectOption:
                  options[i].trim().toLowerCase() ==
                  correctAnswer.toLowerCase(),
              hasAnswered: selectedOption != null,
              primaryColor: primaryColor,
              isDark: isDark,
              onTap: (selectedOption != null || i == eliminatedIdx)
                  ? null
                  : () => onSelectOption(options[i]),
            ),
            if (i < options.length - 1) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}

class _ContextPromptSentence extends StatelessWidget {
  final String sentence;
  final String? filledWord;
  final bool isCorrect;
  final Color primaryColor;
  final bool isDark;

  const _ContextPromptSentence({
    required this.sentence,
    required this.filledWord,
    required this.isCorrect,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final parts = sentence.split(RegExp(r'_{3,}'));
    final before = parts.isNotEmpty ? parts.first.trim() : '';
    final after = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';
    final accent = filledWord == null
        ? primaryColor
        : (isCorrect ? AppColors.emerald600 : AppColors.rose500);

    return Container(
      width: double.infinity,
      padding: SynonymUiTokens.innerPanelPadding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate900.withValues(alpha: 0.65)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
        border: Border.all(color: SynonymUiTokens.subtleBorder(isDark)),
      ),
      child: Text.rich(
        TextSpan(
          style: SynonymUiTokens.sentenceBody(
            color: SynonymUiTokens.secondaryText(isDark),
          ),
          children: [
            if (before.isNotEmpty) TextSpan(text: '$before '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(
                    SynonymUiTokens.badgeRadius,
                  ),
                  border: Border.all(color: accent, width: 1.2),
                ),
                child: Text(
                  filledWord ?? '___',
                  style: SynonymUiTokens.interactiveWord(
                    color: isDark ? AppColors.slate50 : accent,
                  ),
                ),
              ),
            ),
            if (after.isNotEmpty) TextSpan(text: ' $after'),
          ],
        ),
      ),
    );
  }
}

class _ContextOptionTile extends StatelessWidget {
  final String label;
  final bool isEliminated;
  final bool isSelected;
  final bool isCorrectOption;
  final bool hasAnswered;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _ContextOptionTile({
    super.key,
    required this.label,
    required this.isEliminated,
    required this.isSelected,
    required this.isCorrectOption,
    required this.hasAnswered,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = SynonymUiTokens.subtleBorder(isDark);
    Color bg = isDark
        ? AppColors.slate900.withValues(alpha: 0.65)
        : AppColors.white;
    Color textColor = isEliminated
        ? SynonymUiTokens.mutedText(isDark)
        : SynonymUiTokens.primaryText(isDark);

    if (isSelected) {
      borderColor = isCorrectOption ? AppColors.emerald600 : AppColors.rose500;
      bg = borderColor.withValues(alpha: isDark ? 0.26 : 0.12);
    } else if (hasAnswered && isCorrectOption) {
      borderColor = AppColors.emerald600;
    }

    return AnimatedOpacity(
      duration: VowlMotion.shouldReduceMotion(context)
          ? Duration.zero
          : VowlMotion.fast,
      opacity: isEliminated ? 0.45 : 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  SynonymUiTokens.controlRadius,
                ),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: SynonymUiTokens.interactiveWord(color: textColor)
                          .copyWith(
                            decoration: isEliminated
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      isCorrectOption
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 18.sp,
                      color: borderColor,
                    )
                  else if (isEliminated)
                    Text(
                      'Ruled out',
                      style: SynonymUiTokens.badgeLabel(
                        color: SynonymUiTokens.mutedText(isDark),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
