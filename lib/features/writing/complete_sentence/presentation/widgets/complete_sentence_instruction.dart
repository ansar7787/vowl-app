import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Instruction badge displayed at the top of the Complete Sentence screen.
class CompleteSentenceInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color primaryColor;

  /// Custom instruction text override.
  final String? text;

  /// Optional grammar rule focus label.
  final String? grammarFocus;

  /// Creates a [CompleteSentenceInstruction] badge.
  const CompleteSentenceInstruction({
    super.key,
    required this.primaryColor,
    this.text,
    this.grammarFocus,
  });

  @override
  Widget build(BuildContext context) {
    final baseText =
        (text != null && text!.trim().isNotEmpty)
            ? text!
            : context.tr(
                'games.completeSentence_instruction',
                fallback: 'Select the missing word to complete the sentence',
              );
    final fullText = grammarFocus != null && grammarFocus!.trim().isNotEmpty
        ? '$baseText (${grammarFocus!.toUpperCase()})'
        : baseText;

    return Semantics(
      label: 'Instruction: $fullText',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.edit_note_rounded,
                size: 20.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1).clamp(0.85, 1.25),
                  ),
                ),
                child: Text(
                  fullText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: null,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0.15,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            ExcludeSemantics(
              child: Icon(
                Icons.edit_note_rounded,
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
