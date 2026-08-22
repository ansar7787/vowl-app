import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedPageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  
  /// The active color used for all items. Defaults to primary color if [itemColors] is null.
  final Color? activeColor;
  
  /// A specific color for each individual item. Overrides [activeColor] if provided.
  final List<Color>? itemColors;
  
  final double? activeWidth;
  final double? inactiveWidth;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const AnimatedPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeColor,
    this.itemColors,
    this.activeWidth,
    this.inactiveWidth,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultActiveColor = activeColor ?? const Color(0xFF6366F1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isSelected = index == currentIndex;
        
        // Determine the specific color for this dot
        final dotColor = itemColors != null && index < itemColors!.length 
            ? itemColors![index] 
            : defaultActiveColor;
            
        // Determine inactive color
        final inactiveColor = itemColors != null
            ? dotColor.withValues(alpha: 0.2)
            : (isDark ? Colors.white24 : Colors.black12);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: margin ?? EdgeInsets.symmetric(horizontal: 4.w),
          height: height ?? 6.h,
          width: isSelected ? (activeWidth ?? 24.w) : (inactiveWidth ?? 6.w),
          decoration: BoxDecoration(
            color: isSelected ? dotColor : inactiveColor,
            borderRadius: BorderRadius.circular((height ?? 6.h) * 2), // Ensures it's fully rounded
          ),
        );
      }),
    );
  }
}
