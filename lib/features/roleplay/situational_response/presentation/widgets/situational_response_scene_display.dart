import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

class SituationalResponseSceneDisplay extends StatelessWidget {
  final RoleplayQuest quest;
  final Color color;
  final bool isDark;
  final VoidCallback onListen;

  const SituationalResponseSceneDisplay({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.onListen,
  });

  @override
  Widget build(BuildContext context) {
    final Color glowColor = color.withValues(alpha: 0.25);

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 15, spreadRadius: -3),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.theater_comedy_rounded, color: color, size: 24.r),
              SizedBox(width: 8.w),
              Text(
                "ACTIVE SCENARIO",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              ScaleButton(
                onTap: onListen,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_up_rounded, size: 16.r, color: color),
                      SizedBox(width: 4.w),
                      Text(
                        "LISTEN",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            quest.scene ?? "",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
