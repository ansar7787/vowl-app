import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Bottom action controls for the flashcard game presenting flip prompts and mastery evaluation buttons.
class FlashcardActionButtons extends StatelessWidget {
  /// Whether the card is currently showing its back (definition) face.
  final bool isFlipped;

  /// Whether an answer submission transition is actively animating.
  final bool isTransitioning;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Callback executed when the user taps "Again" (missed).
  final VoidCallback onAgain;

  /// Callback executed when the user taps "Got It" (mastered).
  final VoidCallback onGotIt;

  /// Optional multiple-choice options for objective testing (Mastery phase).
  final List<String>? options;

  /// The correct answer string when options are provided.
  final String? correctAnswer;

  /// Callback when a specific option is chosen.
  final ValueChanged<bool>? onOptionSelected;

  /// Creates a [FlashcardActionButtons] widget.
  const FlashcardActionButtons({
    super.key,
    required this.isFlipped,
    required this.isTransitioning,
    required this.isDark,
    required this.onAgain,
    required this.onGotIt,
    this.options,
    this.correctAnswer,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    if (!isFlipped) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reduceMotion
                ? Icon(
                    Icons.touch_app_rounded,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    size: 24.r,
                  )
                : Icon(
                        Icons.touch_app_rounded,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                        size: 24.r,
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .moveY(
                        begin: 2,
                        end: -2,
                        duration: 1.seconds,
                        curve: Curves.easeInOut,
                      ),
            SizedBox(height: 6.h),
            Text(
              context.tr(
                'instructions.flashcards.tap_to_reveal',
                fallback: 'Tap card to flip',
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? AppColors.slate300 : AppColors.slate600,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (options != null && options!.isNotEmpty) {
      final optionsCol = Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                context.tr(
                  'instructions.flashcards.select_meaning',
                  fallback: 'SELECT THE CORRECT MEANING',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? AppColors.slate300 : AppColors.slate700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            for (int i = 0; i < options!.length; i++) ...[
              if (i > 0) SizedBox(height: 6.h),
              _OptionCard(
                text: options![i],
                isCorrect: options![i].trim().toLowerCase() ==
                    (correctAnswer ?? '').trim().toLowerCase(),
                isDark: isDark,
                disabled: isTransitioning,
                onSelected: (correct) {
                  if (onOptionSelected != null) {
                    onOptionSelected!(correct);
                  } else if (correct) {
                    onGotIt();
                  } else {
                    onAgain();
                  }
                },
              ),
            ],
          ],
        ),
      );

      if (reduceMotion) return optionsCol;
      return optionsCol.animate().fadeIn(duration: 350.ms).slideY(begin: 0.15);
    }

    final buttonsRow = Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _ActionBtn(
              label: context.tr('actions.again', fallback: 'Again'),
              icon: Icons.keyboard_double_arrow_left_rounded,
              color: AppColors.red500,
              isDark: isDark,
              onTap: isTransitioning ? null : onAgain,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: _ActionBtn(
              label: context.tr('actions.got_it', fallback: 'Got It'),
              icon: Icons.keyboard_double_arrow_right_rounded,
              color: AppColors.emerald500,
              isDark: isDark,
              onTap: isTransitioning ? null : onGotIt,
              isRight: true,
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return buttonsRow;
    return buttonsRow.animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }
}

class _OptionCard extends StatefulWidget {
  final String text;
  final bool isCorrect;
  final bool isDark;
  final bool disabled;
  final ValueChanged<bool> onSelected;

  const _OptionCard({
    required this.text,
    required this.isCorrect,
    required this.isDark,
    required this.disabled,
    required this.onSelected,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool? _wasTappedCorrect;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (_wasTappedCorrect != null) {
      if (_wasTappedCorrect!) {
        bgColor = AppColors.emerald500.withValues(alpha: 0.2);
        borderColor = AppColors.emerald500;
        textColor = widget.isDark ? AppColors.emerald400 : AppColors.emerald600;
      } else {
        bgColor = AppColors.red500.withValues(alpha: 0.2);
        borderColor = AppColors.red500;
        textColor = widget.isDark ? AppColors.rose500 : AppColors.rose700;
      }
    } else {
      bgColor = widget.isDark ? AppColors.midnightSurface : Colors.white;
      borderColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.slate200;
      textColor = widget.isDark ? Colors.white : AppColors.slate800;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: widget.disabled
            ? null
            : () {
                setState(() {
                  _wasTappedCorrect = widget.isCorrect;
                });
                widget.onSelected(widget.isCorrect);
              },
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
              if (_wasTappedCorrect != null)
                Icon(
                  _wasTappedCorrect!
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: borderColor,
                  size: 18.r,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isRight;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRight) ...[
                Icon(icon, color: color, size: 18.r),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isRight) ...[
                SizedBox(width: 6.w),
                Icon(icon, color: color, size: 18.r),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
