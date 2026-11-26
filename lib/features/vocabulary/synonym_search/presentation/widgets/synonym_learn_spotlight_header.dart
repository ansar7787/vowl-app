import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_translatable_block.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Spotlight banner at the top of Learn Phase displaying the base <-> synonym pair,
/// CEFR band, interactive progress indicators, core meaning, and TTS audio.
class SynonymLearnSpotlightHeader extends StatelessWidget {
  final SynonymLearnItem item;
  final int pairIndex;
  final int totalPairs;
  final int testedMakeovers;
  final Color primaryColor;
  final bool autoSpeak;
  final VoidCallback? onToggleAutoSpeak;

  const SynonymLearnSpotlightHeader({
    super.key,
    required this.item,
    required this.pairIndex,
    required this.totalPairs,
    required this.testedMakeovers,
    required this.primaryColor,
    this.autoSpeak = false,
    this.onToggleAutoSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalMakeovers = item.makeovers.length;
    final allTested = totalMakeovers > 0 && testedMakeovers >= totalMakeovers;
    final meaningAndNuance = item.whyDifferent.isNotEmpty
        ? '${item.coreMeaning}\n\n${item.whyDifferent}'
        : item.coreMeaning;

    return SynonymTranslatableArea(
      textToTranslate: meaningAndNuance,
      primaryColor: primaryColor,
      buttonSize: 20,
      builder: (context, translateAction, translatedBanner) => Container(
        width: double.infinity,
        padding: SynonymUiTokens.cardPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [primaryColor.withValues(alpha: 0.26), AppColors.slate800]
                : [primaryColor.withValues(alpha: 0.12), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(SynonymUiTokens.cardRadius),
          border: Border.all(
            color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SpotlightChip(
                  text: '${item.cefr} • ${item.partOfSpeech}',
                  color: primaryColor,
                  isDark: isDark,
                ),
                _SpotlightChip(
                  text: 'Pair ${pairIndex + 1} of $totalPairs',
                  color: isDark ? AppColors.slate300 : AppColors.slate700,
                  isDark: isDark,
                ),
                _SpotlightChip(
                  text: allTested
                      ? 'All checked'
                      : 'Checked $testedMakeovers/$totalMakeovers',
                  color: allTested ? AppColors.emerald600 : primaryColor,
                  isDark: isDark,
                ),
                if (totalMakeovers > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < totalMakeovers; i++) ...[
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < testedMakeovers
                                ? (allTested
                                      ? AppColors.emerald500
                                      : primaryColor)
                                : (isDark
                                      ? AppColors.slate700
                                      : AppColors.slate300),
                          ),
                        ),
                        if (i < totalMakeovers - 1) SizedBox(width: 4.w),
                      ],
                    ],
                  ),
                if (onToggleAutoSpeak != null)
                  _AutoSpeakChip(
                    enabled: autoSpeak,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: onToggleAutoSpeak!,
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.baseWord,
                        style: SynonymUiTokens.displayWord(
                          color: SynonymUiTokens.primaryText(isDark),
                        ),
                      ),
                      Icon(
                        Icons.compare_arrows_rounded,
                        size: 20.sp,
                        color: primaryColor,
                      ),
                      Text(
                        item.synonym,
                        style: SynonymUiTokens.displayWord(
                          color: isDark ? AppColors.indigo400 : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                translateAction,
                SizedBox(width: 8.w),
                TtsSpeakerButtonWidget(
                  text:
                      '${item.baseWord}. ${item.synonym}. ${item.coreMeaning}',
                  color: primaryColor,
                  size: 22,
                ),
              ],
            ),
            SizedBox(height: 8.h),
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
                      ? AppColors.slate900.withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(
                    SynonymUiTokens.controlRadius,
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
            ?translatedBanner,
          ],
        ),
      ),
    );
  }
}

class _SpotlightChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _SpotlightChip({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SynonymUiTokens.badgePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.11),
        borderRadius: BorderRadius.circular(SynonymUiTokens.badgeRadius),
      ),
      child: Text(
        text,
        style: SynonymUiTokens.badgeLabel(
          color: isDark ? AppColors.slate50 : color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AutoSpeakChip extends StatelessWidget {
  final bool enabled;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _AutoSpeakChip({
    required this.enabled,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = primaryColor.withValues(alpha: isDark ? 0.28 : 0.14);
    final inactiveBg = isDark ? AppColors.slate800 : AppColors.slate100;
    final fg = enabled
        ? (isDark ? AppColors.slate50 : primaryColor)
        : (isDark ? AppColors.slate200 : AppColors.slate700);

    return Semantics(
      button: true,
      toggled: enabled,
      label: enabled ? 'Read aloud on' : 'Read aloud off',
      child: ScaleButton(
        key: const Key('learn_auto_speak_toggle'),
        debounceDuration: const Duration(milliseconds: 120),
        onTap: onTap,
        child: Container(
          padding: SynonymUiTokens.badgePadding,
          decoration: BoxDecoration(
            color: enabled ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(SynonymUiTokens.badgeRadius),
            border: Border.all(
              color: enabled
                  ? primaryColor.withValues(alpha: 0.55)
                  : SynonymUiTokens.subtleBorder(isDark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 14.sp,
                color: fg,
              ),
              SizedBox(width: 4.w),
              Text(
                enabled ? 'Read aloud on' : 'Read aloud',
                style: SynonymUiTokens.badgeLabel(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
