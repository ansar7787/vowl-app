import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_translatable_block.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Shared CEFR + activity tag header for Practice exercises.
class SynonymDrillBadge extends StatelessWidget {
  final String label;
  final String cefr;
  final Color primaryColor;
  final bool isDark;

  const SynonymDrillBadge({
    super.key,
    required this.label,
    required this.cefr,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SynonymUiTokens.badgePadding,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.24 : 0.11),
        borderRadius: BorderRadius.circular(SynonymUiTokens.badgeRadius),
      ),
      child: Text(
        '$label • $cefr',
        style: SynonymUiTokens.badgeLabel(
          color: isDark ? AppColors.slate50 : primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shared word bank button used by Contrast Swap and Word Order exercises.
class SynonymPracticeWordPill extends StatelessWidget {
  final String word;
  final bool isUsed;
  final Color primaryColor;
  final bool isDark;
  final double minWidth;
  final VoidCallback onTap;

  const SynonymPracticeWordPill({
    super.key,
    required this.word,
    required this.isUsed,
    required this.primaryColor,
    required this.isDark,
    this.minWidth = 88,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isUsed ? '$word, placed' : 'Place word $word',
      child: ScaleButton(
        debounceDuration: const Duration(milliseconds: 120),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48, minWidth: minWidth),
          child: AnimatedContainer(
            duration: VowlMotion.shouldReduceMotion(context)
                ? Duration.zero
                : VowlMotion.fast,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isUsed
                  ? (isDark ? AppColors.slate800 : AppColors.slate100)
                  : primaryColor,
              borderRadius: BorderRadius.circular(
                SynonymUiTokens.controlRadius,
              ),
              border: Border.all(
                color: isUsed
                    ? (isDark ? AppColors.slate700 : AppColors.slate300)
                    : primaryColor,
                width: 1.2,
              ),
              boxShadow: isUsed
                  ? const []
                  : [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word,
                  style: SynonymUiTokens.interactiveWord(
                    color: isUsed
                        ? SynonymUiTokens.mutedText(isDark)
                        : Colors.white,
                  ),
                ),
                if (isUsed) ...[
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.check_rounded,
                    size: 16.sp,
                    color: SynonymUiTokens.mutedText(isDark),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared coaching / hint / spoken feedback banner across Practice cards.
class SynonymPracticeBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  final bool isDark;
  final String? ttsText;
  final Color? primaryColor;

  const SynonymPracticeBanner({
    super.key,
    required this.icon,
    required this.text,
    required this.accent,
    required this.isDark,
    this.ttsText,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = primaryColor ?? accent;
    return SynonymTranslatableArea(
      textToTranslate: text,
      primaryColor: activeAccent,
      buttonSize: 16,
      builder: (context, translateAction, translatedBanner) => Container(
        width: double.infinity,
        padding: SynonymUiTokens.innerPanelPadding,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.20 : 0.09),
          borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18.sp,
                  color: isDark ? AppColors.slate50 : accent,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    text,
                    style: SynonymUiTokens.supportBody(
                      color: SynonymUiTokens.primaryText(isDark),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                translateAction,
                if (ttsText != null && primaryColor != null) ...[
                  SizedBox(width: 6.w),
                  TtsSpeakerButtonWidget(
                    text: ttsText!,
                    color: primaryColor!,
                    size: 18,
                  ),
                ],
              ],
            ),
            ?translatedBanner,
          ],
        ),
      ),
    );
  }
}

/// 1-tap swap button for reversing two placed words between blanks.
class SynonymPracticeSwapButton extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const SynonymPracticeSwapButton({
    super.key,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Swap placed words between blanks',
      child: ScaleButton(
        debounceDuration: const Duration(milliseconds: 120),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: BorderRadius.circular(
                SynonymUiTokens.controlRadius,
              ),
              border: Border.all(color: primaryColor.withValues(alpha: 0.50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 18.sp,
                  color: isDark ? AppColors.slate50 : primaryColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Swap',
                  style: SynonymUiTokens.controlLabel(
                    color: isDark ? AppColors.slate50 : primaryColor,
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
