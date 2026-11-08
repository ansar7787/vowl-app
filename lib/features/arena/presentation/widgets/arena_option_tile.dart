import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// 1. ArenaGridOptionTile — Compact option tile for 2x2 grid layout (Word Clash)
class ArenaGridOptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isAnswered;
  final int? selectedOption;
  final int correctIndex;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final VoidCallback onTap;

  const ArenaGridOptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.isAnswered,
    required this.selectedOption,
    required this.correctIndex,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color btnBg = isDark ? AppColors.slate900 : Colors.white;
    Color btnBorder = borderColor;
    Color txtColor = textPrimary;

    if (isAnswered) {
      if (index == correctIndex) {
        btnBg = AppColors.emerald500.withValues(alpha: 0.2);
        btnBorder = AppColors.emerald500;
        txtColor = isDark ? Colors.white : AppColors.emerald950;
      } else if (selectedOption == index) {
        btnBg = AppColors.rose500.withValues(alpha: 0.2);
        btnBorder = AppColors.rose500;
        txtColor = isDark ? Colors.white : AppColors.rose500;
      }
    }

    return ScaleButton(
      onTap: isAnswered ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: btnBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  String.fromCharCode(65 + index),
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  softWrap: true,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: txtColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. ArenaListOptionTile — Full-width option tile for vertical list layout (other disciplines)
class ArenaListOptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isAnswered;
  final int? selectedOption;
  final int correctIndex;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final VoidCallback onTap;

  const ArenaListOptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.isAnswered,
    required this.selectedOption,
    required this.correctIndex,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color btnBg = isDark ? AppColors.slate900 : Colors.white;
    Color btnBorder = borderColor;
    Color txtColor = textPrimary;

    if (isAnswered) {
      if (index == correctIndex) {
        btnBg = AppColors.emerald500.withValues(alpha: 0.2);
        btnBorder = AppColors.emerald500;
        txtColor = isDark ? Colors.white : AppColors.emerald950;
      } else if (selectedOption == index) {
        btnBg = AppColors.rose500.withValues(alpha: 0.2);
        btnBorder = AppColors.rose500;
        txtColor = isDark ? Colors.white : AppColors.rose500;
      }
    }

    return ScaleButton(
      onTap: isAnswered ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: btnBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  String.fromCharCode(65 + index),
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  softWrap: true,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: txtColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
