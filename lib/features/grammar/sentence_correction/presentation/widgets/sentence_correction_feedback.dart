import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceCorrectionFeedback extends StatelessWidget {
  final String correction;
  final String? incorrectPart;
  final bool wasWordSelectionCorrect;
  final bool wasOptionSelectionCorrect;
  final Color primaryColor;

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
    String feedbackTitle = "GLITCH RESOLUTION";
    String feedbackMessage = "Correction: $correction";

    if (!wasWordSelectionCorrect) {
      feedbackTitle = "WRONG DIAGNOSIS";
      if (incorrectPart != null) {
        feedbackMessage =
            "The incorrect word was '$incorrectPart'. It should be '$correction'.";
      } else {
        feedbackMessage =
            "You selected the wrong word to repair. The correct repair is '$correction'.";
      }
    } else if (!wasOptionSelectionCorrect) {
      feedbackTitle = "WRONG REPAIR OPTION";
      feedbackMessage =
          "You found the glitch, but chose the wrong repair! It should be '$correction'.";
    } else {
      feedbackTitle = "TYPING ERROR";
      feedbackMessage =
          "You missed the confirmation spelling! The exact repair is '$correction'.";
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            feedbackTitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            feedbackMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
