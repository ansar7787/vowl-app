import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordLabOptions extends StatelessWidget {
  final dynamic quest;
  final ThemeResult theme;
  final bool isDark;
  final int? selectedOptionIndex;
  final Set<int> wrongIndices;
  final Function(int, bool) onOptionSelected;

  const WordLabOptions({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    this.selectedOptionIndex,
    required this.wrongIndices,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(quest.options?.length ?? 0, (index) {
        final option = quest.options![index];
        final isCorrect = index == quest.correctAnswerIndex;
        final isSelected = selectedOptionIndex == index;
        final isAlreadyWrong = wrongIndices.contains(index);

        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: ScaleButton(
            onTap: () => onOptionSelected(index, isCorrect),
            child: GlassTile(
              borderRadius: BorderRadius.circular(16.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              borderColor: isSelected ? Colors.green : (isAlreadyWrong ? Colors.red : theme.primaryColor.withValues(alpha: 0.1)),
              color: isSelected ? Colors.green.withValues(alpha: 0.1) : (isAlreadyWrong ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02)),
              child: Row(
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.green : (isAlreadyWrong ? Colors.red : theme.primaryColor.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isAlreadyWrong ? "!!" : "0${index + 1}",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green : (isAlreadyWrong ? Colors.red : theme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isAlreadyWrong ? Colors.white54 : Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected || isAlreadyWrong)
                    Icon(
                      isCorrect ? Icons.auto_awesome : Icons.bolt,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 18.r,
                    ).animate().scale().shake(),
                ],
              ),
            ),
          ),
        );
      }).animate(interval: 50.ms).fadeIn(duration: 400.ms).slideX(begin: 0.05),
    );
  }
}
