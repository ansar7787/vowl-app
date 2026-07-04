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
    final double targetX = (maxWidth / 2) + (isLeft ? -90.w : 90.w);
    final double targetY = 170.h;

    Color towerColor = color;
    if (isAnswered && hoveredTowerIndex == index) {
      towerColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    } else if (isHovered) {
      towerColor = color;
    } else {
      towerColor = color.withValues(alpha: 0.35);
    }

    String cleanLabel = label;
    if (label.contains(' (British)')) {
      cleanLabel = "[BRITISH] ${label.replaceAll(' (British)', '')}";
    } else if (label.contains(' (American)')) {
      cleanLabel = "[AMERICAN] ${label.replaceAll(' (American)', '')}";
    }

    return Positioned(
      left: targetX - 80.w,
      top: targetY - 70.h,
      child: SizedBox(
        width: 160.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isHovered || (isAnswered && hoveredTowerIndex == index))
                  Container(
                        width: 72.r,
                        height: 72.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: towerColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.5, 1.5),
                        duration: 1.2.seconds,
                      )
                      .fadeOut(),

                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovered
                          ? towerColor
                          : towerColor.withValues(alpha: 0.2),
                      width: isHovered ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isHovered)
                        BoxShadow(
                          color: towerColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_input_antenna_rounded,
                    size: 32.r,
                    color: towerColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isHovered
                    ? towerColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isHovered
                      ? towerColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                cleanLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isHovered
                      ? towerColor
                      : towerColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
