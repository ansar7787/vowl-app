import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class VowelPlaybackControls extends StatelessWidget {
  final double playbackRate;
  final int listenCount;
  final int maxListens;
  final bool isPlaying;
  final VoidCallback onPlay;
  final Function(double) onRateChange;
  final bool isDark;
  final bool isMidnight;
  final ThemeResult theme;

  const VowelPlaybackControls({
    super.key,
    required this.playbackRate,
    required this.listenCount,
    required this.maxListens,
    required this.isPlaying,
    required this.onPlay,
    required this.onRateChange,
    required this.isDark,
    this.isMidnight = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleButton(
          onTap: onPlay,
          child: Container(
            padding: EdgeInsets.all(30.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.5),
                  theme.primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 50.r,
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPlaybackToggle("NORMAL", 1.0),
            SizedBox(width: 12.w),
            _buildPlaybackToggle("SLOW 🐢", 0.6),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          "Listen: $listenCount / $maxListens",
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackToggle(String label, double rate) {
    bool isSelected = playbackRate == rate;
    return ScaleButton(
      onTap: () => onRateChange(rate),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : (isDark ? Colors.white10 : Colors.black12),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
