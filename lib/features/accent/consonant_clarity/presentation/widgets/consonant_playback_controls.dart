import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ConsonantPlaybackControls extends StatelessWidget {
  final double playbackRate;
  final bool isPlaying;
  final VoidCallback onPlayNormal;
  final VoidCallback onPlaySlow;
  final bool isDark;
  final ThemeResult theme;
  final bool isMidnight;

  const ConsonantPlaybackControls({
    super.key,
    required this.playbackRate,
    required this.isPlaying,
    required this.onPlayNormal,
    required this.onPlaySlow,
    required this.isDark,
    required this.theme,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSpeedButton(
          label: "NORMAL",
          child: Icon(
            Icons.play_arrow_rounded,
            color: playbackRate == 1.0
                ? theme.primaryColor
                : (isDark ? Colors.white38 : Colors.black38),
            size: 24.r,
          ),
          isActive: playbackRate == 1.0,
          onTap: onPlayNormal,
        ),
        SizedBox(width: 16.w),
        _buildSpeedButton(
          label: "SLOW",
          child: Text(
            "🐢",
            style: TextStyle(
              fontSize: 20.sp,
              color: playbackRate == 0.75
                  ? theme.primaryColor
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
          isActive: playbackRate == 0.75,
          onTap: onPlaySlow,
        ),
      ],
    );
  }

  Widget _buildSpeedButton({
    required String label,
    required Widget child,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive
        ? theme.primaryColor
        : (isDark ? Colors.white38 : Colors.black38);

    return ScaleButton(
      onTap: isPlaying ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primaryColor.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isActive
                ? theme.primaryColor
                : (isDark ? Colors.white10 : Colors.black12),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            SizedBox(width: 10.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
