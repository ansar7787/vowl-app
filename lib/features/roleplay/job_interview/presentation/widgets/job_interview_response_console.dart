import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

import 'package:vowl/core/theme/vowl_motion.dart';

class JobInterviewResponseConsole extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final bool? isCorrect;
  final Function(int, int) onOptionSelected;

  const JobInterviewResponseConsole({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isCorrect,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('job_interview_response_console'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        options.length,
        (i) => _buildResponseStone(context, i, options[i]),
      ),
    );
  }

  Widget _buildResponseStone(BuildContext context, int index, String text) {
    final bool isSelected = selectedIndex == index;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Color stoneColor = color;
    if (isAnswered) {
      if (isSelected) {
        stoneColor = (isCorrect ?? false)
            ? AppColors.gameCorrect
            : AppColors.gameIncorrect;
      } else if (index == correctIndex) {
        stoneColor = AppColors
            .gameCorrect; // Highlight correct answer if incorrect chosen
      }
    }

    Widget stone = Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: () => onOptionSelected(index, correctIndex),
        child: Container(
          key: Key('job_interview_option_$index'),
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: isSelected
                ? stoneColor
                : (isDark ? AppColors.deepDark : Colors.white),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : (isAnswered && index == correctIndex)
                  ? AppColors.gameCorrect
                  : color.withValues(alpha: 0.35),
              width: (isSelected || (isAnswered && index == correctIndex))
                  ? 2.5
                  : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? stoneColor : color).withValues(
                  alpha: isSelected ? 0.35 : 0.06,
                ),
                blurRadius: isSelected ? 12 : 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? ((isCorrect ?? false)
                            ? Icons.verified_rounded
                            : Icons.cancel_rounded)
                      : Icons.diamond_rounded,
                  key: Key('job_interview_option_icon_$index'),
                  color: isSelected ? Colors.white : color,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  text,
                  key: Key('job_interview_option_text_$index'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isAnswered && index == correctIndex)
                        ? (isDark ? AppColors.gameCorrect : Colors.green)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return stone;

    return stone
        .animate(target: isSelected ? 1.0 : 0.0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 150.ms,
        );
  }
}
