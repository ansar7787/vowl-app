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
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1);
    final bgColor = isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.75);
    final entry = PhotoVocabularyDictionary.getEntry(label.label);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r), // Playful bubbly corners
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: primaryTeal.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${(label.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: 'Outfit', 
                              fontSize: 13.sp, 
                              fontWeight: FontWeight.w900, 
                              color: isDark ? const Color(0xFF2DD4BF) : primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.definition,
                            style: TextStyle(
                              fontFamily: 'Outfit', 
                              fontSize: 13.sp, 
                              fontWeight: FontWeight.w500, 
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, size: 14.r, color: Colors.amber),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  entry.grammarTip,
                                  style: TextStyle(
                                    fontFamily: 'Outfit', 
                                    fontSize: 12.sp, 
                                    fontWeight: FontWeight.w600, 
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Example: "${entry.example}"',
                            style: TextStyle(
                              fontFamily: 'Outfit', 
                              fontSize: 13.sp, 
                              fontWeight: FontWeight.w500, 
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (translatedText != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        translatedText!,
                        style: TextStyle(
                          fontFamily: 'Outfit', 
                          fontSize: 18.sp, 
                          fontWeight: FontWeight.w700, 
                          color: isDark ? const Color(0xFF2DD4BF) : primaryTeal,
                        ),
                      ),
                    ] else if (isTranslating) ...[
                      SizedBox(height: 12.h),
                      SizedBox(
                        height: 3.h, 
                        width: 48.w, 
                        child: LinearProgressIndicator(color: primaryTeal),
                      ),
                    ] else ...[
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () => onTranslate(index, label.label),
                        child: Text(
                          context.tr('translation.translate', fallback: 'Translate'),
                          style: TextStyle(
                            fontFamily: 'Outfit', 
                            fontSize: 15.sp, 
                            fontWeight: FontWeight.w600, 
                            color: isDark ? const Color(0xFF2DD4BF) : primaryTeal,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              ScaleButton(
                onTap: () => onPlayPronunciation(label.label),
                child: Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.volume_up_rounded, color: isDark ? Colors.white : primaryTeal, size: 26.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
