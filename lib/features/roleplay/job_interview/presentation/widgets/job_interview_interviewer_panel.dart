import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JobInterviewInterviewerPanel extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  final String? reaction;

  const JobInterviewInterviewerPanel({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.reaction,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = reaction == 'impressed' ? Colors.greenAccent : (reaction == 'disappointed' ? Colors.redAccent : color);
    final IconData activeIcon = reaction == 'impressed' ? Icons.sentiment_very_satisfied_rounded : (reaction == 'disappointed' ? Icons.sentiment_dissatisfied_rounded : Icons.business_center_rounded);

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF07070F)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: reaction != null ? activeColor.withValues(alpha: 0.3) : (isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activeIcon,
                  color: activeColor,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reaction == 'impressed' ? "IMPRESSED" : (reaction == 'disappointed' ? "DISAPPOINTED" : "CHIEF EXECUTIVE V-407"),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      color: activeColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    reaction != null ? "INTERVIEWER REACTION" : "ACTIVE BIO-TRANSCEIVER",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 7.sp,
                      color: activeColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: activeColor.withValues(alpha: 0.05)),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
