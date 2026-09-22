import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ReadingSpeedOption extends StatelessWidget {
  final int index;
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final VoidCallback onTap;

  const ReadingSpeedOption({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    bool isSelected = selectedIndex == index;
    bool isCorrect =
        isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    bool isWrong = isAnswered && isSelected && !isCorrect;

    // Clean flat styling logic
    final Color baseColor = isCorrect
        ? tokens.gameCorrect
        : (isWrong ? tokens.gameIncorrect : color);

    final Color bgColor = isCorrect
        ? tokens.gameCorrect.withValues(alpha: 0.15)
        : (isWrong
              ? tokens.gameIncorrect.withValues(alpha: 0.15)
              : (isSelected
                    ? color.withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white)));

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: bgColor,
            border: Border.all(
              color: isSelected || isCorrect || isWrong
                  ? baseColor.withValues(alpha: 0.8)
                  : (isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05)),
              width: isSelected || isCorrect || isWrong ? 2.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: isSelected || isCorrect || isWrong
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
