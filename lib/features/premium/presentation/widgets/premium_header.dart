import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
          // Modern Frosted Glass Back Button
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: IconButton(
                  tooltip: context.tr('common.back', fallback: 'Back'),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 24.r,
                  ),
                ),
              ),
            ),
          ),
          
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        const Color(0xFFEA580C).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        color: const Color(0xFFF59E0B),
                        size: 14.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          context.tr('premium.verified_pro_badge', fallback: 'Verified Pro'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
