import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ModernFeatureBar extends StatelessWidget {
  const ModernFeatureBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x08FFFFFF) : const Color(0x05000000),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          FeatureItem(icon: Icons.block_rounded, label: 'ZERO ADS'),
          FeatureItem(icon: Icons.auto_graph_rounded, label: '2X SPEED'),
          FeatureItem(icon: Icons.emoji_events_rounded, label: 'VIP BADGES'),
          FeatureItem(icon: Icons.workspace_premium_rounded, label: 'PRO STATUS'),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const FeatureItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 18.r),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', 
            color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
            fontSize: 7.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
