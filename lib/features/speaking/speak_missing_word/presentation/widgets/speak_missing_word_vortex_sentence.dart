import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SpeakMissingWordVortexSentence extends StatelessWidget {
  final String text;
  final String insertedWord;
  final Color primaryColor;
  final bool isDark;

  const SpeakMissingWordVortexSentence({
    super.key,
    required this.text,
    required this.insertedWord,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Sentence: $text',
      child: GlassTile(
        key: const Key('speak_missing_word_vortex_sentence'),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: [
            Text(
              "COMPLETE THE SENTENCE",
              key: const Key('speak_missing_word_vortex_header'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                color: primaryColor,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              text,
              key: const Key('speak_missing_word_sentence_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 19.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.45,
              ),
            ),
            if (insertedWord.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Container(
                key: const Key('speak_missing_word_locked_option'),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13.r,
                      color: primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        "SELECTED WORD: ${insertedWord.toUpperCase()}",
                        key: const Key('speak_missing_word_locked_option_text'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
