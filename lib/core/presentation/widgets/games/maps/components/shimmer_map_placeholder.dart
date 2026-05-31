import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/painters/category_path_painter.dart';

/// A premium skeleton loader displaying a shimmering track layout while categories load from disk/cache.
class ShimmerMapPlaceholder extends StatelessWidget {
  final ThemeResult theme;
  final List<Offset> points;
  final double rowSpacing;
  final double totalHeight;
  final int totalLevels;

  const ShimmerMapPlaceholder({
    super.key,
    required this.theme,
    required this.points,
    required this.rowSpacing,
    required this.totalHeight,
    required this.totalLevels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.05,
    );

    return Stack(
      children: [
        // 1. Shimmering Path Line
        CustomPaint(
          size: Size(ScreenUtil().screenWidth, totalHeight),
          painter: CategoryPathPainter(
            points: points,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            category: theme.category,
            isDark: isDark,
            unlockedLevels: 0,
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2.seconds,
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),

        // 2. Shimmering Nodes
        Column(
          children: [
            SizedBox(height: 150.h),
            ...List.generate(totalLevels, (index) {
              final point = points[index];
              return Container(
                height: rowSpacing,
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(point.dx - ScreenUtil().screenWidth / 2, 0),
                  child: Container(
                    width: 85.r,
                    height: 85.r,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white24,
                        width: 2,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 1.5.seconds,
                    color: theme.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
              );
            }),
            SizedBox(height: 150.h),
          ],
        ),
      ],
    );
  }
}
