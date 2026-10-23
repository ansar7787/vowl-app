import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

/// Anatomical diagram widget highlighting clinical vocabulary and body areas.
class MedicalConsultBodyDiagram extends StatelessWidget {
  /// Roleplay quest containing medical vocabulary.
  final RoleplayQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates a [MedicalConsultBodyDiagram] widget.
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
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Container(
      key: const Key('medical_consult_body_diagram'),
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate900.withValues(alpha: 0.5)
            : primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : primaryColor.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                "MEDICAL VOCABULARY",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 90.r,
                width: 90.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: reduceMotion
                      ? Icon(
                          Icons.accessibility_new_rounded,
                          size: 54.r,
                          color: primaryColor.withValues(alpha: 0.7),
                        )
                      : Icon(
                          Icons.accessibility_new_rounded,
                          size: 54.r,
                          color: primaryColor.withValues(alpha: 0.7),
                        )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 1000.ms),
                ),
              ),
              SizedBox(width: 18.w),
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
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                color: Theme.of(context).colorScheme.onSurface,
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
