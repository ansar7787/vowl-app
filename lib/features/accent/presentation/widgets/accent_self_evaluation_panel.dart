import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speaking_self_evaluation_controls.dart';

class AccentSelfEvaluationPanel extends StatelessWidget {
  final String textToSpeak;
  final Color primaryColor;
  final bool isCompact;
  final void Function(bool isCorrect) onEvaluate;

  const AccentSelfEvaluationPanel({
    super.key,
    required this.textToSpeak,
    required this.primaryColor,
    required this.isCompact,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: primaryColor.withValues(alpha: 0.2), thickness: 2),
        SizedBox(height: 8.h),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10.w,
          runSpacing: 4.h,
          children: [
            Text(
              "YOUR TURN TO SPEAK",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: primaryColor,
              ),
            ),
          ],
        ),
        if (textToSpeak.trim().isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              '"$textToSpeak"',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: textToSpeak.length > 30 ? 15.sp : 17.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ] else ...[
          SizedBox(height: 16.h),
        ],

        SpeakingSelfEvaluationControls(
          expectedText: textToSpeak,
          primaryColor: primaryColor,
          onConfirmed: () => onEvaluate(true),
          onSkipped: () => onEvaluate(false),
        ),
      ],
    ).animate().slideY(begin: 0.2).fadeIn();
  }
}
