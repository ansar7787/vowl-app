import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SituationalResponseOptionsPanel extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final int? selectedIndex;
  final Function(int, int) onOptionTap;

  const SituationalResponseOptionsPanel({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    this.isCorrect,
    this.selectedIndex,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = selectedIndex == index;

        // Determine state colors
        Color borderColor = isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08);
        Color iconColor = color;
        Color iconBgColor = color.withValues(alpha: 0.15);
        IconData iconData = Icons.chat_bubble_outline_rounded;

        if (isAnswered && isSelected) {
          if (index == correctIndex) {
            borderColor = AppColors.gameCorrect;
            iconColor = AppColors.gameCorrect;
            iconBgColor = AppColors.gameCorrect.withValues(alpha: 0.15);
            iconData = Icons.check_rounded;
          } else {
            borderColor = AppColors.gameIncorrect;
            iconColor = AppColors.gameIncorrect;
            iconBgColor = AppColors.gameIncorrect.withValues(alpha: 0.15);
            iconData = Icons.close_rounded;
          }
        } else if (isAnswered && index == correctIndex) {
          // Show correct answer if they got it wrong
          borderColor = AppColors.gameCorrect;
          iconColor = AppColors.gameCorrect;
          iconBgColor = AppColors.gameCorrect.withValues(alpha: 0.15);
          iconData = Icons.check_rounded;
        } else if (isSelected) {
          borderColor = color;
        }

        final isActualCorrect = isAnswered && index == correctIndex;
        final isActualWrong = isAnswered && isSelected && index != correctIndex;
        final semanticLabel = _buildOptionLabel(
          context,
          option,
          isActualCorrect,
          isActualWrong,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Semantics(
            button: true,
            enabled: !isAnswered,
            selected: isSelected,
            label: semanticLabel,
            excludeSemantics: true,
            child: ScaleButton(
              onTap: isAnswered ? null : () => onOptionTap(index, correctIndex),
              child: GlassTile(
                borderRadius: BorderRadius.circular(20.r),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                usePremiumStyle: true,
                showShadow: true,
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white,
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || (isAnswered && index == correctIndex))
                      ? 2.0
                      : 1.5,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 18.r),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
      }),
    );
  }

  String _buildOptionLabel(
    BuildContext context,
    String option,
    bool isCorrect,
    bool isWrong,
  ) {
    if (isCorrect) {
      return '$option. ${context.tr('games.semantic_correct_suffix', fallback: 'Correct')}';
    }
    if (isWrong) {
      return '$option. ${context.tr('games.semantic_incorrect_suffix', fallback: 'Incorrect')}';
    }
    return option;
  }
}
