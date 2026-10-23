import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Interactive word token that can be inspected and selected for grammatical correction.
class SentenceCorrectionDiagnosticWord extends StatelessWidget {
  /// The word token text.
  final String text;

  /// The index position of this word token in the sentence.
  final int index;

  /// Whether the user has marked this word as suspected erroneous.
  final bool isSuspected;

  /// Whether this word was correctly diagnosed as the error.
  final bool isCorrectZap;

  /// Whether this word was incorrectly diagnosed as the error.
  final bool isWrongZap;

  /// Whether error highlight styling should be applied.
  final bool isErrorHighlight;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// The primary accent color for active borders and glows.
  final Color primaryColor;

  /// Callback invoked when the word token is tapped.
  final VoidCallback onTap;

  /// Creates a [SentenceCorrectionDiagnosticWord] widget.
  const SentenceCorrectionDiagnosticWord({
    super.key,
    required this.text,
    required this.index,
    required this.isSuspected,
    required this.isCorrectZap,
    required this.isWrongZap,
    this.isErrorHighlight = false,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    Color itemColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    Color borderColor = primaryColor.withValues(alpha: 0.12);
    double borderWidth = 1;
    Color textColor = Theme.of(context).colorScheme.onSurface;
    List<BoxShadow> shadows = [];
    TextDecoration? textDecoration;
    Color? decorationColor;

    if (isErrorHighlight && !isCorrectZap && !isWrongZap) {
      textDecoration = TextDecoration.underline;
      decorationColor = Colors.orangeAccent;
      textColor = isDark ? Colors.orangeAccent : Colors.deepOrange;
    }

    if (isCorrectZap) {
      itemColor = tokens.gameCorrect.withValues(alpha: 0.15);
      borderColor = tokens.gameCorrect;
      borderWidth = 1.5;
      textColor = tokens.gameCorrect;
      shadows = [
        BoxShadow(
          color: tokens.gameCorrect.withValues(alpha: 0.25),
          blurRadius: 10,
        ),
      ];
    } else if (isWrongZap) {
      itemColor = tokens.gameIncorrect.withValues(alpha: 0.15);
      borderColor = tokens.gameIncorrect;
      borderWidth = 1.5;
      textColor = tokens.gameIncorrect;
      shadows = [
        BoxShadow(
          color: tokens.gameIncorrect.withValues(alpha: 0.25),
          blurRadius: 10,
        ),
      ];
      textDecoration = TextDecoration.lineThrough;
    } else if (isSuspected) {
      itemColor = primaryColor.withValues(alpha: 0.15);
      borderColor = primaryColor;
      borderWidth = 1.5;
      textColor = primaryColor;
      shadows = [
        BoxShadow(color: primaryColor.withValues(alpha: 0.25), blurRadius: 8),
      ];
    }

    final wordWidget = ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCorrectZap) ...[
              Icon(
                Icons.check_circle_rounded,
                color: tokens.gameCorrect,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
            ] else if (isWrongZap) ...[
              Icon(
                Icons.cancel_rounded,
                color: tokens.gameIncorrect,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: isCorrectZap || isWrongZap || isSuspected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
                decoration: textDecoration,
                decorationColor: decorationColor,
                decorationThickness: textDecoration != null ? 2 : null,
              ),
            ),
          ],
        ),
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return wordWidget;
    }

    return wordWidget
        .animate(target: isSuspected ? 1 : 0)
        .shimmer(
          duration: 400.ms,
          color: isCorrectZap
              ? tokens.gameCorrect
              : (isWrongZap ? tokens.gameIncorrect : primaryColor),
        )
        .shake(duration: 300.ms, hz: isWrongZap ? 10 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.04, 1.04),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
