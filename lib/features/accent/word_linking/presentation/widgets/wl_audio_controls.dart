import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';

class WLAudioControls extends StatelessWidget {
  final AccentQuest quest;
  final ThemeResult theme;
  final bool isSlowMode;
  final Function(bool isSlow) onPlayAudio;

  const WLAudioControls({
    super.key,
    required this.quest,
    required this.theme,
    required this.isSlowMode,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAudioButton(
          label: "NORMAL",
          icon: Icons.volume_up_rounded,
          isActive: !isSlowMode,
          onTap: () => onPlayAudio(false),
          theme: theme,
        ),
        SizedBox(width: 16.w),
        _buildAudioButton(
          label: "SLOW",
          icon: Icons.slow_motion_video_rounded,
          isActive: isSlowMode,
          onTap: () => onPlayAudio(true),
          theme: theme,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildAudioButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeResult theme,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.9),
                    theme.primaryColor,
                  ],
                )
              : null,
          color: isActive ? null : (theme.primaryColor.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : theme.primaryColor,
              size: 22.r,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : theme.primaryColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
