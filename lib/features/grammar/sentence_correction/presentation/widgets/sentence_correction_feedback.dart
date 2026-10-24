import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Feedback card detailing error explanations and the correct sentence replacement.
class SentenceCorrectionFeedback extends StatelessWidget {
  /// The correct replacement word or phrase.
  final String correction;

  /// The erroneous word identified in the sentence.
  final String? incorrectPart;

  /// Whether the user correctly selected the error location.
  final bool wasWordSelectionCorrect;

  /// Whether the user selected the proper replacement option.
  final bool wasOptionSelectionCorrect;

  /// The primary accent color for styling.
  final Color primaryColor;

  /// Creates a [SentenceCorrectionFeedback] widget.
  const SentenceCorrectionFeedback({
    super.key,
    required this.correction,
    this.incorrectPart,
    required this.wasWordSelectionCorrect,
    required this.wasOptionSelectionCorrect,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    String feedbackTitle = "CORRECTION";
    String feedbackMessage = "Correction: $correction";

    if (!wasWordSelectionCorrect) {
      feedbackTitle = "INCORRECT WORD";
      if (incorrectPart != null) {
        feedbackMessage =
            "The incorrect word is '$incorrectPart'. The correct word is '$correction'.";
      } else {
        feedbackMessage =
            "That word is correct. The correct word is '$correction'.";
      }
    } else if (!wasOptionSelectionCorrect) {
      feedbackTitle = "INCORRECT REPLACEMENT";
      feedbackMessage =
          "You found the incorrect word, but the right correction is '$correction'.";
    } else {
      feedbackTitle = "SPELLING ERROR";
      feedbackMessage =
          "Check your spelling. The correct word is '$correction'.";
    }

    final feedback = Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: tokens.gameIncorrect.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: tokens.gameIncorrect.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            feedbackTitle,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: tokens.gameIncorrect,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            feedbackMessage,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.5.sp,
              color: tokens.gameIncorrect,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return feedback;
    }

    return feedback.animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
