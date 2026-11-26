import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Compact collocation & nuance scale supplement shown inside Mastery feedback.
class SynonymMasteryFeedbackContent extends StatelessWidget {
  final VocabularyQuest quest;
  final Color primaryColor;

  const SynonymMasteryFeedbackContent({
    super.key,
    required this.quest,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final good =
        quest.collocations?.where((e) => e.trim().isNotEmpty).toList() ??
        const <String>[];
    final bad =
        quest.wrongCollocations?.where((e) => e.trim().isNotEmpty).toList() ??
        const <String>[];
    final scale =
        quest.gradientScale?.where((e) => e.trim().isNotEmpty).toList() ??
        const <String>[];

    if (good.isEmpty && bad.isEmpty && scale.length < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('synonym_mastery_feedback_content'),
      width: double.infinity,
      padding: SynonymUiTokens.innerPanelPadding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate900.withValues(alpha: 0.65)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
        border: Border.all(color: SynonymUiTokens.subtleBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (good.isNotEmpty || bad.isNotEmpty) ...[
            Text(
              'Common pairings',
              style: SynonymUiTokens.badgeLabel(
                color: SynonymUiTokens.mutedText(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                if (good.isNotEmpty)
                  _PairingTag(
                    icon: Icons.check_circle_outline_rounded,
                    label: good.first,
                    color: AppColors.emerald600,
                    isDark: isDark,
                  ),
                if (bad.isNotEmpty)
                  _PairingTag(
                    icon: Icons.highlight_off_rounded,
                    label: 'Not: ${bad.first}',
                    color: AppColors.rose500,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
          if (scale.length >= 2) ...[
            if (good.isNotEmpty || bad.isNotEmpty) SizedBox(height: 10.h),
            Text(
              'Word scale',
              style: SynonymUiTokens.badgeLabel(
                color: SynonymUiTokens.mutedText(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < scale.length; i++) ...[
                  Text(
                    scale[i],
                    style: SynonymUiTokens.controlLabel(
                      color:
                          scale[i].toLowerCase() ==
                              (quest.correctAnswer ?? quest.synonym ?? '')
                                  .toLowerCase()
                          ? (isDark ? AppColors.slate50 : primaryColor)
                          : SynonymUiTokens.secondaryText(isDark),
                    ),
                  ),
                  if (i < scale.length - 1)
                    Text(
                      '→',
                      style: SynonymUiTokens.badgeLabel(
                        color: SynonymUiTokens.mutedText(isDark),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PairingTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _PairingTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.slate50 : color;
    return Container(
      padding: SynonymUiTokens.badgePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(SynonymUiTokens.badgeRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: fg),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              style: SynonymUiTokens.badgeLabel(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
