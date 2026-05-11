import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class WLOptionsList extends StatelessWidget {
  final AccentQuest quest;
  final bool isDark;
  final bool isMidnight;
  final ThemeResult theme;
  final List<int> shuffledIndices;
  final List<int> eliminatedIndices;
  final bool hasSubmitted;
  final int? selectedOptionIndex;
  final Function(int index) onOptionSelected;

  const WLOptionsList({
    super.key,
    required this.quest,
    required this.isDark,
    required this.theme,
    required this.shuffledIndices,
    required this.eliminatedIndices,
    required this.hasSubmitted,
    this.selectedOptionIndex,
    required this.onOptionSelected,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = quest.options ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shuffledIndices.length,
      itemBuilder: (context, index) {
        final originalIndex = shuffledIndices[index];
        final option = options[originalIndex];
        final isSelected = selectedOptionIndex == index;

        bool isCorrect = false;
        if (hasSubmitted) {
          if (quest.correctAnswerIndex != null) {
            isCorrect = originalIndex == quest.correctAnswerIndex;
          } else if (quest.correctAnswer != null) {
            isCorrect = options[originalIndex] == quest.correctAnswer;
          }
        }
        final isEliminated = eliminatedIndices.contains(originalIndex);

        Color cardColor = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white;
        if (isEliminated) {
          cardColor = isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02);
        } else if (hasSubmitted) {
          if (isCorrect) {
            cardColor = Colors.greenAccent.withValues(alpha: 0.15);
          } else if (isSelected) {
            cardColor = Colors.redAccent.withValues(alpha: 0.15);
          }
        } else if (isSelected) {
          cardColor = theme.primaryColor.withValues(alpha: 0.08);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ScaleButton(
            onTap: isEliminated || hasSubmitted
                ? null
                : () => onOptionSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isEliminated
                      ? Colors.transparent
                      : isSelected || (isCorrect && hasSubmitted)
                      ? (isCorrect && hasSubmitted
                            ? Colors.greenAccent
                            : (isSelected && hasSubmitted
                                  ? Colors.redAccent
                                  : theme.primaryColor))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
                  width: isSelected || (isCorrect && hasSubmitted) ? 2 : 1.5,
                ),
                boxShadow: isSelected || (isCorrect && hasSubmitted)
                    ? [
                        BoxShadow(
                          color:
                              (isCorrect && hasSubmitted
                                      ? Colors.greenAccent
                                      : theme.primaryColor)
                                  .withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: _buildOptionContent(
                  option,
                  isSelected: isSelected,
                  isCorrect: isCorrect,
                  isEliminated: isEliminated,
                  isDark: isDark,
                  theme: theme,
                  hasSubmitted: hasSubmitted,
                ),
              ),
            ),
          ),
        ).animate(delay: (200 + index * 100).ms).fadeIn().slideX(begin: 0.1);
      },
    );
  }

  Widget _buildOptionContent(
    String option, {
    required bool isSelected,
    required bool isCorrect,
    required bool isEliminated,
    required bool isDark,
    required ThemeResult theme,
    required bool hasSubmitted,
  }) {
    final parts = option
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    Color getTextColor() {
      if (isEliminated) return isDark ? Colors.white24 : Colors.black26;
      if (isSelected || (isCorrect && hasSubmitted)) {
        if (isCorrect && hasSubmitted) {
          return isDark ? Colors.greenAccent : Colors.green.shade800;
        }
        if (isSelected && hasSubmitted) {
          return isDark ? Colors.redAccent : Colors.red.shade800;
        }
        return theme.primaryColor;
      }
      return isDark ? Colors.white70 : Colors.black87;
    }

    if (parts.length <= 1) {
      return Text(
        option,
        style: GoogleFonts.outfit(
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: getTextColor(),
          letterSpacing: 2,
        ),
      );
    }

    // Visually separate split sounds as chips
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: parts.map((part) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: getTextColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: getTextColor().withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            part,
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: getTextColor(),
              letterSpacing: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
