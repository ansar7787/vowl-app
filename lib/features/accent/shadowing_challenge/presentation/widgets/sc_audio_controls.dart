import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SCAudioControls extends StatelessWidget {
  final ThemeResult theme;
  final bool isPlaying;
  final VoidCallback onPlayAudio;
  final bool isMidnight;

  const SCAudioControls({
    super.key,
    required this.theme,
    required this.isPlaying,
    required this.onPlayAudio,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onPlayAudio,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withValues(alpha: 0.9),
              theme.primaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPlaying)
              SizedBox(
                width: 60.w,
                child: const HarmonicWaves(color: Colors.white, height: 30),
              ).animate().fadeIn()
            else
              Icon(Icons.volume_up_rounded, color: Colors.white, size: 28.r),
            SizedBox(width: 12.w),
            Text(
              "PREVIEW",
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
    ).animate().fadeIn(delay: 200.ms).scale();
  }
}
