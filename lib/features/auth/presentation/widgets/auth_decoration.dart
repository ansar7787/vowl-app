import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Shared decoration builder for auth input fields.
///
/// Implements Instagram/modern mobile input styling: clean high-contrast
/// surface with a crisp 1px neutral border, legible hint text, and an active
/// brand focus outline.
InputDecoration buildAuthDecoration({
  required BuildContext context,
  required Color contrastColor,
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isMidnight =
      isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
  final primaryColor = Theme.of(context).colorScheme.primary;

  final fieldFill = isMidnight
      ? const Color(0xFF070B14)
      : (isDark ? AppColors.slate800 : AppColors.white);

  final fieldBorder = isMidnight
      ? Colors.white.withValues(alpha: 0.14)
      : (isDark ? AppColors.slate700 : AppColors.slate200);

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: 'Outfit',
      color: isDark ? Colors.white38 : AppColors.slate400,
      fontSize: 15.sp,
    ),
    errorStyle: TextStyle(
      fontFamily: 'Outfit',
      color: AppColors.red500,
      fontWeight: FontWeight.w600,
      fontSize: 12.sp,
    ),
    prefixIcon: Icon(
      prefixIcon,
      color: isDark ? Colors.white54 : AppColors.slate400,
      size: 22.r,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: fieldFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide(color: fieldBorder, width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide(color: fieldBorder, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: const BorderSide(color: AppColors.red500, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: const BorderSide(color: AppColors.red500, width: 2.0),
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 18.w),
  );
}
