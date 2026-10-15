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
        fontSize: 12.sp,
        color: tokens.gameIncorrect,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w800,
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
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: tokens.gameIncorrect,
          width: 2.0,
        ),
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
          SizedBox(height: 16.h),

          // Instruction Field (First)
          Text(
            instruction,
            key: const Key('emergency_hub_telex_instruction_text'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
            softWrap: true,
          ),
          SizedBox(height: 12.h),

          // Dispatcher Question Field (Second)
          if (dispatcherQuestion.isNotEmpty)
            Text(
              dispatcherQuestion,
              key: const Key('emergency_hub_telex_question_text'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                height: 1.4,
              ),
              softWrap: true,
            ),

          SizedBox(height: 20.h),
          Divider(
            color: tokens.gameIncorrect.withValues(alpha: 0.3),
            thickness: 2,
            height: 1,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                "URGENCY LEVEL",
                key: const Key('emergency_hub_telex_urgency_label'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
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
                                          : Colors.yellow))
                              : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(2.r),
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
