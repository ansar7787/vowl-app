import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Selection panel providing candidate corrections for a diagnosed sentence error.
class SentenceCorrectionOptionsPanel extends StatelessWidget {
  /// The list of candidate correction options.
  final List<String> options;

  /// The currently selected correction option.
  final String? selectedOption;

  /// Whether the question has already been answered.
  final bool isAnswered;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// The primary accent color for buttons and borders.
  final Color primaryColor;

  /// Callback invoked when a correction option is selected.
  final ValueChanged<String> onOptionSelect;

  /// Callback invoked to confirm and submit the selection.
  final VoidCallback onConfirm;

  /// Creates a [SentenceCorrectionOptionsPanel] widget.
  const SentenceCorrectionOptionsPanel({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.isAnswered,
    required this.isDark,
    required this.primaryColor,
    required this.onOptionSelect,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isOptionSelected = selectedOption != null;

    final panel = Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              "Choose the correction",
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: options.map((option) {
                final isThisSelected = selectedOption == option;
                return ScaleButton(
                  onTap: isAnswered ? null : () => onOptionSelect(option),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isThisSelected
                          ? primaryColor.withValues(alpha: 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isThisSelected
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.1),
                        width: isThisSelected ? 1.5 : 1,
                      ),
                      boxShadow: isThisSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isThisSelected
                            ? primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
            if (!isAnswered)
              ScaleButton(
                onTap: isOptionSelected ? onConfirm : null,
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      colors: !isOptionSelected
                          ? [
                              Colors.grey.withValues(alpha: 0.3),
                              Colors.grey.withValues(alpha: 0.4),
                            ]
                          : [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.85),
                            ],
                    ),
                    boxShadow: !isOptionSelected
                        ? []
                        : [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      "Confirm Correction",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w700,
                        color: !isOptionSelected
                            ? (isDark ? Colors.white30 : Colors.black26)
                            : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return panel;
    }

    return panel.animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
