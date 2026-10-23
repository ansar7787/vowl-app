import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Customs terminal screen card displaying traveler prompt and inspector instructions.
class TravelDeskCustomsTerminal extends StatelessWidget {
  /// Customs inspector instruction text.
  final String instruction;

  /// Traveler dialogue prompt or statement.
  final String prompt;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates a [TravelDeskCustomsTerminal] widget.
  const TravelDeskCustomsTerminal({
    super.key,
    required this.instruction,
    required this.prompt,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('travel_desk_customs_terminal'),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.12),
      color: isDark ? AppColors.deepDark : Colors.white,
      surfaceTintColor: color.withValues(alpha: 0.05),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction Row at top
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 16.r,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Divider(
                height: 1,
                thickness: 1,
                color: color.withValues(alpha: 0.1),
              ),
            ),

            // Main Prompt UI
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final reduceMotion =
                        MediaQuery.disableAnimationsOf(context) ||
                        VowlMotion.lowAnimationModeOverride.value;
                    Widget icon = Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.record_voice_over_rounded,
                        color: color,
                        size: 22.r,
                      ),
                    );

                    if (!reduceMotion) {
                      icon = icon
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.08, 1.08),
                            duration: 2.seconds,
                            curve: Curves.easeInOutSine,
                          );
                    }
                    return icon;
                  },
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TRAVELER REQUEST",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          color: color,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        "\"$prompt\"",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.black87,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
