import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

/// Cultural note card and formality rating gauge widget.
class SituationalResponseFormalityGauge extends StatelessWidget {
  /// Active roleplay quest containing formality scores and cultural notes.
  final RoleplayQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates a [SituationalResponseFormalityGauge] widget.
  const SituationalResponseFormalityGauge({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (quest.culturalNote == null && quest.formalityScore == null) {
      return const SizedBox();
    }

    final double score = ((quest.formalityScore ?? 50) / 100.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public_rounded, color: primaryColor, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                "CULTURAL NOTE",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (quest.culturalNote != null) ...[
            SizedBox(height: 8.h),
            Text(
              quest.culturalNote!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.black87,
                height: 1.45,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Casual",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              Text(
                "Formal",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final fillWidth = trackWidth * score;
              return Stack(
                children: [
                  Container(
                    height: 8.h,
                    width: trackWidth,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 8.h,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
