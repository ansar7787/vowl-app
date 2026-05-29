import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

class VoiceSwapToggle extends StatelessWidget {
  final bool isPassive;
  final bool isAnswered;
  final Color primaryColor;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const VoiceSwapToggle({
    super.key,
    required this.isPassive,
    required this.isAnswered,
    required this.primaryColor,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = di.sl<HapticService>();
    final soundService = di.sl<SoundService>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleLabel("ACTIVE", !isPassive),
            SizedBox(width: 20.w),
            GestureDetector(
              onTap: () {
                if (isAnswered) return;
                onToggle(!isPassive);
                hapticService.heavy();
                soundService.playClick();
              },
              child: Container(
                width: 130.w,
                height: 65.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(35.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Energy Pulse Track
                    Center(
                      child: Container(
                        width: 100.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      left: isPassive ? 66.w : 4.w,
                      top: 4.h,
                      child: Container(
                        width: 58.w,
                        height: 53.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPassive
                              ? Icons.waves_rounded
                              : Icons.bolt_rounded,
                          color: Colors.white,
                          size: 26.r,
                        ),
                      )
                      .animate(key: ValueKey(isPassive))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20.w),
            _buildToggleLabel("PASSIVE", isPassive),
          ],
        ),
        SizedBox(height: 32.h),
        Text(
          "MODE: ${(isPassive ? "PASSIVE" : "ACTIVE")}",
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: primaryColor.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        )
        .animate(key: ValueKey(isPassive))
        .fadeIn()
        .scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }

  Widget _buildToggleLabel(String label, bool isActive) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: GoogleFonts.outfit(
        fontSize: 14.sp,
        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
        color: isActive
            ? primaryColor
            : (isDark ? Colors.white24 : Colors.black26),
        letterSpacing: 2,
      ),
      child: Text(label),
    );
  }
}
