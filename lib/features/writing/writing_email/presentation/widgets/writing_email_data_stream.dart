import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WritingEmailDataStream extends StatelessWidget {
  final List<String> items;
  final Map<String, String?> slots;
  final Color color;
  final bool isDark;

  const WritingEmailDataStream({
    super.key,
    required this.items,
    required this.slots,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final placed = slots.values.toSet();
    final availableItems = items.where((i) => !placed.contains(i)).toList();

    return Container(
      constraints: BoxConstraints(minHeight: 80.h),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: availableItems
            .map(
              (i) => Draggable<String>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 260.w,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Text(
                      i,
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                child: Container(
                  width: 140.w,
                  padding: EdgeInsets.all(12.r),
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
                    i,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
