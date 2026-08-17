import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ScanResultBlock extends StatelessWidget {
  final TextBlock block;
  final int index;
  final String? translatedText;
  final bool isTranslating;
  final void Function(int, String) onTranslate;

  const ScanResultBlock({
    super.key,
    required this.block,
    required this.index,
    required this.translatedText,
    required this.isTranslating,
    required this.onTranslate,
  });

  static String generateReadingTip(String text) {
    final lowerText = text.toLowerCase();
    final words = text.trim().split(RegExp(r'\s+'));
    final wordCount = words.length;

    if (RegExp(r'\b\w+ed\b').hasMatch(lowerText)) {
      return 'Phonics Tip: Words ending in "-ed" can sound like /t/, /d/, or /id/ depending on the root word.';
    } else if (lowerText.contains('th')) {
      return 'Phonics Tip: Watch your "th" sounds! Remember to place your tongue slightly between your teeth.';
    } else if (RegExp(
      r'\b(can|could|should|would|will|must)\b',
    ).hasMatch(lowerText)) {
      return 'Grammar Tip: Modal verbs (like can/should) are usually unstressed in natural spoken English.';
    } else if (RegExp(r"\b\w+'\w+\b").hasMatch(lowerText)) {
      return 'Fluency Tip: This text contains contractions (e.g., don\'t). Pronounce them smoothly as a single sound.';
    } else if (text.contains('?')) {
      return 'Intonation Tip: Questions usually end with a rising voice intonation.';
    } else if (text.contains('!')) {
      return 'Expression Tip: Exclamation marks indicate strong emotion. Read with emphasis!';
    } else if (text.contains('"') || text.contains("'")) {
      return 'Expression Tip: Quotes indicate someone is speaking. Try to read with character!';
    } else if (wordCount > 15) {
      return 'Pacing Tip: Long text! Remember to breathe and pause briefly at commas and periods.';
    } else if (RegExp(r'\b(and|but|or|because)\b').hasMatch(lowerText)) {
      return 'Fluency Tip: Use conjunctions to smoothly link your thoughts together without pausing.';
    } else {
      return 'Pronunciation Tip: Focus on clearly articulating the final consonant of each word.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIndigo = const Color(0xFF6366F1);
    final textColor = isDark ? Colors.white : Colors.black87;

    final translationParts = translatedText?.split('\n\n') ?? [];
    final translatedBlockText = translationParts.isNotEmpty
        ? translationParts[0]
        : null;
    final translatedTip = translationParts.length > 1
        ? translationParts[1]
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryIndigo.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glowing Data Line Indicator
              Container(
                width: 4.w,
                height: 40.h,
                margin: EdgeInsets.only(top: 4.h),
                decoration: BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryIndigo.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_format_rounded,
                          size: 14.r,
                          color: primaryIndigo,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${block.text.trim().split(RegExp(r'\s+')).length} words',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryIndigo,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 14.r,
                          color: primaryIndigo,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Reading Data',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      block.text,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp, // slightly larger text for readability
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates_rounded,
                                size: 16.r,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  generateReadingTip(block.text),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (translatedTip != null) ...[
                            SizedBox(height: 8.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 24.w),
                                Expanded(
                                  child: Text(
                                    translatedTip,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: primaryIndigo,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (translatedBlockText != null) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: primaryIndigo.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.g_translate_rounded,
                              color: primaryIndigo,
                              size: 20.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                translatedBlockText,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  color: isDark
                                      ? const Color(0xFF818CF8)
                                      : primaryIndigo,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isTranslating) ...[
                      SizedBox(height: 16.h),
                      SizedBox(
                        height: 4.h,
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          color: primaryIndigo,
                          backgroundColor: primaryIndigo.withValues(alpha: 0.2),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 16.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ScaleButton(
                          onTap: () => onTranslate(index, block.text),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryIndigo.withValues(alpha: 0.2),
                                  const Color(
                                    0xFF4F46E5,
                                  ).withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: primaryIndigo.withValues(alpha: 0.4),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.g_translate_rounded,
                                  color: primaryIndigo,
                                  size: 16.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  context.tr(
                                    'translation.translate',
                                    fallback: 'Translate',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryIndigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
