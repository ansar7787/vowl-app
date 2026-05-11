import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceToggleIndicator extends StatelessWidget {
  final String instruction; // e.g. "Active → Passive"
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const VoiceToggleIndicator({
    super.key,
    required this.instruction,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPassiveGoal =
        instruction.toLowerCase().contains("passive") &&
        instruction.contains("→");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isMidnight
            ? Colors.black.withValues(alpha: 0.2)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVoiceLabel("ACTIVE", !isPassiveGoal),
          SizedBox(width: 12.w),
          Icon(
                Icons.east_rounded,
                size: 16.r,
                color: primaryColor.withValues(alpha: 0.6),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 2.seconds,
                color: primaryColor.withValues(alpha: 0.2),
              ),
          SizedBox(width: 12.w),
          _buildVoiceLabel("PASSIVE", isPassiveGoal),
        ],
      ),
    );
  }

  Widget _buildVoiceLabel(String label, bool isGoal) {
    return AnimatedContainer(
      duration: 400.ms,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isGoal ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: isGoal
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: isGoal
              ? Colors.white
              : (isDark ? Colors.white38 : Colors.black26),
        ),
      ),
    );
  }
}
