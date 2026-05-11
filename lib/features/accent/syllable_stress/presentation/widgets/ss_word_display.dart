import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SsWordDisplay extends StatelessWidget {
  final String word;
  final String? phoneticHint;
  final bool isPlaying;
  final Color primaryColor;
  final VoidCallback onPlayTap;
  final bool isMidnight;

  const SsWordDisplay({
    super.key,
    required this.word,
    this.phoneticHint,
    required this.isPlaying,
    required this.primaryColor,
    required this.onPlayTap,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ScaleButton(
          onTap: onPlayTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withValues(alpha: 0.9), primaryColor],
              ),
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPlaying)
                  HarmonicWaves(
                    color: Colors.white,
                    height: 30.h,
                    width: 40.w,
                  ).animate().fadeIn()
                else
                  Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 28.r,
                  ),
                SizedBox(width: 12.w),
                Text(
                  "LISTEN",
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 40.h),
        GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 32.h),
          borderRadius: BorderRadius.circular(40.r),
          borderColor: primaryColor.withValues(alpha: 0.3),
          child: Column(
            children: [
              if (phoneticHint != null && phoneticHint!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    "[ $phoneticHint ]",
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: primaryColor.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 6,
                  ),
                  maxLines: 1,
                ),
              ),
              SizedBox(height: 8.h),
              _buildSyllableVisual(word, isDark, primaryColor),
            ],
          ),
        ).animate().fadeIn().scale(),
      ],
    );
  }

  Widget _buildSyllableVisual(String word, bool isDark, Color color) {
    // Note: In an ideal world we'd use a syllable-splitting library,
    // but here we can at least show a sub-caption indicating it's a multi-beat word.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        "RHYTHM: • •", // Simplified rhythm indicator
        style: GoogleFonts.outfit(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: 0.7),
          letterSpacing: 2,
        ),
      ),
    );
  }
}
