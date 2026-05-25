import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FastSpeechDecoderSteamVents extends StatelessWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final Function(int) onSubmitAnswer;

  const FastSpeechDecoderSteamVents({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;
        final isChoiceCorrect =
            isAnswered && index == correctAnswerIndex && isCorrectState == true;
        final isChoiceWrong = isAnswered && isSelected && isCorrectState == false;

        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: ScaleButton(
            onTap: () => onSubmitAnswer(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isChoiceCorrect
                    ? Colors.greenAccent.withValues(alpha: 0.8)
                    : (isChoiceWrong
                        ? Colors.redAccent.withValues(alpha: 0.8)
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
                      color: (isChoiceCorrect
                              ? Colors.greenAccent
                              : (isChoiceWrong ? Colors.redAccent : color))
                          .withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isChoiceCorrect
                        ? Icons.verified_rounded
                        : (isChoiceWrong
                            ? Icons.error_outline_rounded
                            : Icons.air_rounded),
                    color: Colors.white,
                    size: 18.r,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      options[index],
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected && !isAnswered)
                    Icon(
                      Icons.radio_button_checked,
                      color: Colors.white,
                      size: 14.r,
                    ),
                ],
              ),
            ),
          ),
        ).animate(target: isChoiceWrong ? 1 : 0).shake(duration: 400.ms);
      }),
    );
  }
}
