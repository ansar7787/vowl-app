import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class KidsRoomFurnitureRenderer extends StatelessWidget {
  final Map<String, dynamic>? item;
  final String category;

  const KidsRoomFurnitureRenderer({
    super.key,
    required this.item,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      // Empty slot placeholder
      return Container(
        width: _getWidthForCategory(),
        height: _getHeightForCategory(),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2.w,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Instead of just an emoji in a circle, render a styled container
    // that looks like actual furniture with depth and shadows.
    return SizedBox(
      width: _getWidthForCategory(),
      height: _getHeightForCategory(),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Shadow
          Container(
            width: _getWidthForCategory() * 0.8,
            height: 15.h,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Furniture Base/Platform
          if (category != 'window') // Windows don't need a floor platform
            Container(
              margin: EdgeInsets.only(bottom: 5.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.2 : 0.9),
                    Colors.white.withValues(alpha: isDark ? 0.05 : 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.3 : 1.0),
                  width: 2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
                    blurRadius: 15,
                    spreadRadius: -2,
                    offset: const Offset(0, -2), // Inner top glow
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),

          // The item icon (scaled up)
          Center(
            child:
                Text(
                      item!['icon'] as String,
                      style: TextStyle(fontSize: _getIconSizeForCategory()),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    )
                    .fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }

  double _getWidthForCategory() {
    switch (category) {
      case 'bed':
        return 160.w;
      case 'window':
        return 120.w;
      case 'shelf':
        return 100.w;
      case 'toy':
        return 80.w;
      case 'plant':
        return 70.w;
      case 'rug':
        return 200.w;
      default:
        return 100.w;
    }
  }

  double _getHeightForCategory() {
    switch (category) {
      case 'bed':
        return 120.h;
      case 'window':
        return 140.h;
      case 'shelf':
        return 150.h;
      case 'toy':
        return 80.h;
      case 'plant':
        return 100.h;
      case 'rug':
        return 40.h;
      default:
        return 100.h;
    }
  }

  double _getIconSizeForCategory() {
    switch (category) {
      case 'bed':
        return 80.sp;
      case 'window':
        return 90.sp;
      case 'shelf':
        return 80.sp;
      case 'toy':
        return 50.sp;
      case 'plant':
        return 60.sp;
      case 'rug':
        return 70.sp;
      default:
        return 60.sp;
    }
  }
}
