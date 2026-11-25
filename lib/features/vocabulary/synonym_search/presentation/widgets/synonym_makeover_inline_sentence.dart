import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Interactive wrapped sentence with an inline `>= 48dp` tappable word-swap slot.
class SynonymMakeoverInlineSentence extends StatelessWidget {
  final String beforeSentence;
  final String activeWord;
  final String alternateWord;
  final bool isSwapped;
  final bool isNaturalSwap;
  final Color primaryColor;
  final Color textColor;
  final bool isDark;
  final Key slotKey;
  final VoidCallback onTapSlot;

  const SynonymMakeoverInlineSentence({
    super.key,
    required this.beforeSentence,
    required this.activeWord,
    required this.alternateWord,
    required this.isSwapped,
    required this.isNaturalSwap,
    required this.primaryColor,
    required this.textColor,
    required this.isDark,
    required this.slotKey,
    required this.onTapSlot,
  });

  @override
  Widget build(BuildContext context) {
    final parts = beforeSentence.split('___');
    final prefixWords = _tokenize(parts.isNotEmpty ? parts.first : '');
    final suffixWords = parts.length > 1
        ? _tokenize(parts.sublist(1).join(' '))
        : const [];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5.w,
      runSpacing: 8.h,
      children: [
        for (final w in prefixWords) _wordText(w),
        _SwapSlotButton(
          key: slotKey,
          activeWord: activeWord,
          alternateWord: alternateWord,
          isSwapped: isSwapped,
          isNaturalSwap: isNaturalSwap,
          primaryColor: primaryColor,
          isDark: isDark,
          onTap: onTapSlot,
        ),
        for (final w in suffixWords) _wordText(w),
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

  Widget _wordText(String word) {
    return Text(
      word,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
    );
  }
}

class _SwapSlotButton extends StatelessWidget {
  final String activeWord;
  final String alternateWord;
  final bool isSwapped;
  final bool isNaturalSwap;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SwapSlotButton({
    super.key,
    required this.activeWord,
    required this.alternateWord,
    required this.isSwapped,
    required this.isNaturalSwap,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = !isSwapped
        ? primaryColor
        : (isNaturalSwap ? AppColors.emerald500 : AppColors.rose500);
    final Color fill = !isSwapped
        ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.14)
        : accent.withValues(alpha: isDark ? 0.28 : 0.16);

    return Semantics(
      button: true,
      label: 'Swap word $activeWord with $alternateWord',
      child: ScaleButton(
        debounceDuration: const Duration(milliseconds: 120),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 68),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accent, width: 1.6),
            ),
            child: AnimatedSwitcher(
              duration: VowlMotion.shouldReduceMotion(context)
                  ? Duration.zero
                  : VowlMotion.fast,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.90, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Row(
                key: ValueKey<String>('$activeWord-$isSwapped'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeWord,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate50 : accent,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16.sp,
                    color: isDark ? AppColors.slate200 : accent,
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

/// Native Ear Verdict callout rendered beneath swapped Learn sentences.
class SynonymMakeoverVerdictBanner extends StatelessWidget {
  final bool isNatural;
  final String verdictText;
  final bool isDark;

  const SynonymMakeoverVerdictBanner({
    super.key,
    required this.isNatural,
    required this.verdictText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isNatural ? AppColors.emerald600 : AppColors.rose500;
    final bg = isNatural
        ? (isDark
              ? AppColors.emerald950.withValues(alpha: 0.7)
              : AppColors.emerald50)
        : (isDark ? AppColors.red900.withValues(alpha: 0.45) : AppColors.red50);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNatural
                ? Icons.hearing_rounded
                : Icons.do_not_disturb_alt_rounded,
            size: 18.sp,
            color: isDark ? AppColors.slate50 : accent,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              verdictText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate100 : AppColors.slate800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
