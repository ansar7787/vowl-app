import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuessTitleCargoCrate extends StatelessWidget {
  final String passage;
  final String correct;
  final Color color;
  final bool isDark;
  final String? selectedTitle;
  final bool isAnswered;
  final bool? isCorrect;
  final Function(String) onAccept;

  const GuessTitleCargoCrate({
    super.key,
    required this.passage,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedTitle,
    required this.isAnswered,
    required this.isCorrect,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            passage,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 32.h),
          DragTarget<String>(
            onWillAcceptWithDetails: (details) => !isAnswered,
            onAcceptWithDetails: (details) {
              onAccept(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              final Color borderClr = isAnswered
                  ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
                  : (isHovered ? color : color.withValues(alpha: 0.4));

              return Container(
                height: 70.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: borderClr.withValues(alpha: isHovered ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: borderClr,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: selectedTitle != null
                        ? Text(
                            selectedTitle!.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: isCorrect == true
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          )
                        : Text(
                            "DRAG & DROP TITLE HERE",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: color.withValues(
                                alpha: isHovered ? 0.8 : 0.4,
                              ),
                              fontSize: 13.sp,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
