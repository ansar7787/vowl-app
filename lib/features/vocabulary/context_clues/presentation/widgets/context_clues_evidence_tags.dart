import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ContextCluesEvidenceTags extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color color;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;
  final bool isFinalFailure;
  final Function(String) onOptionSelected;

  const ContextCluesEvidenceTags({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
    required this.isFinalFailure,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            children: [
              Icon(Icons.label_important_rounded, size: 14.r, color: color),
              SizedBox(width: 8.w),
              Text(
                "IDENTIFY REDACTED COMPONENT",
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: options.map((o) {
              final isSelected = selectedOption == o;
              final showCorrect =
                  (isAnswered && isCorrect == true && o == correct) ||
                  (isAnswered && isFinalFailure && o == correct);
              final showWrong =
                  isAnswered && isSelected && isCorrect == false;

              return Padding(
                padding: EdgeInsets.only(right: 15.w),
                child: ScaleButton(
                  onTap: () => onOptionSelected(o),
                  child: Container(
                    padding: EdgeInsets.only(left: 10.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: IntrinsicWidth(
                      child: Row(
                        children: [
                          // Tag String Hole
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 15.h,
                            ),
                            decoration: BoxDecoration(
                              color: showCorrect
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : (showWrong
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : (isSelected
                                              ? color.withValues(alpha: 0.2)
                                              : Colors.white)),
                              border: Border(
                                left: BorderSide(
                                  color: color.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              o.toUpperCase(),
                              style: TextStyle(fontFamily: 'RobotoMono', 
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: showCorrect
                                    ? Colors.green
                                    : (showWrong
                                          ? Colors.red
                                          : (isSelected
                                                ? color
                                                : Colors.black87)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
