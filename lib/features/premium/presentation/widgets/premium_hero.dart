import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 25,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 36.r,
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
        SizedBox(height: 16.h),
        // RESPONSIVENESS: no maxLines/overflow constraint needed here -
        // this heading is allowed to wrap to a second line for longer
        // translations rather than being clipped, since it sits in a
        // scrollable column (see premium_screen.dart) and has no fixed
        // height neighbor depending on it.
        Text(
          context.tr('premium.hero_title', fallback: 'Unlock Everything'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 30.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.tr('premium.hero_subtitle', fallback: 'Reach your full potential with Vowl Premium.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? const Color(0x7DFFFFFF) : const Color(0x42000000),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
