import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PremiumHero extends StatelessWidget {
  const PremiumHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Ultra-modern floating icon with deep glowing shadows
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            LucideIcons.crown,
            color: Colors.white,
            size: 40.r,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 1.5.seconds,
            curve: Curves.easeInOut,
          ),
        ).animate().slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack, duration: 800.ms)
         .fadeIn(),
         
        SizedBox(height: 24.h),
        
        // Gradient Shader Text for a 2026 ultra-premium feel
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            context.tr('premium.hero_title', fallback: 'Unlock Everything'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white, // Required for ShaderMask to work
              fontSize: 34.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
        ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 100.ms).fadeIn(),
        
        SizedBox(height: 12.h),
        
        Text(
          context.tr('premium.hero_subtitle', fallback: 'Reach your full potential with Vowl Premium.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? const Color(0x99FFFFFF) : const Color(0x8A000000),
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms).fadeIn(),
      ],
    );
  }
}
