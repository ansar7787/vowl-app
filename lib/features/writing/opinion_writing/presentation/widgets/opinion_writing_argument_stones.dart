import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OpinionWritingArgumentStones extends StatelessWidget {
  final List<String> options;
  final List<String> leftPanArgs;
  final List<String> rightPanArgs;
  final Color color;
  final bool isDark;

  const OpinionWritingArgumentStones({
    super.key,
    required this.options,
    required this.leftPanArgs,
    required this.rightPanArgs,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final placed = leftPanArgs.toSet()..addAll(rightPanArgs);
    final availableOptions = options.where((o) => !placed.contains(o)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate exact width to ensure exactly 2 cards fit per row (2x2 grid)
        final double cardWidth = (constraints.maxWidth - 12.w) / 2;

        return Container(
          constraints: BoxConstraints(minHeight: 80.h),
          width: double.infinity,
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: availableOptions
                .map(
                  (o) => Draggable<String>(
                    data: o,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: cardWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Text(
                      o,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  width: cardWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.black12,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: color.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    o,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.transparent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
                child: Container(
                  width: cardWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black87 : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isDark ? 0.35 : 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    o,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
      },
    );
  }
}
