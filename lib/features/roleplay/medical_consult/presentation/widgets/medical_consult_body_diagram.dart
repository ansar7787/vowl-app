import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

class MedicalConsultBodyDiagram extends StatelessWidget {
  final RoleplayQuest quest;
  final Color primaryColor;
  final bool isDark;

  const MedicalConsultBodyDiagram({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (quest.medicalVocab == null || quest.medicalVocab!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: primaryColor,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "BIOMETRIC SCAN: MEDICAL VOCAB",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 100.r,
                width: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child:
                      Icon(
                            Icons.accessibility_new_rounded,
                            size: 60.r,
                            color: primaryColor.withValues(alpha: 0.7),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 1000.ms),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: quest.medicalVocab!.map((word) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              word.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }
}
