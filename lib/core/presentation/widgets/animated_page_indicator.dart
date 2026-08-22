import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedPageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Color activeColor;

  const AnimatedPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 6.h,
          width: isSelected ? 24.w : 6.w,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }
}
