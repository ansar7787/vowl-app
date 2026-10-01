import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/illustration_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color06b6d4 = Color(0xFF06B6D4);
  static const Color coloreab308 = Color(0xFFEAB308);
}

class ModernFeatureBar extends StatelessWidget {
  const ModernFeatureBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
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
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _buildFeatureChip(
                context,
                icon: LucideIcons.bot,
                title: 'AI Smart Reply',
                color: IllustrationColors.brightBlue,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.camera,
                title: 'Photo Vocab',
                color: AppColors.teal500,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.scan,
                title: 'Scan & Learn',
                color: AppColors.indigo500,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.shieldCheck,
                title: 'Ad-Free',
                color: AppColors.emerald500,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.sparkles,
                title: 'Offline AI',
                color: AppColors.rose500,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.wifiOff,
                title: 'Offline Mode',
                color: AppColors.slate500,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.unlock,
                title: 'All Vaults',
                color: _LocalPalette.color06b6d4,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.gift,
                title: 'Daily Loot',
                color: IllustrationColors.vibrantPink,
                isDark: isDark,
              ),
              _buildFeatureChip(
                context,
                icon: LucideIcons.award,
                title: 'VIP Badges',
                color: _LocalPalette.coloreab308,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    // Calculates a width that fits exactly 2 columns with a 12px gap
    final screenWidth = MediaQuery.of(context).size.width;
    // 24 padding from screen edges * 2 = 48
    // 20 padding from container * 2 = 40
    // 12 gap between columns
    final availableWidth = screenWidth - 48.w - 40.w - 12.w;
    final chipWidth = availableWidth / 2;

    return Container(
      width: chipWidth,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
