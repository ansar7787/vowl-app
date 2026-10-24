import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Rotary dial and vertical fader console for selecting semantic interpretations of modulated pitch.
class PitchModulationDialControl extends StatelessWidget {
  /// Semantic meaning options.
  final List<String> options;

  /// Index of the correct interpretation.
  final int correctIndex;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Whether the rotary dial is actively being dragged.
  final bool isDragging;

  /// Current rotational angle of the dial in radians.
  final double dialRotation;

  /// Selected option index, or `null`.
  final int? selectedIndex;

  /// Callback executed when the rotary dial rotates.
  final Function(DragUpdateDetails, int) onDialRotate;

  /// Callback executed when dragging the dial completes.
  final VoidCallback onDialRelease;

  /// Callback executed when an option choice is confirmed.
  final Function(int, int) onSubmitChoice;

  /// Creates a [PitchModulationDialControl] widget.
  const PitchModulationDialControl({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isDragging,
    required this.dialRotation,
    required this.selectedIndex,
    required this.onDialRotate,
    required this.onDialRelease,
    required this.onSubmitChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: _buildVerticalFader(correctIndex, color, isDark),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildOptionCard(options[1], 1, correctIndex, color, isDark),
              SizedBox(height: 24.h),
              _buildOptionCard(options[0], 0, correctIndex, color, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalFader(int correct, Color color, bool isDark) {
    return Semantics(
      slider: true,
      label: "Pitch modulation dial",
      value: dialRotation > 0.5
          ? "Top selected"
          : (dialRotation < -0.5 ? "Bottom selected" : "Neutral"),
      increasedValue: "Top selected",
      decreasedValue: "Bottom selected",
      onIncrease: () => onSubmitChoice(1, correct),
      onDecrease: () => onSubmitChoice(0, correct),
      child: GestureDetector(
        key: const ValueKey('pitch_modulation_fader'),
        onPanUpdate: (details) => onDialRotate(details, correct),
        onPanEnd: (_) => onDialRelease(),
        child: Container(
          height: 180.h,
          width: 58.w,
          decoration: BoxDecoration(
            color: isDark ? Colors.black45 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: color.withValues(alpha: isDragging ? 0.6 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Direction hint: Top
              Positioned(
                top: 8.h,
                child: Icon(
                  Icons.arrow_drop_up_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 22.r,
                ),
              ),

              // Center track line
              Container(
                width: 4.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Direction hint: Bottom
              Positioned(
                bottom: 8.h,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 22.r,
                ),
              ),

              // Fader thumb
              TweenAnimationBuilder<double>(
                duration: isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: -dialRotation, end: -dialRotation),
                builder: (context, rotation, child) {
                  return Align(
                    alignment: Alignment(0, rotation),
                    child: Container(
                      width: 46.r,
                      height: 46.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.4 : 0.15,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: color.withValues(
                            alpha: isDragging ? 0.8 : 0.4,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: color,
                          size: 22.r,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;

    Color cardBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white;
    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    if (isAnswered && isSelected) {
      cardBg = correct
          ? AppColors.gameCorrect.withValues(alpha: 0.12)
          : AppColors.gameIncorrect.withValues(alpha: 0.12);
      borderColor = correct ? AppColors.gameCorrect : AppColors.gameIncorrect;
      textColor = correct ? AppColors.gameCorrect : AppColors.gameIncorrect;
    } else if (isSelected) {
      cardBg = color.withValues(alpha: isDark ? 0.18 : 0.1);
      borderColor = color;
      textColor = isDark ? Colors.white : color;
    }

    String mainText = text;
    String subText = "";
    if (text.contains(" (") && text.endsWith(")")) {
      final parts = text.split(" (");
      mainText = parts[0];
      subText = parts[1].substring(0, parts[1].length - 1);
    }

    return Semantics(
      button: true,
      label: "$mainText${subText.isNotEmpty ? ', Meaning: $subText' : ''}",
      child: ScaleButton(
        key: ValueKey('pitch_modulation_option_$index'),
        onTap: () => onSubmitChoice(index, correctIndex),
        child:
            AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? borderColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.04,
                              ),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mainText,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.5.sp,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.2,
                                height: 1.25,
                              ),
                            ),
                            if (subText.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                subText,
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        isSelected
                            ? (isAnswered
                                ? (correct
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded)
                                : Icons.check_circle_rounded)
                            : (index == 1
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded),
                        color: isSelected
                            ? textColor
                            : (isDark ? Colors.white30 : Colors.black26),
                        size: 20.r,
                      ),
                    ],
                  ),
                )
                .animate(target: isSelected ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: 150.ms,
                ),
      ),
    );
  }
}
