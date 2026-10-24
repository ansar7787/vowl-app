import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
}

/// Tray displaying available menu items, ingredients, and course choices.
class GourmetOrderPlateTray extends StatelessWidget {
  /// Available dish or beverage options.
  final List<String> options;

  /// Price labels corresponding to each option.
  final List<String> prices;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Whether the player has submitted an order.
  final bool isAnswered;

  /// Whether the submitted order was correct.
  final bool? isCorrect;

  /// Currently selected menu item names.
  final List<String> selectedItems;

  /// Callback fired when an item is tapped.
  final Function(String) onItemTapped;

  /// Callback fired when dragging of an item begins.
  final VoidCallback onDragStarted;

  /// Creates a [GourmetOrderPlateTray] widget.
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
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    Widget content = Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MENU OPTIONS",
                key: const Key('gourmet_order_plate_tray_title'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: color,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.restaurant_rounded,
                key: const Key('gourmet_order_plate_tray_icon'),
                color: color.withValues(alpha: 0.7),
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Plate grid (Wrap) containing Draggables.
          // Using Wrap instead of horizontal scroll prevents drag-vs-scroll gesture conflicts.
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            children: List.generate(
              options.length,
              (i) => _buildDraggablePlate(
                options[i],
                prices.length > i ? prices[i] : "\$3.50",
                i,
              ),
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      content = content.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
    }

    return content;
  }

  Widget _buildDraggablePlate(String item, String price, int index) {
    final bool isSelected = selectedItems.contains(item);

    Color plateColor = color;
    if (isAnswered && isSelected) {
      plateColor = (isCorrect ?? false)
          ? AppColors.gameCorrect
          : AppColors.gameIncorrect;
    }

    return Draggable<String>(
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
        key: Key('gourmet_order_plate_$index'),
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
      child: Semantics(
        label: '$item, $price',
        selected: isSelected,
        button: true,
        excludeSemantics: true,
        child: Container(
          width: 142.w,
          constraints: BoxConstraints(minHeight: 82.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: isSelected
                ? color
                : (isDark ? _LocalPalette.color131326 : Colors.white),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : color.withValues(alpha: isDark ? 0.35 : 0.25),
              width: isSelected ? 2.5 : 1.5,
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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.toUpperCase(),
                      key: Key('gourmet_order_plate_text_$item'),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : const Color(0xFF1E293B)),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.22)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        price,
                        key: Key('gourmet_order_plate_price_$item'),
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      key: Key('gourmet_order_plate_check_$item'),
                      color: color,
                      size: 12.r,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
