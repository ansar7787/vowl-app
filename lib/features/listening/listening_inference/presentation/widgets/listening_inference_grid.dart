import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ListeningInferenceGrid extends StatelessWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final Function(int) onSubmitAnswer;

  const ListeningInferenceGrid({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 16.w,
        runSpacing: 16.h,
        alignment: WrapAlignment.center,
        children: List.generate(options.length, (index) {
          bool isSelected = selectedIndex == index;
          bool isChoiceCorrect = isAnswered && index == correctAnswerIndex && isCorrectState == true;
          bool isChoiceWrong = isAnswered && isSelected && isCorrectState == false;
          
          return ScaleButton(
            onTap: () => onSubmitAnswer(index),
            child: Container(
              width: 135.w,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isChoiceCorrect 
                    ? Colors.greenAccent 
                    : (isChoiceWrong 
                        ? Colors.redAccent 
                        : (isSelected ? color : const Color(0xFF1E1E24))),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isChoiceCorrect || isChoiceWrong || isSelected 
                      ? Colors.white.withValues(alpha: 0.5) 
                      : color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: Offset(0, 4.h),
                    blurRadius: 8,
                  ),
                  if (isSelected || isChoiceCorrect || isChoiceWrong)
                    BoxShadow(
                      color: (isChoiceCorrect ? Colors.greenAccent : (isChoiceWrong ? Colors.redAccent : color)).withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isChoiceCorrect ? Icons.verified_user_rounded : (isChoiceWrong ? Icons.report_problem_rounded : Icons.bubble_chart_rounded),
                    color: Colors.white,
                    size: 18.r
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    options[index].toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
