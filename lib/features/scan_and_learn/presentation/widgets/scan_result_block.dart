import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color818cf8 = Color(0xFF818CF8);
  static const Color color4f46e5 = Color(0xFF4F46E5);
}

/// Interactive card widget rendering a single detected OCR [TextBlock] with
/// one-tap translation, audio pronunciation, and dictionary definitions.
class ScanResultBlock extends StatelessWidget {
  final TextBlock block;
  final int index;
  final String? translatedText;
  final bool isTranslating;
  final void Function(int, String) onTranslate;
  final void Function(String) onPlayPronunciation;
  final bool containsBounty;
  final String? bountyWord;
  final bool isSaved;
  final void Function(String text)? onToggleSave;

  const ScanResultBlock({
    super.key,
    required this.block,
    required this.index,
    required this.translatedText,
    required this.isTranslating,
    required this.onTranslate,
    required this.onPlayPronunciation,
    this.containsBounty = false,
    this.bountyWord,
    this.isSaved = false,
    this.onToggleSave,
  });

  static bool _isLikelyEnglish(String text) {
    if (text.isEmpty) return false;
    final asciiLetters = text.runes
        .where((r) => (r >= 65 && r <= 90) || (r >= 97 && r <= 122))
        .length;
    final totalLetters = text.runes
        .where(
          (r) => !RegExp(
            r'[\s\d\p{P}]',
            unicode: true,
          ).hasMatch(String.fromCharCode(r)),
        )
        .length;
    if (totalLetters == 0) return false;
    return asciiLetters / totalLetters > 0.8;
  }

  static String generateReadingTip(BuildContext context, String text) {
    final lowerText = text.toLowerCase();
    final words = text.trim().split(RegExp(r'\s+'));
    final wordCount = words.length;

    if (RegExp(r'\b\w+ed\b').hasMatch(lowerText)) {
      return context.tr(
        'translation.tip_ed',
        fallback:
            'Phonics Tip: Words ending in "-ed" can sound like /t/, /d/, or /id/ depending on the root word.',
      );
    } else if (lowerText.contains('th')) {
      return context.tr(
        'translation.tip_th',
        fallback:
            'Phonics Tip: Watch your "th" sounds! Remember to place your tongue slightly between your teeth.',
      );
    } else if (RegExp(
      r'\b(can|could|should|would|will|must)\b',
    ).hasMatch(lowerText)) {
      return context.tr(
        'translation.tip_modal',
        fallback:
            'Grammar Tip: Modal verbs (like can/should) are usually unstressed in natural spoken English.',
      );
    } else if (RegExp(r"\b\w+'\w+\b").hasMatch(lowerText)) {
      return context.tr(
        'translation.tip_contraction',
        fallback:
            'Fluency Tip: This text contains contractions (e.g., don\'t). Pronounce them smoothly as a single sound.',
      );
    } else if (text.contains('?')) {
      return context.tr(
        'translation.tip_question',
        fallback:
            'Intonation Tip: Questions usually end with a rising voice intonation.',
      );
    } else if (text.contains('!')) {
      return context.tr(
        'translation.tip_exclamation',
        fallback:
            'Expression Tip: Exclamation marks indicate strong emotion. Read with emphasis!',
      );
    } else if (text.contains('"') || text.contains("'")) {
      return context.tr(
        'translation.tip_quote',
        fallback:
            'Expression Tip: Quotes indicate someone is speaking. Try to read with character!',
      );
    } else if (wordCount > 15) {
      return context.tr(
        'translation.tip_pacing',
        fallback:
            'Pacing Tip: Long text! Remember to breathe and pause briefly at commas and periods.',
      );
    } else if (RegExp(r'\b(and|but|or|because)\b').hasMatch(lowerText)) {
      return context.tr(
        'translation.tip_conjunction',
        fallback:
            'Fluency Tip: Use conjunctions to smoothly link your thoughts together without pausing.',
      );
    } else {
      return context.tr(
        'translation.tip_default',
        fallback:
            'Pronunciation Tip: Focus on clearly articulating the final consonant of each word.',
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    try {
      Clipboard.setData(ClipboardData(text: block.text));
      di.sl<HapticService>().light();
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'common.copied_to_clipboard',
          fallback: 'Copied scanned text to clipboard!',
        ),
        type: CustomSnackBarType.success,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIndigo = AppColors.indigo500;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final translationParts = translatedText?.split('\n\n') ?? [];
    final translatedBlockText = translationParts.isNotEmpty
        ? translationParts[0]
        : null;
    final translatedTip = translationParts.length > 1
        ? translationParts[1]
        : null;

    final borderColor = containsBounty
        ? primaryIndigo
        : (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.06));

    final wordCount = block.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => RegExp(r'\w').hasMatch(w))
        .length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: isDark
                ? (containsBounty
                    ? primaryIndigo.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.55))
                : (containsBounty
                    ? primaryIndigo.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: borderColor,
              width: containsBounty ? 2.w : 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: containsBounty
                    ? primaryIndigo.withValues(alpha: 0.22)
                    : primaryIndigo.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Bounty Match Highlight Banner
              if (containsBounty && bountyWord != null) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
                          'translation.bounty_block_match',
                          args: [bountyWord!],
                          fallback: 'TARGET WORD DETECTED: "$bountyWord"',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 2. Header Row: Metadata + Action Toolbar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Data indicator bar
                  Container(
                    width: 4.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      color: containsBounty ? AppColors.amber500 : primaryIndigo,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.text_format_rounded,
                    size: 14.r,
                    color: primaryIndigo,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    context.tr(
                      'translation.words_count',
                      args: [wordCount.toString()],
                      fallback: '$wordCount words',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryIndigo,
                    ),
                  ),
                  const Spacer(),

                  // Copy to Clipboard Button
                  Semantics(
                    label: 'Copy scanned text',
                    button: true,
                    child: ScaleButton(
                      onTap: () => _copyToClipboard(context),
                      child: Container(
                        padding: EdgeInsets.all(7.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.1),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.copy,
                          size: 15.r,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Listen Audio Button
                  Semantics(
                    label: 'Listen to scanned text',
                    button: true,
                    child: ScaleButton(
                      onTap: () {
                        try {
                          di.sl<HapticService>().light();
                        } catch (_) {}
                        onPlayPronunciation(block.text);
                      },
                      child: Container(
                        padding: EdgeInsets.all(7.r),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryIndigo.withValues(alpha: 0.35),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: isDark ? _LocalPalette.color818cf8 : primaryIndigo,
                          size: 16.r,
                        ),
                      ),
                    ),
                  ),

                  // Vocab Notebook Bookmark Button
                  if (onToggleSave != null) ...[
                    SizedBox(width: 8.w),
                    Semantics(
                      label: isSaved
                          ? 'Remove from Vocab Notebook'
                          : 'Save to Vocab Notebook',
                      button: true,
                      child: ScaleButton(
                        onTap: () => onToggleSave!(block.text),
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
                            isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSaved
                                ? (isDark ? Colors.amber.shade300 : AppColors.amber500)
                                : (isDark ? Colors.white54 : Colors.black45),
                            size: 16.r,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),

              // 3. Primary Scanned English Text
              SelectableText(
                block.text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.35,
                ),
              ),

              // 4. Reading / Phonics Tip
              if (_isLikelyEnglish(block.text)) ...[
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
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
                            Icons.lightbulb_outline_rounded,
                            size: 16.r,
                            color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              generateReadingTip(context, block.text),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (translatedTip != null) ...[
                        SizedBox(height: 6.h),
                        Padding(
                          padding: EdgeInsets.only(left: 24.w),
                          child: Text(
                            translatedTip,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryIndigo,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // 5. Native Language Translation or Translate Action
              if (translatedBlockText != null) ...[
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: primaryIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: primaryIndigo.withValues(alpha: 0.28),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.g_translate_rounded,
                        color: primaryIndigo,
                        size: 18.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          translatedBlockText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            color: isDark
                                ? _LocalPalette.color818cf8
                                : primaryIndigo,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isTranslating) ...[
                SizedBox(height: 14.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: SizedBox(
                    height: 4.h,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      color: primaryIndigo,
                      backgroundColor: primaryIndigo.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: 14.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label: 'Translate text',
                    button: true,
                    child: ScaleButton(
                      onTap: () => onTranslate(index, block.text),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryIndigo.withValues(alpha: 0.22),
                              _LocalPalette.color4f46e5.withValues(alpha: 0.08),
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
                            SizedBox(width: 6.w),
                            Text(
                              context.tr(
                                'translation.translate',
                                fallback: 'Translate',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: primaryIndigo,
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
          ),
        ),
      ),
    )
        .animate(delay: (60 * index).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
