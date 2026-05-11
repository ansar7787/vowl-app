import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class GameErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final Color primaryColor;

  const GameErrorWidget({
    super.key,
    this.title = 'Quest Unavailable',
    this.message =
        'We couldn\'t load this quest right now. Please check your connection or try another level.',
    required this.onRetry,
    required this.onBack,
    this.primaryColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: GlassTile(
          borderRadius: BorderRadius.circular(32.r),
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon with Glow
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.report_gmailerrorred_rounded,
                  size: 48.r,
                  color: Colors.redAccent,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              SizedBox(height: 24.h),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),

              SizedBox(height: 12.h),

              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 32.h),

              // Action Buttons
              ScaleButton(
                onTap: onRetry,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'TRY AGAIN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              ScaleButton(
                onTap: onBack,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    'GO BACK',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
