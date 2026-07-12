import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SentenceCorrectionOptionsPanel extends StatelessWidget {
  final List<String> options;
  final String? selectedOption;
  final bool isAnswered;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<String> onOptionSelect;
  final VoidCallback onConfirm;

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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              "GLITCH IDENTIFIED: CHOOSE THE CORRECTION",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              alignment: WrapAlignment.center,
              children: options.map((option) {
                final isThisSelected = selectedOption == option;
                return ScaleButton(
                  onTap: isAnswered ? null : () => onOptionSelect(option),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: isThisSelected
                          ? primaryColor.withValues(alpha: 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isThisSelected
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.1),
                        width: isThisSelected ? 2 : 1,
                      ),
                      boxShadow: isThisSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isThisSelected
                            ? primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 28.h),
            if (!isAnswered)
              ScaleButton(
                onTap: isOptionSelected ? onConfirm : null,
                child: Container(
                  width: double.infinity,
                  height: 58.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: LinearGradient(
                      colors: !isOptionSelected
                          ? [
                              Colors.grey.withValues(alpha: 0.3),
                              Colors.grey.withValues(alpha: 0.4),
                            ]
                          : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    ),
                    boxShadow: !isOptionSelected
                        ? []
                        : [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      "EXECUTE REPAIR",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: !isOptionSelected
                            ? (isDark ? Colors.white30 : Colors.black26)
                            : Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
