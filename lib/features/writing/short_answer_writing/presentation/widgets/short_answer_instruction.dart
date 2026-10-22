import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ShortAnswerInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const ShortAnswerInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final String displayInstruction = (instruction != null &&
            instruction!.trim().isNotEmpty)
        ? instruction!
        : context.tr(
            'games.short_answer_writing_instruction',
            fallback: "Write a short, natural answer to the prompt below.",
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Text(
        displayInstruction,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w500,
          color: primaryColor,
          height: 1.45,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
