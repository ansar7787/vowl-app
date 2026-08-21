import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GourmetOrderPlateTray extends StatelessWidget {
  final List<String> options;
  final List<String> prices;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final List<String> selectedItems;
  final Function(String) onItemTapped;
  final VoidCallback onDragStarted;

  const GourmetOrderPlateTray({
    super.key,
    required this.options,
    required this.prices,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedItems,
    required this.onItemTapped,
    required this.onDragStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BANQUET PLATE TRAY",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.kitchen_rounded,
                color: color.withValues(alpha: 0.5),
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Scrollable Plate drawer containing Draggables
          SizedBox(
            height: 110.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, i) => _buildDraggablePlate(options[i], prices.length > i ? prices[i] : "\$3.50"),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildDraggablePlate(String item, String price) {
    final bool isSelected = selectedItems.contains(item);

    Color plateColor = color;
    if (isAnswered && isSelected) {
      plateColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Padding(
      padding: EdgeInsets.only(right: 14.w),
      child: Draggable<String>(
        data: item,
        onDragStarted: onDragStarted,
        feedback: _buildPlateCore(
          item,
          price,
          plateColor,
          isSelected,
          isDark,
          isDraggingFeedback: true,
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildPlateCore(
            item,
            price,
            plateColor,
            isSelected,
            isDark,
            isDraggingFeedback: false,
          ),
        ),
        child: InkWell(
          onTap: () => onItemTapped(item),
          borderRadius: BorderRadius.circular(16.r),
          child: _buildPlateCore(
            item,
            price,
            plateColor,
            isSelected,
            isDark,
            isDraggingFeedback: false,
          ),
        ),
      ),
    );
  }

  Widget _buildPlateCore(
    String item,
    String price,
    Color color,
    bool isSelected,
    bool isDark, {
    required bool isDraggingFeedback,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 100.r,
        height: 110.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF131326) : Colors.white),
          border: Border.all(
            color: isSelected ? Colors.white : color.withValues(alpha: 0.4),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? color : Colors.black).withValues(
                alpha: isDraggingFeedback ? 0.45 : 0.08,
              ),
              blurRadius: isDraggingFeedback ? 15 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      price,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4.h,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: color, size: 10.r),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
