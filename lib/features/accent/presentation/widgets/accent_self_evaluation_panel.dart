import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/speaking_self_evaluation_controls.dart';

class AccentSelfEvaluationPanel extends StatelessWidget {
  final String textToSpeak;
  final Color primaryColor;
  final bool isCompact;
  final void Function(bool isCorrect) onEvaluate;
  final int? bonusCoins;

  const AccentSelfEvaluationPanel({
    super.key,
    required this.textToSpeak,
    required this.primaryColor,
    required this.isCompact,
    required this.onEvaluate,
    this.bonusCoins = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Divider(color: primaryColor.withValues(alpha: 0.2), thickness: 2),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PHASE 2: SPEAKING",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: primaryColor,
              ),
            ),
            if (bonusCoins != null) ...[
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '+$bonusCoins Coins',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (textToSpeak.trim().isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '"$textToSpeak"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: textToSpeak.length > 30 ? 16.sp : 18.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
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
          allowSkip: false, // Legacy panel didn't have "Can't Speak Now"
          isDark: isDark,
        ),
      ],
    ).animate().slideY(begin: 0.2).fadeIn();
  }
}
