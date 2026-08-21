import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BranchingDialogueRelationshipMeter extends StatelessWidget {
  final int? consequenceScore;
  final Color primaryColor;
  final bool isDark;

  const BranchingDialogueRelationshipMeter({
    super.key,
    required this.consequenceScore,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Score defines if it's polite (+1) or rude (-1) or neutral (null/0)
    final double value = consequenceScore == null ? 0.5 : (consequenceScore! > 0 ? 1.0 : 0.0);
    final Color activeColor = value > 0.5 ? Colors.greenAccent : (value < 0.5 ? Colors.redAccent : primaryColor);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RELATIONSHIP STATUS",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                value > 0.5 ? Icons.thumb_up_alt_rounded : (value < 0.5 ? Icons.thumb_down_alt_rounded : Icons.thumbs_up_down_rounded),
                color: activeColor,
                size: 14.r,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              Container(
                height: 8.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                height: 8.h,
                width: (1.sw - 64.w) * value,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rude",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Polite",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }
}
