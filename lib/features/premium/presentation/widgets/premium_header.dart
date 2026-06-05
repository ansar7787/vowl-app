import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
class PremiumHeader extends StatelessWidget {
  const PremiumHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: Icon(
              Icons.keyboard_backspace_rounded,
              color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x0DFFFFFF) : const Color(0x08000000),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: const Color(0xFFF59E0B), size: 14.r),
                SizedBox(width: 6.w),
                Text(
                  'VERIFIED PRO',
                  style: TextStyle(fontFamily: 'Outfit', 
                    color: isDark ? const Color(0xB3FFFFFF) : const Color(0xDE000000),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
