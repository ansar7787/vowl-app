import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModernFeatureBar extends StatelessWidget {
  const ModernFeatureBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Convert from a congested horizontal row to a beautiful, scroll-safe vertical list
    // This allows ample room for localization text expansion and accessibility scaling.
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x0CFFFFFF) : const Color(0x04000000),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFeatureRow(
            context,
            icon: LucideIcons.sparkles,
            title: context.tr('premium.feature_translations', fallback: 'Instant Translations'),
            subtitle: context.tr('premium.feature_translations_desc', fallback: 'Ad-free, on-device AI hints in your native language.'),
            isDark: isDark,
            isHighlight: true,
          ),
          SizedBox(height: 16.h),
          _buildFeatureRow(
            context,
            icon: Icons.block_rounded,
            title: context.tr('premium.feature_zero_ads', fallback: 'Zero Interruptions'),
            subtitle: context.tr('premium.feature_zero_ads_desc', fallback: 'Completely ad-free learning experience.'),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildFeatureRow(
            context,
            icon: Icons.auto_graph_rounded,
            title: context.tr('premium.feature_2x_speed', fallback: '2x Learning Speed'),
            subtitle: context.tr('premium.feature_2x_speed_desc', fallback: 'Master concepts faster with advanced tracking.'),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildFeatureRow(
            context,
            icon: Icons.airplanemode_active_rounded,
            title: context.tr('premium.feature_play_offline', fallback: 'Offline Mode'),
            subtitle: context.tr('premium.feature_play_offline_desc', fallback: 'Download lessons and learn anywhere.'),
            isDark: isDark,
          ),
          SizedBox(height: 16.h),
          _buildFeatureRow(
            context,
            icon: Icons.lock_open_rounded,
            title: context.tr('premium.feature_unlimited_levels', fallback: 'Unlimited Access'),
            subtitle: context.tr('premium.feature_unlimited_levels_desc', fallback: 'Unlock all elite and master difficulty levels.'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    bool isHighlight = false,
  }) {
    final primaryColor = isHighlight ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: primaryColor, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 13.sp,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
