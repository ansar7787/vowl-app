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

  Widget _buildItem(BuildContext context, String text, {bool isFeedback = false}) {
    return Container(
      width: isFeedback ? MediaQuery.of(context).size.width - 48.w : double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isFeedback ? color : (isDark ? Colors.black87 : Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: isFeedback
            ? null
            : Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isFeedback ? 0.4 : (isDark ? 0.35 : 0.15)),
            blurRadius: isFeedback ? 20 : 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: isFeedback ? Colors.white70 : color.withValues(alpha: 0.6),
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: isFeedback ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 14.sp,
                fontWeight: isFeedback ? FontWeight.w500 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  child: _buildItem(context, i, isFeedback: true),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildItem(context, i),
                ),
                child: _buildItem(context, i),
              ),
            ),
          )
          .toList(),
    );
  }
}
