import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class IdiomMatchOptionsPanel extends StatelessWidget {
  final List<String> shuffledOptions;
  final List<int> originalIndices;
  final int? selectedIndex;
  final List<int> wrongIndices;
  final bool isAnswered;
  final int correctAnswerIndex;
  final bool isDark;
  final Color primaryColor;
  final Function(int shuffledIndex) onOptionSelected;

  const IdiomMatchOptionsPanel({
    super.key,
    required this.shuffledOptions,
    required this.originalIndices,
    this.selectedIndex,
    required this.wrongIndices,
    required this.isAnswered,
    required this.correctAnswerIndex,
    required this.isDark,
    required this.primaryColor,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(shuffledOptions.length, (index) {
        final option = shuffledOptions[index];
        final isSelected = selectedIndex == index;
        final isWrong = wrongIndices.contains(index);
        final isCorrect =
            isAnswered && originalIndices[index] == correctAnswerIndex;
        Color textColor = isDark ? Colors.white : Colors.black87;

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ScaleButton(
            onTap: isAnswered ? null : () => onOptionSelected(index),
            child: GlassTile(
              borderRadius: BorderRadius.circular(24.r),
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 22.h,
              ),
              usePremiumStyle: true,
              showShadow: true,
              color: isDark ? Colors.black.withValues(alpha: 0.3) : null,
              border: Border.all(
                color: isCorrect
                    ? Colors.green
                    : (isWrong
                        ? Colors.red
                        : (isSelected
                            ? Colors.green
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.08)))),
                width: 1.5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isWrong)
                    Icon(
                      Icons.cancel_rounded,
                      color: Colors.redAccent,
                      size: 24.r,
                    ).animate().shake(duration: 400.ms),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
      }),
    );
  }
}
