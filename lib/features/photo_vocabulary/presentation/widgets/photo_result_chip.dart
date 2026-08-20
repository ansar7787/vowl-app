import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';

class PhotoResultChip extends StatelessWidget {
  final ImageLabel label;
  final int index;
  final String? translatedText;
  final bool isTranslating;
  final void Function(int, String) onTranslate;
  final void Function(String) onPlayPronunciation;

  const PhotoResultChip({
    super.key,
    required this.label,
    required this.index,
    required this.translatedText,
    required this.isTranslating,
    required this.onTranslate,
    required this.onPlayPronunciation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = const Color(0xFF14B8A6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final entry = PhotoVocabularyDictionary.getEntry(label.label);

    final translationParts = translatedText?.split('\n\n') ?? [];
    final translatedWord = translationParts.isNotEmpty
        ? translationParts[0]
        : null;
    final translatedExample = translationParts.length > 1
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
                color: primaryTeal.withValues(alpha: 0.1),
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
                  color: primaryTeal,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withValues(alpha: 0.6),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.label,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (entry.ipa != 'Noun') ...[
                                SizedBox(height: 2.h),
                                Text(
                                  entry.ipa,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: primaryTeal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: primaryTeal.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '${(label.confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF2DD4BF)
                                      : primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                          Text(
                            entry.definition,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16.r,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  entry.grammarTip,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            '${context.tr('daily_words.example', fallback: 'Example')}: "${entry.example}"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (translatedExample != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              '${context.tr('daily_words.example', fallback: 'Example')}: "$translatedExample"',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryTeal,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (translatedWord != null) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: primaryTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.g_translate_rounded,
                              color: primaryTeal,
                              size: 20.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                translatedWord,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.sp,
                                  color: isDark
                                      ? const Color(0xFF2DD4BF)
                                      : primaryTeal,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
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
                          color: primaryTeal,
                          backgroundColor: primaryTeal.withValues(alpha: 0.2),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 16.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ScaleButton(
                          onTap: () => onTranslate(index, label.label),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryTeal.withValues(alpha: 0.2),
                                  const Color(
                                    0xFF0D9488,
                                  ).withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: primaryTeal.withValues(alpha: 0.4),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.g_translate_rounded,
                                  color: primaryTeal,
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
                                    color: primaryTeal,
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
              SizedBox(width: 12.w),
              ScaleButton(
                onTap: () => onPlayPronunciation(label.label),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryTeal.withValues(alpha: 0.2),
                        const Color(0xFF0D9488).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryTeal.withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: isDark ? const Color(0xFF2DD4BF) : primaryTeal,
                    size: 24.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
