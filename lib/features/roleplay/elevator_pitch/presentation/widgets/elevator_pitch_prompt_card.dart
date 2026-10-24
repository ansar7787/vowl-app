import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Card displaying the pitch prompt, scenario instructions, and time limit.
class ElevatorPitchPromptCard extends StatelessWidget {
  /// Custom instructions or objective text.
  final String? instruction;

  /// Main prompt or scenario description for the elevator pitch.
  final String prompt;

  /// Time limit in seconds allocated for this pitch.
  final int timeLimit;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates an [ElevatorPitchPromptCard] widget.
  const ElevatorPitchPromptCard({
    super.key,
    this.instruction,
    required this.prompt,
    required this.timeLimit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const Key('elevator_pitch_card_icon'),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_rounded, color: color, size: 24.r),
          ),
          SizedBox(height: 14.h),
          Text(
            (instruction ?? "Elevator Pitch").toUpperCase(),
            key: const Key('elevator_pitch_instruction_text'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              color: color,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            prompt,
            key: const Key('elevator_pitch_prompt_text'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: isDark ? AppColors.white : AppColors.slate900,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          Container(
            key: const Key('elevator_pitch_timer_badge'),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: color, size: 16.r),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    "$timeLimit SECONDS LIMIT",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

