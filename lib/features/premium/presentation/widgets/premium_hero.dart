import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          style: TextStyle(fontFamily: 'Outfit', 
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
