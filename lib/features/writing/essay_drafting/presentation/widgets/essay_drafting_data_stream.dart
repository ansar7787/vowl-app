import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Draggable item tray presenting candidate draft sentences for structural essay placement.
class EssayDraftingDataStream extends StatelessWidget {
  /// The candidate essay sentence segments available for placement.
  final List<String> items;

  /// Current blueprint slot assignments mapping slot keys to sentence strings.
  final Map<String, String?> slots;

  /// Theme accent color applied to cards and highlight borders.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Optional callback fired during card drag movements.
  final void Function(DragUpdateDetails)? onDragUpdate;

  /// Optional callback fired when an item card is tapped.
  final void Function(String item)? onItemTap;

  /// Creates an [EssayDraftingDataStream] widget.
  const EssayDraftingDataStream({
    super.key,
    required this.items,
    required this.slots,
    required this.color,
    required this.isDark,
    this.onDragUpdate,
    this.onItemTap,
  });

  Widget _buildItem(
    BuildContext context,
    String text, {
    bool isFeedback = false,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      width: isFeedback ? (screenWidth - 48.w) : double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isFeedback
            ? color
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: isFeedback
            ? null
            : Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.5,
              ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: isFeedback ? 0.4 : (isDark ? 0.2 : 0.06),
            ),
            blurRadius: isFeedback ? 18 : 8,
            offset: Offset(0, isFeedback ? 6 : 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.drag_indicator_rounded,
              color: isFeedback
                  ? Colors.white.withValues(alpha: 0.8)
                  : color.withValues(alpha: 0.7),
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isFeedback
                    ? Colors.white
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.black87),
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w500,
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
                key: Key('essay_drafting_draggable_$i'),
                data: i,
                onDragUpdate: onDragUpdate,
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildItem(context, i, isFeedback: true),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildItem(context, i),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemTap?.call(i),
                  child: _buildItem(context, i),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
