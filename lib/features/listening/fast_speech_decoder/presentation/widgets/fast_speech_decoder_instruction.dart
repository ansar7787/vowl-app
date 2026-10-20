import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FastSpeechDecoderInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const FastSpeechDecoderInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: instruction,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 340.w),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Text(
            instruction,
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.35,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
