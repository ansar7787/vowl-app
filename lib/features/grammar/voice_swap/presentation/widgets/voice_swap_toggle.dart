import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildToggleLabel(
              "ACTIVE",
              !isPassive,
              const ValueKey("voice_label_active"),
              () {
                if (isAnswered || !isPassive) return;
                onToggle(false);
                hapticService.selection();
                soundService.playClick();
              },
            ),
            SizedBox(width: 14.w),
            Semantics(
              button: true,
              enabled: !isAnswered,
              label:
                  'Voice mode toggle. Currently ${isPassive ? "Passive" : "Active"}. Double tap to switch to ${isPassive ? "Active" : "Passive"}.',
              child: GestureDetector(
                key: const ValueKey('voice_toggle_switch'),
                onTap: () {
                  if (isAnswered) return;
                  onToggle(!isPassive);
                  hapticService.heavy();
                  soundService.playClick();
                },
                child: Container(
                  width: 96.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Track guide
                      Center(
                        child: Container(
                          width: 70.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        left: isPassive ? 52.w : 4.w,
                        top: 4.h,
                        child: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPassive
                                ? Icons.waves_rounded
                                : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 20.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            _buildToggleLabel(
              "PASSIVE",
              isPassive,
              const ValueKey("voice_label_passive"),
              () {
                if (isAnswered || isPassive) return;
                onToggle(true);
                hapticService.selection();
                soundService.playClick();
              },
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Builder(
          builder: (context) {
            final textWidget = Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.16),
                  width: 1,
                ),
              ),
              child: Text(
                "MODE: ${(isPassive ? "PASSIVE" : "ACTIVE")}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.6,
                ),
              ),
            );
            if (reduceMotion) return textWidget;
            return textWidget
                .animate(key: ValueKey(isPassive))
                .fadeIn(duration: 200.ms)
                .scale(
                  begin: const Offset(0.96, 0.96),
                  end: const Offset(1, 1),
                );
          },
        ),
      ],
    );
  }

  Widget _buildToggleLabel(
    String label,
    bool isActive,
    Key key,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? primaryColor
                : (isDark ? Colors.white70 : AppColors.slate600),
            letterSpacing: 0.5,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
