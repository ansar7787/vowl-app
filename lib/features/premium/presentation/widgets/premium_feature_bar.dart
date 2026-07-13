import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ModernFeatureBar extends StatelessWidget {
  const ModernFeatureBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x0CFFFFFF) : const Color(0x08000000),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
        ),
      ),
      child: Row(
        // RESPONSIVENESS FIX: the original Row let each FeatureItem take
        // its intrinsic (unconstrained) width. On a small phone combined
        // with longer translated labels (German compounds, Indian
        // regional scripts), four tightly-packed unconstrained items can
        // exceed the row's available width and overflow horizontally.
        // Giving each item equal `Expanded` width, with the label allowed
        // to wrap to two lines instead, makes this overflow-proof at any
        // text length while preserving the original "4 equal columns"
        // layout exactly when text is short (English).
        children: [
          Expanded(
            child: FeatureItem(
              icon: Icons.block_rounded,
              label: context.tr('premium.feature_zero_ads', fallback: 'Zero Ads'),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: FeatureItem(
              icon: Icons.auto_graph_rounded,
              label: context.tr('premium.feature_2x_speed', fallback: '2x Learning Speed'),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: FeatureItem(
              icon: Icons.emoji_events_rounded,
              label: context.tr('premium.feature_vip_badges', fallback: 'VIP Badges'),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: FeatureItem(
              icon: Icons.lock_open_rounded,
              label: context.tr('premium.feature_unlimited_levels', fallback: 'Unlimited Levels'),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: FeatureItem(
              icon: Icons.airplanemode_active_rounded,
              label: context.tr(
                'premium.feature_play_offline',
                fallback: 'Play Offline',
              ),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: const Color(0xFFF59E0B), size: 18.r),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
            fontSize: 7.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
