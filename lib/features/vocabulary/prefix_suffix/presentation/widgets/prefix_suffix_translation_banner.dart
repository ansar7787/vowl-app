import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Reusable 1-Click Translation & Translated Native TTS Banner for Prefix & Suffix.
///
/// Features:
/// - 1-Click Offline AI Translation via [TranslateButtonWidget].
/// - Instant toggle between Translated (native language) and Original (English).
/// - Translated Text-To-Speech (TTS) narration calibrated to target locale.
/// - Themed clean-white Light Mode and midnight Dark Mode styling.
class PrefixSuffixTranslationBanner extends StatefulWidget {
  final String originalText;
  final Color accentColor;
  final bool isDark;
  final String? label;

  const PrefixSuffixTranslationBanner({
    super.key,
    required this.originalText,
    this.accentColor = AppColors.emerald500,
    required this.isDark,
    this.label,
  });

  @override
  State<PrefixSuffixTranslationBanner> createState() =>
      _PrefixSuffixTranslationBannerState();
}

class _PrefixSuffixTranslationBannerState
    extends State<PrefixSuffixTranslationBanner> {
  String? _translatedText;
  String? _targetLanguageCode;
  bool _showTranslated = false;

  @override
  void didUpdateWidget(covariant PrefixSuffixTranslationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalText != widget.originalText) {
      _translatedText = null;
      _targetLanguageCode = null;
      _showTranslated = false;
    }
  }

  void _toggleLanguage() {
    if (_translatedText != null) {
      setState(() => _showTranslated = !_showTranslated);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.originalText.trim().isEmpty) return const SizedBox.shrink();

    final isTranslatedActive = _showTranslated && _translatedText != null;
    final displayText = isTranslatedActive
        ? _translatedText!
        : widget.originalText;
    final activeLocale = isTranslatedActive ? _targetLanguageCode : 'en-US';

    final bgColor = widget.isDark
        ? widget.accentColor.withValues(alpha: 0.12)
        : widget.accentColor.withValues(alpha: 0.08);
    final borderColor = widget.accentColor.withValues(
      alpha: widget.isDark ? 0.35 : 0.25,
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate_rounded,
                size: 14.sp,
                color: widget.accentColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.label ??
                      (isTranslatedActive ? 'Translation' : 'English'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: widget.accentColor,
                  ),
                ),
              ),
              if (_translatedText != null) ...[
                ScaleButton(
                  onTap: _toggleLanguage,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark ? AppColors.slate800 : Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: widget.isDark
                            ? AppColors.slate700
                            : AppColors.slate300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 12.sp,
                          color: widget.isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _showTranslated ? 'Original (EN)' : 'Translated',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.slate200
                                : AppColors.slate800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              TranslateButtonWidget(
                originalText: widget.originalText,
                iconSize: 15.sp,
                iconColor: widget.accentColor,
                padding: EdgeInsets.all(2.w),
                onTranslationComplete: (translated) {
                  if (mounted) {
                    setState(() {
                      _translatedText = translated;
                      _showTranslated = true;
                    });
                  }
                },
                onTranslationWithLanguage: (translated, langCode) {
                  if (mounted) {
                    setState(() {
                      _translatedText = translated;
                      _targetLanguageCode = langCode;
                      _showTranslated = true;
                    });
                  }
                },
              ),
              SizedBox(width: 4.w),
              TtsSpeakerButtonWidget(
                text: displayText,
                locale: activeLocale,
                color: widget.accentColor,
                size: 16.sp,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          GestureDetector(
            onTap: _toggleLanguage,
            child: Text(
              displayText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5.sp,
                fontStyle: isTranslatedActive
                    ? FontStyle.italic
                    : FontStyle.normal,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: widget.isDark ? AppColors.slate100 : AppColors.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
