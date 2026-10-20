import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceOrderReadingInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const SentenceOrderReadingInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final text = (instruction != null && instruction!.trim().isNotEmpty)
        ? instruction!.trim()
        : 'Put the sentences in the correct order.';

    return Semantics(
      header: true,
      label: text,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 340.w),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: 0.1,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
