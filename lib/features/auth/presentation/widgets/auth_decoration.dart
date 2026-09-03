import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared decoration builder for auth input fields.
InputDecoration buildAuthDecoration({
  required BuildContext context,
  required Color contrastColor,
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: 'Outfit',
      color: contrastColor.withValues(alpha: 0.5),
    ),
    errorStyle: TextStyle(
      fontFamily: 'Outfit',
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 12.sp,
    ),
    prefixIcon: Icon(prefixIcon, color: contrastColor.withValues(alpha: 0.5)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF3F4F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: const BorderSide(color: Colors.red, width: 2.5),
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
  );
}
