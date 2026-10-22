import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class EmergencyHubTelexCard extends StatelessWidget {
  final String instruction;
  final String dispatcherQuestion;
  final int urgencyLevel;
  final bool isDark;

  const EmergencyHubTelexCard({
    super.key,
    required this.instruction,
    required this.dispatcherQuestion,
    required this.urgencyLevel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    Widget iconWidget = Container(
      key: const Key('emergency_hub_telex_warning_icon'),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: tokens.gameIncorrect,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.warning_amber_rounded,
        color: isDark ? AppColors.deepDark : Colors.white,
        size: 20.r,
      ),
    );

    if (!reduceMotion) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 1.2.seconds,
            curve: Curves.easeInOut,
          );
    }

    Widget broadcastText = Text(
      "INCOMING BROADCAST",
      key: const Key('emergency_hub_telex_broadcast_title'),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13.sp,
        color: tokens.gameIncorrect,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
      ),
      softWrap: true,
    );

    if (!reduceMotion) {
      broadcastText = broadcastText
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2.seconds);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: tokens.gameIncorrect.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              iconWidget,
              SizedBox(width: 10.w),
              Expanded(child: broadcastText),
            ],
          ),
          SizedBox(height: 14.h),

          // Instruction Field (First)
          Text(
            instruction,
            key: const Key('emergency_hub_telex_instruction_text'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
            softWrap: true,
          ),
          SizedBox(height: 10.h),

          // Dispatcher Question Field (Second)
          if (dispatcherQuestion.isNotEmpty)
            Text(
              dispatcherQuestion,
              key: const Key('emergency_hub_telex_question_text'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.45,
              ),
              softWrap: true,
            ),

          SizedBox(height: 18.h),
          Divider(
            color: tokens.gameIncorrect.withValues(alpha: 0.2),
            thickness: 1.5,
            height: 1,
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Text(
                "URGENCY LEVEL",
                key: const Key('emergency_hub_telex_urgency_label'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final isActive = index < urgencyLevel;
                    return Expanded(
                      child: Container(
                        key: Key('emergency_hub_urgency_bar_$index'),
                        height: 8.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (urgencyLevel >= 4
                                    ? tokens.gameIncorrect
                                    : (urgencyLevel >= 3
                                          ? Colors.orange
                                          : Colors.amber))
                              : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
