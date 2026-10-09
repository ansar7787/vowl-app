import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SentenceBuilderInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final String? sentenceType;

  const SentenceBuilderInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.sentenceType,
  });

  @override
  Widget build(BuildContext context) {
    // Combine instruction and sentenceType into one string if needed,
    // or just show them in one text block.
    final baseText = context.tr(
      'games.sentenceBuilder_instruction',
      fallback: instruction ?? 'Put the words in the right order',
    );
    final fullText = sentenceType != null
        ? '$baseText (${sentenceType!.toUpperCase()})'
        : baseText;

    return Semantics(
      label: 'Instruction: Assemble the jigsaw of logic',
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
                Icons.carpenter_rounded,
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
            // Transparent icon for perfect centering balance
            ExcludeSemantics(
              child: Icon(
                Icons.carpenter_rounded,
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
