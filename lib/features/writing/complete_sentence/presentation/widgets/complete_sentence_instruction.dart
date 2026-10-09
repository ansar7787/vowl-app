import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class CompleteSentenceInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? text;
  final String? grammarFocus;

  const CompleteSentenceInstruction({
    super.key,
    required this.primaryColor,
    this.text,
    this.grammarFocus,
  });

  @override
  Widget build(BuildContext context) {
    final baseText =
        text ??
        context.tr(
          'games.completeSentence_instruction',
          fallback: 'Launch the correct fragment to complete the sentence!',
        );
    final fullText = grammarFocus != null
        ? '$baseText (${grammarFocus!.toUpperCase()})'
        : baseText;

    return Semantics(
      label: 'Instruction: $fullText',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.gps_fixed_rounded,
                size: 20.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
                  ),
                ),
                child: Text(
                  fullText,
                  textAlign: TextAlign.center,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ExcludeSemantics(
              child: Icon(
                Icons.gps_fixed_rounded,
                size: 20.r,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
