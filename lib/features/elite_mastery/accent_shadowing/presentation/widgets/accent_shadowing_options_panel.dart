import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AccentShadowingOptionsPanel extends StatelessWidget {
  final List<String> shuffledOptions;
  final List<int> originalIndices;
  final int? selectedIndex;
  final List<int> wrongIndices;
  final bool isAnswered;
  final bool showCorrectAnswer;
  final int correctAnswerIndex;
  final bool isDark;
  final Color primaryColor;
  // FIX: was `final Function(int shuffledIndex) onOptionSelected;` — a bare
  // `Function` type accepts a callback of *any* signature and only fails at
  // runtime if misused. `ValueChanged<int>` (Flutter's own alias for
  // `void Function(int)`) gives the same call-site ergonomics with real
  // compile-time type safety.
  final ValueChanged<int> onOptionSelected;

  const AccentShadowingOptionsPanel({
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
    final reduceMotion = VowlMotion.shouldReduceMotion(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    return Column(
      children: List.generate(shuffledOptions.length, (index) {
        final option = shuffledOptions[index];
        final isSelected = selectedIndex == index;
        final isWrong = wrongIndices.contains(index);
        final isCorrect =
            showCorrectAnswer && originalIndices[index] == correctAnswerIndex;
        Color textColor = Theme.of(context).colorScheme.onSurface;

        final semanticLabel = _buildOptionLabel(
          context,
          option,
          isCorrect,
          isWrong,
        );

        final optionWidget = Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Semantics(
            button: true,
            enabled: !isAnswered,
            selected: isSelected,
            label: semanticLabel,
            excludeSemantics: true,
            child: ScaleButton(
              key: Key('accent_shadowing_option_$index'),
              onTap: isAnswered ? null : () => onOptionSelected(index),
              child: GlassTile(
                borderRadius: BorderRadius.circular(20.r),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (reduceMotion) {
          return optionWidget;
        }

        return optionWidget
            .animate()
            .fadeIn(delay: (index * 100).ms)
            .slideX(begin: 0.1);
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
