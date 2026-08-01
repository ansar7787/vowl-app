import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EssayDraftingDataStream extends StatelessWidget {
  final List<String> items;
  final Map<String, String?> slots;
  final Color color;
  final bool isDark;

  const EssayDraftingDataStream({
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

    return Column(
      children: availableItems
          .map(
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Draggable<String>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 48.w,
                    padding: EdgeInsets.all(16.r),
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
                      i,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
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
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
