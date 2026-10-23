import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Options list panel rendering idiom interpretation choices.
class IdiomMatchOptionsPanel extends StatelessWidget {
  /// Shuffled list of potential idiom definitions.
  final List<String> shuffledOptions;

  /// Original indexing mapping permuted choices back to canonical indices.
  final List<int> originalIndices;

  /// Currently selected option index in shuffled coordinates, if any.
  final int? selectedIndex;

  /// Indices of candidate options evaluated as incorrect.
  final List<int> wrongIndices;

  /// Whether an answer has been locked in and evaluated.
  final bool isAnswered;

  /// Whether the solution should be illuminated.
  final bool showCorrectAnswer;

  /// Canonical index of the correct answer.
  final int correctAnswerIndex;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Primary accent color.
  final Color primaryColor;

  /// Callback triggered when an option tile is tapped.
  final ValueChanged<int> onOptionSelected;

  /// Creates an [IdiomMatchOptionsPanel].
  const IdiomMatchOptionsPanel({
    super.key,
    required this.shuffledOptions,
    required this.originalIndices,
    this.selectedIndex,
    required this.wrongIndices,
    required this.isAnswered,
    required this.showCorrectAnswer,
    required this.correctAnswerIndex,
    required this.isDark,
    required this.primaryColor,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    return Column(
      children: List.generate(shuffledOptions.length, (index) {
        final option = shuffledOptions[index];
        final isSelected = selectedIndex == index;
        final isWrong = wrongIndices.contains(index);
        final isCorrect =
            showCorrectAnswer && originalIndices[index] == correctAnswerIndex;
        Color textColor = Theme.of(context).colorScheme.onSurface;

        // FIX: this option previously had zero Semantics. A sighted player
        // gets the outcome from border color (green/red) plus the cancel
        // icon on wrong answers; a screen-reader user got none of that —
        // just the bare option text repeated identically regardless of
        // state. Build one combined label per option instead.
        final semanticLabel = _buildOptionLabel(
          context,
          option,
          isCorrect,
          isWrong,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Semantics(
            button: true,
            enabled: !isAnswered,
            selected: isSelected,
            label: semanticLabel,
            excludeSemantics: true,
            child: ScaleButton(
              key: Key('idiom_match_option_$index'),
              onTap: isAnswered ? null : () => onOptionSelected(index),
              child: GlassTile(
                borderRadius: BorderRadius.circular(20.r),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
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
                                        : Colors.black.withValues(
                                            alpha: 0.08,
                                          )))),
                  width: 1.5,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: (isCorrect || isSelected)
                            ? Colors.green.withValues(alpha: 0.15)
                            : (isWrong
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : primaryColor.withValues(alpha: 0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect
                            ? Icons.check_rounded
                            : (isWrong
                                  ? Icons.close_rounded
                                  : Icons.psychology_alt_rounded),
                        color: (isCorrect || isSelected)
                            ? Colors.green
                            : (isWrong
                                ? (tokens?.gameIncorrect ?? AppColors.red500)
                                : primaryColor),
                        size: 18.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        option,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.35,
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
      return '$option. ${context.tr('games.semantic_correct_suffix', fallback: 'Correct answer')}';
    }
    if (isWrong) {
      return '$option. ${context.tr('games.semantic_incorrect_suffix', fallback: 'Incorrect')}';
    }
    return option;
  }
}
