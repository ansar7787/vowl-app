import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color coloreab308 = Color(0xFFEAB308);
}

class ModernFeatureBar extends StatelessWidget {
  const ModernFeatureBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('premium.whats_included', fallback: "Everything you get"),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24.h),
          
          _buildGroupedFeature(
            context,
            icon: LucideIcons.brainCircuit,
            title: context.tr('premium.group_ai_title', fallback: 'Complete AI Suite'),
            subtitle: context.tr(
              'premium.group_ai_desc', 
              fallback: 'Unlimited Smart Reply, Photo Vocabulary, Scan & Learn, and Offline AI Translations.'
            ),
            color: AppColors.violet500,
            isDark: isDark,
          ),
          SizedBox(height: 24.h),
          
          _buildGroupedFeature(
            context,
            icon: LucideIcons.shieldCheck,
            title: context.tr('premium.group_focus_title', fallback: 'Pure Focus Mode'),
            subtitle: context.tr(
              'premium.group_focus_desc', 
              fallback: 'Zero interruptions with a 100% Ad-Free experience and full Anywhere Offline Mode.'
            ),
            color: AppColors.emerald500,
            isDark: isDark,
          ),
          SizedBox(height: 24.h),

          _buildGroupedFeature(
            context,
            icon: LucideIcons.crown,
            title: context.tr('premium.group_vip_title', fallback: 'Ultimate VIP Access'),
            subtitle: context.tr(
              'premium.group_vip_desc', 
              fallback: 'Unlock all Vaults instantly, claim 100 free coins daily, and flaunt Golden VIP Badges.'
            ),
            color: _LocalPalette.coloreab308,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: color, size: 24.r),
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
