import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PremiumUpsellContent extends StatelessWidget {
  final String titleKey;
  final String titleFallback;
  final String subtitleKey;
  final String subtitleFallback;
  final String adButtonTextKey;
  final String adButtonTextFallback;
  final VoidCallback onPremiumTap;
  final VoidCallback onAdTap;

  const PremiumUpsellContent({
    super.key,
    required this.titleKey,
    required this.titleFallback,
    required this.subtitleKey,
    required this.subtitleFallback,
    required this.adButtonTextKey,
    required this.adButtonTextFallback,
    required this.onPremiumTap,
    required this.onAdTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.g_translate_rounded,
            color: Colors.white,
            size: 28.r,
          ),
        ),
        SizedBox(height: 16.h),

        // Title
        Text(
          context.tr(titleKey, fallback: titleFallback),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8.h),

        // Subtitle
        Text(
          context.tr(subtitleKey, fallback: subtitleFallback),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),

        // Primary Premium Button
        ScaleButton(
          onTap: onPremiumTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 18.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  context.tr(
                    'translation.get_premium_button',
                    fallback: 'Get Vowl Premium',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Secondary Ad Button
        ScaleButton(
          onTap: onAdTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 18.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  context.tr(
                    adButtonTextKey,
                    fallback: adButtonTextFallback,
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
