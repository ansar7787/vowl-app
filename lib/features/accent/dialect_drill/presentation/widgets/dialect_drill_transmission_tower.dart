import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DialectDrillTransmissionTower extends StatelessWidget {
  final int index;
  final String label;
  final double maxWidth;
  final Color color;
  final bool isDark;
  final bool isHovered;
  final bool isAnswered;
  final bool? isCorrect;
  final int? hoveredTowerIndex;

  const DialectDrillTransmissionTower({
    super.key,
    required this.index,
    required this.label,
    required this.maxWidth,
    required this.color,
    required this.isDark,
    required this.isHovered,
    required this.isAnswered,
    required this.isCorrect,
    required this.hoveredTowerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = index == 0;
    final double targetX = (maxWidth / 2) + (isLeft ? -110.w : 110.w);
    final double targetY = 220.h;

    Color towerColor = color;
    if (isAnswered && hoveredTowerIndex == index) {
      towerColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    } else if (isHovered) {
      towerColor = color;
    } else {
      towerColor = color.withValues(alpha: 0.35);
    }

    String displayLabel = label;
    IconData regionIcon = Icons.public;
    if (label.toLowerCase().contains('british')) {
      displayLabel = "British";
      regionIcon = Icons.language_rounded;
    } else if (label.toLowerCase().contains('american')) {
      displayLabel = "American";
      regionIcon = Icons.public_rounded;
    } else {
      displayLabel = label.replaceAll(RegExp(r'\(.*\)'), '').trim();
    }

    return Positioned(
      left: targetX - 70.w,
      top: targetY - 60.h,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isHovered || (isAnswered && hoveredTowerIndex == index))
            Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: towerColor.withValues(alpha: 0.1),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.1, 1.1),
                  duration: 1.seconds,
                ),

          Container(
            width: 140.w,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white70,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: isHovered
                    ? towerColor
                    : towerColor.withValues(alpha: 0.15),
                width: isHovered ? 2.5 : 1.5,
              ),
              boxShadow: [
                if (isHovered)
                  BoxShadow(
                    color: towerColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  regionIcon,
                  size: 36.r,
                  color: isHovered
                      ? towerColor
                      : towerColor.withValues(alpha: 0.6),
                ),
                SizedBox(height: 8.h),
                Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isHovered
                        ? towerColor
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
