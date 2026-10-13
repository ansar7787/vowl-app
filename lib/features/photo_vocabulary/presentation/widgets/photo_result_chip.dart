import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';
import 'package:lucide_icons/lucide_icons.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color2dd4bf = Color(0xFF2DD4BF);
  static const Color color0d9488 = Color(0xFF0D9488);
}

class PhotoResultChip extends StatelessWidget {
  final ImageLabel label;
  final int index;
  final String? translatedText;
  final bool isTranslating;
  final bool isBountyTarget;
  final bool isSaved;
  final void Function(int, String) onTranslate;
  final void Function(String) onPlayPronunciation;
  final void Function(String word)? onToggleSave;

  const PhotoResultChip({
    super.key,
    required this.label,
    required this.index,
    required this.translatedText,
    required this.isTranslating,
    this.isBountyTarget = false,
    this.isSaved = false,
    required this.onTranslate,
    required this.onPlayPronunciation,
    this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryTeal = AppColors.teal500;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final entry = PhotoVocabularyDictionary.getEntry(label.label);

    final rawParts = translatedText != null
        ? (translatedText!.contains('\n\n')
            ? translatedText!.split('\n\n')
            : translatedText!.split('\n'))
        : <String>[];
    final translationParts = rawParts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final translatedWord = translationParts.isNotEmpty
        ? translationParts[0]
        : null;
    final translatedExample = translationParts.length > 1
        ? translationParts.sublist(1).join(' ')
        : null;

    final confidencePercent = (label.confidence * 100).round();

    final borderColor = isBountyTarget
        ? AppColors.teal500
        : (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.06));

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark
            ? (isBountyTarget
                ? AppColors.teal500.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.55))
            : (isBountyTarget
                ? AppColors.teal500.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: borderColor,
          width: isBountyTarget ? 2.w : 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isBountyTarget
                ? AppColors.teal500.withValues(alpha: 0.2)
                : primaryTeal.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Accent Indicator
          Container(
            width: 4.w,
            height: 38.h,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: isBountyTarget ? AppColors.amber500 : primaryTeal,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bounty Target Banner (if matched)
                if (isBountyTarget) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.6),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 13.r,
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          context.tr(
                            'vocabulary.bounty_match_badge',
                            fallback: 'DAILY BOUNTY TARGET',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Header Row: Word, Audio Button & Confidence Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  label.label,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Semantics(
                                label: 'Listen to pronunciation for ${label.label}',
                                button: true,
                                child: ScaleButton(
                                  onTap: () {
                                    try {
                                      di.sl<HapticService>().light();
                                    } catch (_) {}
                                    onPlayPronunciation(label.label);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(7.r),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryTeal.withValues(alpha: 0.3),
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: isDark
                                          ? _LocalPalette.color2dd4bf
                                          : primaryTeal,
                                      size: 18.r,
                                    ),
                                  ),
                                ),
                              ),
                              if (onToggleSave != null) ...[
                                SizedBox(width: 6.w),
                                Semantics(
                                  label: isSaved
                                      ? 'Remove ${label.label} from Vocab Notebook'
                                      : 'Save ${label.label} to Vocab Notebook',
                                  button: true,
                                  child: ScaleButton(
                                    onTap: () => onToggleSave!(label.label),
                                    child: Container(
                                      padding: EdgeInsets.all(7.r),
                                      decoration: BoxDecoration(
                                        color: isSaved
                                            ? AppColors.amber500.withValues(alpha: 0.2)
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : Colors.black.withValues(alpha: 0.04)),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSaved
                                              ? AppColors.amber500.withValues(alpha: 0.6)
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.15)
                                                  : Colors.black.withValues(alpha: 0.1)),
                                          width: 1.w,
                                        ),
                                      ),
                                      child: Icon(
                                        isSaved
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: isSaved
                                            ? (isDark
                                                ? Colors.amber.shade300
                                                : AppColors.amber500)
                                            : (isDark
                                                ? Colors.white54
                                                : Colors.black45),
                                        size: 18.r,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // IPA Phonetic transcription & CEFR Level Badge
                          if (entry.ipa != null || entry.cefr != null) ...[
                            SizedBox(height: 3.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (entry.ipa != null)
                                  Flexible(
                                    child: Text(
                                      entry.ipa!,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                if (entry.cefr != null) ...[
                                  if (entry.ipa != null) SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 1.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: primaryTeal.withValues(alpha: 0.35),
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Text(
                                      entry.cefr!.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? _LocalPalette.color2dd4bf
                                            : primaryTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],

                          // Inline Native Word Translation
                          if (translatedWord != null) ...[
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.g_translate_rounded,
                                  size: 14.r,
                                  color: primaryTeal,
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    translatedWord,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? _LocalPalette.color2dd4bf
                                          : primaryTeal,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Confidence Badge
                    Semantics(
                      label: 'Confidence $confidencePercent percent',
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: primaryTeal.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '$confidencePercent%',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? _LocalPalette.color2dd4bf
                                : primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Definition + Grammar Tip + Example Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Definition
                      Text(
                        entry.definition,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Grammar Tip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 15.r,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade700,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              entry.grammarTip,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.amber.shade300
                                    : Colors.amber.shade800,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // English Example
                      Text(
                        '${context.tr('daily_words.example', fallback: 'Example')}: "${entry.example}"',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black87,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),

                      // Translated Example
                      if (translatedExample != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '"$translatedExample"',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryTeal,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Bottom Action: Translate Button or Translating Indicator
                if (translatedWord == null) ...[
                  SizedBox(height: 12.h),
                  if (isTranslating) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: SizedBox(
                        height: 4.h,
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          color: primaryTeal,
                          backgroundColor: primaryTeal.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: 'Translate word ${label.label}',
                        button: true,
                        child: ScaleButton(
                          onTap: () {
                            try {
                              di.sl<HapticService>().light();
                            } catch (_) {}
                            onTranslate(index, label.label);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryTeal.withValues(alpha: 0.2),
                                  _LocalPalette.color0d9488.withValues(alpha: 0.08),
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
                                  size: 15.r,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  context.tr(
                                    'translation.translate',
                                    fallback: 'Translate',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    )
    .animate(delay: (100 * index).ms)
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }
}
