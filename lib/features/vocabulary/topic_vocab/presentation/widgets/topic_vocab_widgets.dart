import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class TopicVocabQuestion extends StatelessWidget {
  final dynamic quest;
  final ThemeResult theme;
  final bool isDark;
  final Function(String) onSpeak;

  const TopicVocabQuestion({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(16.r),
      borderRadius: BorderRadius.circular(24.r),
      borderColor: theme.primaryColor.withValues(alpha: 0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            quest.instruction.toUpperCase(),
            style: GoogleFonts.shareTechMono(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5),
          ),
          SizedBox(height: 12.h),
          Text(
            quest.sentence ?? quest.definition ?? "---",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
          ),
          SizedBox(height: 12.h),
          ScaleButton(
            onTap: () => onSpeak(quest.sentence ?? quest.definition ?? ""),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.volume_up_rounded, color: theme.primaryColor, size: 16.r),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class TopicVocabOptions extends StatelessWidget {
  final dynamic quest;
  final ThemeResult theme;
  final bool isDark;
  final int? selectedOptionIndex;
  final Set<int> wrongIndices;
  final Function(int, bool) onOptionSelected;
  final Function(String) onSpeak;

  const TopicVocabOptions({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    required this.selectedOptionIndex,
    required this.wrongIndices,
    required this.onOptionSelected,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              borderColor: isSelected ? Colors.green : (isAlreadyWrong ? Colors.red : theme.primaryColor.withValues(alpha: 0.1)),
              color: isSelected ? Colors.green.withValues(alpha: 0.1) : (isAlreadyWrong ? Colors.red.withValues(alpha: 0.1) : Colors.transparent),
              child: Row(
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(color: isSelected ? Colors.green : (isAlreadyWrong ? Colors.red : theme.primaryColor.withValues(alpha: 0.3)))
                    ),
                    child: Center(
                      child: Text(
                        isAlreadyWrong ? "!!" : String.fromCharCode(65 + index),
                        style: GoogleFonts.shareTechMono(fontSize: 10.sp, fontWeight: FontWeight.bold, color: isSelected ? Colors.green : (isAlreadyWrong ? Colors.red : theme.primaryColor)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isAlreadyWrong ? Colors.white38 : Colors.white),
                    ),
                  ),
                  ScaleButton(onTap: () => onSpeak(option), child: Icon(Icons.volume_up_rounded, size: 16.r, color: Colors.white38)),
                ],
              ),
            ),
          ),
        );
      }),
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}
