import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SpeedSpellingInputField extends StatelessWidget {
  final String currentInput;
  final bool isAnswered;
  final bool? isCorrect;
  final int attempts;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const SpeedSpellingInputField({
    super.key,
    required this.currentInput,
    required this.isAnswered,
    this.isCorrect,
    required this.attempts,
    required this.isDark,
    required this.primaryColor,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final correctColor = tokens?.gameCorrect ?? AppColors.gameCorrect;
    final incorrectColor = tokens?.gameIncorrect ?? AppColors.gameIncorrect;
    final showCorrectGlow = isCorrect == true;
    final isCompact = MediaQuery.sizeOf(context).height < 650;

    return Container(
      key: const Key('speed_spelling_input_field'),
      height: isCompact ? 76.h : 84.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: showCorrectGlow
            ? LinearGradient(
                colors: [
                  correctColor.withValues(alpha: 0.2),
                  correctColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.015),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (isAnswered || (isCorrect == false && attempts > 0))
              ? (isCorrect == true
                    ? correctColor.withValues(alpha: 0.6)
                    : incorrectColor.withValues(alpha: 0.6))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08)),
          width: 1.5,
        ),
        boxShadow: showCorrectGlow
            ? [
                BoxShadow(
                  color: correctColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: 16.w,
                end: math.max(90.w, 116.0),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Semantics(
                  liveRegion: true,
                  label: currentInput.isEmpty
                      ? context.tr(
                          'games.semantic_spelling_empty',
                          fallback: 'No letters entered yet',
                        )
                      : context.tr(
                          'games.semantic_current_spelling',
                          fallback: 'Current Spelling',
                          args: [currentInput],
                        ),
                  excludeSemantics: true,
                  child: Text(
                    currentInput,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: showCorrectGlow
                          ? correctColor
                          : (isDark ? primaryColor : AppColors.slate900),
                      letterSpacing: 4,
                      shadows: showCorrectGlow
                          ? [
                              Shadow(
                                color: correctColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (currentInput.isNotEmpty && !isAnswered)
            PositionedDirectional(
              end: 12.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: context.tr(
                        'games.semantic_backspace',
                        fallback: 'Delete last letter',
                      ),
                      excludeSemantics: true,
                      child: ScaleButton(
                        key: const Key('speed_spelling_backspace_button'),
                        onTap: onBackspace,
                        debounceDuration: Duration.zero,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.slate100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.backspace_rounded,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate800,
                                size: 18.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Semantics(
                      button: true,
                      label: context.tr(
                        'games.semantic_clear_input',
                        fallback: 'Clear all letters',
                      ),
                      excludeSemantics: true,
                      child: ScaleButton(
                        key: const Key('speed_spelling_clear_button'),
                        onTap: onClear,
                        debounceDuration: Duration.zero,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.slate100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.refresh_rounded,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate800,
                                size: 18.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
