import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceBuilderKeyboardInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final bool isDark;

  const SentenceBuilderKeyboardInput({
    super.key,
    required this.controller,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
          color: isDark ? Colors.white : Colors.black87,
        ),
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Type the complete sentence here...",
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}
