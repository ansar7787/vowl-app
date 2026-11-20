import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// 2026 Interactive Collocation Snap Challenge Card for Guided Practice.
class FlashcardCollocationSnapCard extends StatelessWidget {
  final String? collocationPrompt;
  final List<String> collocationOptions;
  final int? selectedCollocationIndex;
  final int correctCollocationIndex;
  final bool hasCheckedCollocation;
  final bool isDark;
  final void Function(int optionIndex) onSelectCollocation;

  const FlashcardCollocationSnapCard({
    super.key,
    this.collocationPrompt,
    required this.collocationOptions,
    this.selectedCollocationIndex,
    required this.correctCollocationIndex,
    required this.hasCheckedCollocation,
    required this.isDark,
    required this.onSelectCollocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.amber.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_rounded,
                  size: 16.r,
                  color: isDark ? Colors.amberAccent : Colors.amber.shade800,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  collocationPrompt ?? 'SELECT THE NATURAL WORD PARTNER',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...List.generate(collocationOptions.length, (idx) {
            final option = collocationOptions[idx];
            final isSelected = selectedCollocationIndex == idx;
            final isCorrect = idx == correctCollocationIndex;

            Color borderCol = isDark ? AppColors.slate700 : AppColors.slate300;
            Color bgCol = isDark ? AppColors.slate800 : AppColors.slate50;

            if (hasCheckedCollocation && isSelected) {
              if (isCorrect) {
                borderCol = Colors.green;
                bgCol = Colors.green.withValues(alpha: 0.15);
              } else {
                borderCol = Colors.red;
                bgCol = Colors.red.withValues(alpha: 0.15);
              }
            } else if (isSelected) {
              borderCol = AppColors.indigo500;
              bgCol = AppColors.indigo500.withValues(alpha: 0.1);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: ScaleButton(
                key: ValueKey('collocation_$idx'),
                onTap: () => onSelectCollocation(idx),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: bgCol,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: borderCol,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate700
                              : AppColors.slate200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                      if (hasCheckedCollocation && isSelected) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 20.r,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
