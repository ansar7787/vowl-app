import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

// Glow Background Effect
class StaticGlow extends StatelessWidget {
  final Color color;
  const StaticGlow({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.r,
      height: 350.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}

// Premium Header Bar
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
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.keyboard_backspace_rounded,
              color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x0DFFFFFF) : const Color(0x08000000),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: const Color(0xFFF59E0B), size: 14.r),
                SizedBox(width: 6.w),
                Text(
                  'VERIFIED PRO',
                  style: GoogleFonts.outfit(
                    color: isDark ? const Color(0xB3FFFFFF) : const Color(0xDE000000),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Premium Hero Visuals
class PremiumHero extends StatelessWidget {
  const PremiumHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 70.r,
          height: 70.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0x4DF59E0B), blurRadius: 20),
            ],
          ),
          child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36.r),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
        SizedBox(height: 16.h),
        Text(
          'Unlimited Growth.',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 30.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

// Subscription Options Plan Card
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
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (plan['tag'] != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            plan['tag'] as String,
                            style: GoogleFonts.outfit(
                              color: accentColor,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${plan['days']} days of elite access',
                    style: GoogleFonts.outfit(
                      color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
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
                    if (plan['oldPrice'] != null)
                      Text(
                        '₹${(plan['oldPrice'] as double).toInt()}',
                        style: GoogleFonts.outfit(
                          color: isDark ? const Color(0x3DFFFFFF) : const Color(0x42000000),
                          fontSize: 13.sp,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    SizedBox(width: 6.w),
                    Text(
                      '₹${(plan['price'] as double).toInt()}',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Features bar showing standard pro rewards
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
          style: GoogleFonts.outfit(
            color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
            fontSize: 7.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
