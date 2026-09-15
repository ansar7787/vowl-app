import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ShadowPlaybackButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onPlay;
  final bool isDark;
  final bool isPlaying;

  const ShadowPlaybackButton({
    super.key,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onPlay,
    required this.isDark,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play $label audio',
      child: GestureDetector(
        onTap: isPlaying ? null : onPlay,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.1)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Label
              AutoSizeText(
                label,
                maxLines: 1,
                minFontSize: 10,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Play icon
              Icon(
                isActive ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                color: color,
                size: 24.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
