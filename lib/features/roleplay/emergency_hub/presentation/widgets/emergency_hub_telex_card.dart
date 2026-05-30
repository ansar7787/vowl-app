import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmergencyHubTelexCard extends StatelessWidget {
  final String telex;
  final bool isDark;

  const EmergencyHubTelexCard({
    super.key,
    required this.telex,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20.r),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 1.2.seconds,
                    curve: Curves.easeInOut,
                  ),
              SizedBox(width: 10.w),
              Text(
                "CRITICAL INCOMING HAZARD ALERT",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.redAccent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            telex,
            style: GoogleFonts.fredoka(
              fontSize: 18.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
