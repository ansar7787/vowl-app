import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_tts_helper.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Stateful wrapper providing 1-click native translation, translated TTS audio
/// (with budget-device locale pre-warming), and 1-tap toggle back to English.
class SynonymTranslatableArea extends StatefulWidget {
  final String textToTranslate;
  final Color primaryColor;
  final double buttonSize;
  final Widget Function(
    BuildContext context,
    Widget translateAction,
    Widget? translatedBanner,
  )
  builder;

  const SynonymTranslatableArea({
    super.key,
    required this.textToTranslate,
    required this.primaryColor,
    this.buttonSize = 18,
    required this.builder,
  });

  @override
  State<SynonymTranslatableArea> createState() =>
      _SynonymTranslatableAreaState();
}

class _SynonymTranslatableAreaState extends State<SynonymTranslatableArea> {
  String? _translatedText;
  String? _targetLocale;
  bool _showTranslated = false;

  @override
  void didUpdateWidget(covariant SynonymTranslatableArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textToTranslate != widget.textToTranslate) {
      _translatedText = null;
      _targetLocale = null;
      _showTranslated = false;
    }
  }

  void _applyTranslation(
    String expectedSource,
    String translated, [
    String? langCode,
  ]) {
    if (!mounted || expectedSource != widget.textToTranslate.trim()) return;
    final cleanCode = langCode?.trim();
    if (cleanCode != null && cleanCode.isNotEmpty) {
      SynonymTtsHelper.preWarm(locale: cleanCode);
    }
    setState(() {
      _translatedText = translated;
      if (cleanCode != null && cleanCode.isNotEmpty) {
        _targetLocale = cleanCode;
      }
      _showTranslated = true;
    });
  }

  void _toggleBackToEnglishOrTranslated() {
    SynonymTtsHelper.stopAll();
    if (_showTranslated) {
      SynonymTtsHelper.preWarm(locale: 'en-US');
    } else if (_targetLocale != null && _targetLocale!.isNotEmpty) {
      SynonymTtsHelper.preWarm(locale: _targetLocale);
    }
    setState(() {
      _showTranslated = !_showTranslated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanSource = widget.textToTranslate.trim();

    if (cleanSource.isEmpty) {
      return widget.builder(context, const SizedBox.shrink(), null);
    }

    final Widget translateAction = _translatedText == null
        ? TranslateButtonWidget(
            key: ValueKey<String>(cleanSource),
            originalText: cleanSource,
            iconSize: widget.buttonSize,
            iconColor: isDark ? AppColors.slate300 : widget.primaryColor,
            padding: EdgeInsets.all(2.r),
            onTranslationComplete: (translated) =>
                _applyTranslation(cleanSource, translated),
            onTranslationWithLanguage: (translated, code) =>
                _applyTranslation(cleanSource, translated, code),
          )
        : Semantics(
            button: true,
            label: _showTranslated ? 'Back to English' : 'Show translation',
            child: ScaleButton(
              debounceDuration: const Duration(milliseconds: 120),
              onTap: _toggleBackToEnglishOrTranslated,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(
                    alpha: isDark ? 0.24 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    SynonymUiTokens.badgeRadius,
                  ),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTranslated
                          ? Icons.undo_rounded
                          : Icons.translate_rounded,
                      size: 12.sp,
                      color: isDark ? AppColors.slate50 : widget.primaryColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _showTranslated ? 'EN' : 'Translated',
                      style: SynonymUiTokens.badgeLabel(
                        color: isDark ? AppColors.slate50 : widget.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    final Widget? translatedBanner =
        (_showTranslated && _translatedText != null)
        ? Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 8.h),
            padding: SynonymUiTokens.innerPanelPadding,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(
                alpha: isDark ? 0.16 : 0.07,
              ),
              borderRadius: BorderRadius.circular(
                SynonymUiTokens.controlRadius,
              ),
              border: Border.all(
                color: widget.primaryColor.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(
                    Icons.translate_rounded,
                    size: 15.sp,
                    color: isDark ? AppColors.slate50 : widget.primaryColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleBackToEnglishOrTranslated,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translatedText!,
                          style: SynonymUiTokens.supportBody(
                            color: SynonymUiTokens.primaryText(isDark),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.undo_rounded,
                              size: 12.sp,
                              color: isDark
                                  ? AppColors.slate200
                                  : widget.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Original (EN)',
                              style: SynonymUiTokens.badgeLabel(
                                color: isDark
                                    ? AppColors.slate200
                                    : widget.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_targetLocale != null && _targetLocale!.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  TtsSpeakerButtonWidget(
                    text: _translatedText!,
                    locale: _targetLocale,
                    color: widget.primaryColor,
                    size: 18,
                  ),
                ],
              ],
            ),
          )
        : null;

    return widget.builder(context, translateAction, translatedBanner);
  }
}
