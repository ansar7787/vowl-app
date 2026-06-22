import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  final VoidCallback onTap;

  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = plan['color'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0x0DFFFFFF) : const Color(0x08000000))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0x1AFFFFFF) : const Color(0x1E000000)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan['name'].toString().toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (plan['tag'] != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            plan['tag'] as String,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: accentColor,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${plan['days']} days of elite access',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark
                          ? const Color(0x61FFFFFF)
                          : const Color(0x61000000),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (plan['oldPrice'] != null) ...[
                      Text(
                        '₹${(plan['oldPrice'] as double).toInt()}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark
                              ? const Color(0x3DFFFFFF)
                              : const Color(0x42000000),
                          fontSize: 13.sp,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 6.w),
                    ],
                    Text(
                      '₹${(plan['price'] as double).toInt()}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Save ${((plan['oldPrice'] - plan['price']) / 1).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: accentColor,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(0.98, 0.98)),
    );
  }
}
