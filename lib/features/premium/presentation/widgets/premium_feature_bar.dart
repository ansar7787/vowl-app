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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            context.tr('premium.whats_included', fallback: "PREMIUM PERKS"),
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white70 : AppColors.slate500,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
              _buildListFeature(context, icon: LucideIcons.bot, title: context.tr('premium.feature_smart_reply', fallback: 'AI Smart Reply'), color: IllustrationColors.brightBlue),
              _buildListFeature(context, icon: LucideIcons.camera, title: context.tr('premium.feature_photo_vocab', fallback: 'Photo Vocabulary'), color: AppColors.teal500),
              _buildListFeature(context, icon: LucideIcons.scan, title: context.tr('premium.feature_scan_learn', fallback: 'Scan & Learn Documents'), color: AppColors.indigo500),
              _buildListFeature(context, icon: LucideIcons.sparkles, title: context.tr('premium.feature_translations', fallback: 'Offline AI Translations'), color: AppColors.rose500),
              _buildListFeature(context, icon: LucideIcons.shieldCheck, title: context.tr('premium.feature_zero_ads', fallback: 'No Ads (100% Ad-Free)'), color: AppColors.emerald500),
              _buildListFeature(context, icon: LucideIcons.zap, title: context.tr('premium.feature_2x_speed', fallback: 'Enhanced Learning Tools'), color: AppColors.amber500),
              _buildListFeature(context, icon: LucideIcons.wifiOff, title: context.tr('premium.feature_play_offline', fallback: 'Play Offline Anywhere'), color: AppColors.slate500),
              _buildListFeature(context, icon: LucideIcons.unlock, title: context.tr('premium.feature_unlimited_levels', fallback: 'Unlock All Difficulty Vaults'), color: _LocalPalette.color06b6d4),
              _buildListFeature(context, icon: LucideIcons.gift, title: context.tr('premium.feature_vip_loot', fallback: '100 Free Bonus Coins Daily'), color: IllustrationColors.vibrantPink),
              _buildListFeature(context, icon: LucideIcons.award, title: context.tr('premium.feature_vip_badges', fallback: 'Exclusive VIP Badges'), color: _LocalPalette.coloreab308, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    bool isLast = false,
  }) {
    // If a translation file returns ALL CAPS (e.g. "ZERO ADS"), normalize it to Title Case.
    String formattedTitle = title;
    if (title.isNotEmpty && title == title.toUpperCase()) {
      formattedTitle = title.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              formattedTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
