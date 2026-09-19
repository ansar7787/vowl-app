import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ParagraphSummaryOptionRack extends StatelessWidget {
  final List<String> options;
  final String correctAnswer;
  final Color color;
  final bool isDark;
  final String? selectedOption;
  final bool isAnswered;
  final Function(String) onTapOption;

  const ParagraphSummaryOptionRack({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.color,
    required this.isDark,
    required this.selectedOption,
    required this.isAnswered,
    required this.onTapOption,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Column(
      children: options.map((opt) {
        final bool isSelected = selectedOption == opt;

        Color cardColor = isDark ? Colors.grey.shade900 : Colors.white;
        Color borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

        if (isAnswered) {
          if (opt.trim().toLowerCase() == correctAnswer.trim().toLowerCase()) {
            cardColor = tokens.gameCorrect.withValues(alpha: 0.15);
            borderColor = tokens.gameCorrect;
          } else if (isSelected) {
            cardColor = tokens.gameIncorrect.withValues(alpha: 0.15);
            borderColor = tokens.gameIncorrect;
          }
        } else if (isSelected) {
          borderColor = color;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTap: () => onTapOption(opt),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
