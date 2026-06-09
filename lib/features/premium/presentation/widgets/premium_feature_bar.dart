import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FeatureItem(
            icon: Icons.block_rounded,
            label: 'ZERO ADS',
            isDark: isDark,
          ),
          FeatureItem(
            icon: Icons.auto_graph_rounded,
            label: '2X SPEED',
            isDark: isDark,
          ),
          FeatureItem(
            icon: Icons.emoji_events_rounded,
            label: 'VIP BADGES',
            isDark: isDark,
          ),
          FeatureItem(
            icon: Icons.workspace_premium_rounded,
            label: 'PRO STATUS',
            isDark: isDark,
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
