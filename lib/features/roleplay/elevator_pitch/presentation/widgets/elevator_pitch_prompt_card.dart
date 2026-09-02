import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ElevatorPitchPromptCard extends StatelessWidget {
  final String prompt;
  final int timeLimit;
  final Color color;
  final bool isDark;

  const ElevatorPitchPromptCard({
    super.key,
    required this.prompt,
    required this.timeLimit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: color,
                  size: 24.r,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ELEVATOR SPEECH PROMPT:",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    color: color,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  prompt,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 16.h),
                Divider(
                  color: color.withValues(alpha: 0.15),
                  thickness: 1,
                  height: 1,
                ),
                SizedBox(height: 12.h),
                TweenAnimationBuilder<double>(
                  key: ValueKey(prompt),
                  tween: Tween(begin: timeLimit.toDouble(), end: 0.0),
                  duration: Duration(seconds: timeLimit),
                  builder: (context, value, child) {
                    final int secondsLeft = value.ceil();
                    final int wordsSpoken = ((timeLimit - value) * 1.5)
                        .floor(); // Fake words per sec

                    final bool isLowTime = secondsLeft <= 10;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: isLowTime
                                  ? Colors.redAccent
                                  : color.withValues(alpha: 0.7),
                              size: 14.r,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "00:${secondsLeft.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: isLowTime
                                    ? Colors.redAccent
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.text_snippet_outlined,
                              color: color.withValues(alpha: 0.7),
                              size: 14.r,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "$wordsSpoken WORDS",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
