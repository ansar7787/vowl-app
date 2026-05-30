import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PremiumSuccessOverlay extends StatelessWidget {
  final VoidCallback onBeginAdventure;

  const PremiumSuccessOverlay({
    super.key,
    required this.onBeginAdventure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33F59E0B),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF59E0B),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 40,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .shimmer(duration: 2.seconds),
          SizedBox(height: 24.h),
          Text(
            "UPGRADE SUCCESSFUL",
            style: GoogleFonts.shareTechMono(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF59E0B),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Welcome to Vowl Pro. Your elite learning journey starts now!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24.h),
          ScaleButton(
            onTap: onBeginAdventure,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 32.w,
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "BEGIN ADVENTURE",
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade().scale(begin: const Offset(0.9, 0.9));
  }
}
