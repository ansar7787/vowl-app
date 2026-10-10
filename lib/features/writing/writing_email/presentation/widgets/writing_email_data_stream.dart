import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WritingEmailDataStream extends StatelessWidget {
  final List<String> items;
  final Map<String, String?> slots;
  final Color color;
  final bool isDark;
  final Function(String) onTapItem;

  const WritingEmailDataStream({
    super.key,
    required this.items,
    required this.slots,
    required this.color,
    required this.isDark,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    List<String> availableItems = List.from(items);
    for (var val in slots.values) {
      if (val != null) {
        availableItems.remove(val);
      }
    }

    return Container(
      constraints: BoxConstraints(minHeight: 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: availableItems
            .map(
              (i) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Semantics(
                  label: "Email part: $i",
                  hint: "Double tap to place in next available slot",
                  button: true,
                  child: GestureDetector(
                    onTap: () => onTapItem(i),
                    child: Draggable<String>(
                      data: i,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 280.w,
                          padding: EdgeInsets.all(16.r),
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
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      child: Container(
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
                              color: color.withValues(
                                alpha: isDark ? 0.35 : 0.15,
                              ),
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
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
