import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Related synonym chip strip displayed below sentence examples in Learn Phase.
///
/// Selecting any word reveals its pronunciation, tone tag, real sentence
/// context, and audio without crowding initial load.
class SynonymCousinPreviewStrip extends StatelessWidget {
  final List<SynonymCousinWord> cousins;
  final int? selectedIndex;
  final Color primaryColor;
  final ValueChanged<int> onSelectCousin;

  const SynonymCousinPreviewStrip({
    super.key,
    required this.cousins,
    required this.selectedIndex,
    required this.primaryColor,
    required this.onSelectCousin,
  });

  @override
  Widget build(BuildContext context) {
    if (cousins.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = SynonymUiTokens.cardSurface(isDark);
    final labelColor = SynonymUiTokens.mutedText(isDark);
    final selectedCousin =
        (selectedIndex != null &&
            selectedIndex! >= 0 &&
            selectedIndex! < cousins.length)
        ? cousins[selectedIndex!]
        : null;

    return Container(
      width: double.infinity,
      padding: SynonymUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(SynonymUiTokens.cardRadius),
        border: Border.all(color: SynonymUiTokens.subtleBorder(isDark)),
        boxShadow: SynonymUiTokens.softCardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related words',
            style: SynonymUiTokens.sectionHeading(
              color: SynonymUiTokens.primaryText(isDark),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap a word to see how it is used.',
            style: SynonymUiTokens.supportBody(color: labelColor),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (int i = 0; i < cousins.length; i++)
                _CousinChip(
                  key: Key('cousin_chip_$i'),
                  cousin: cousins[i],
                  isSelected: selectedIndex == i,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => onSelectCousin(i),
                ),
            ],
          ),
          if (selectedCousin != null) ...[
            SizedBox(height: 12.h),
            _CousinDetailPanel(
              cousin: selectedCousin,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _CousinChip extends StatelessWidget {
  final SynonymCousinWord cousin;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _CousinChip({
    super.key,
    required this.cousin,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? primaryColor.withValues(alpha: isDark ? 0.28 : 0.12)
        : (isDark ? AppColors.slate900 : AppColors.slate50);
    final border = isSelected
        ? primaryColor
        : (isDark ? AppColors.slate700 : AppColors.slate300);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${cousin.word}, ${cousin.toneTag}',
      child: ScaleButton(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: VowlMotion.shouldReduceMotion(context)
                ? Duration.zero
                : VowlMotion.fast,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(
                SynonymUiTokens.controlRadius,
              ),
              border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                Text(
                  cousin.word,
                  style: SynonymUiTokens.interactiveWord(
                    color: SynonymUiTokens.primaryText(isDark),
                  ),
                ),
                if (cousin.toneTag.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        SynonymUiTokens.badgeRadius,
                      ),
                    ),
                    child: Text(
                      cousin.toneTag,
                      style: SynonymUiTokens.badgeLabel(
                        color: isDark ? AppColors.slate200 : primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CousinDetailPanel extends StatelessWidget {
  final SynonymCousinWord cousin;
  final Color primaryColor;
  final bool isDark;

  const _CousinDetailPanel({
    required this.cousin,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: SynonymUiTokens.innerPanelPadding,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.w,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      cousin.word,
                      style: SynonymUiTokens.sectionHeading(
                        color: SynonymUiTokens.primaryText(isDark),
                      ),
                    ),
                    if (cousin.ipa.isNotEmpty)
                      Text(
                        cousin.ipa,
                        style: SynonymUiTokens.controlLabel(
                          color: SynonymUiTokens.mutedText(isDark),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  cousin.miniContext,
                  style: SynonymUiTokens.supportBody(
                    color: SynonymUiTokens.primaryText(isDark),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TtsSpeakerButtonWidget(
            text: '${cousin.word}. ${cousin.miniContext}',
            color: primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
