import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class ConsonantClarityExplanationCard extends StatelessWidget {
  final AccentQuest quest;
  final Color color;
  final bool isDark;

  const ConsonantClarityExplanationCard({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (quest.mouthPosition == null) return const SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.face_retouching_natural, color: color, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              quest.mouthPosition!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}
