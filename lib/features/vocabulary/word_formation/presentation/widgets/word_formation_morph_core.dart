import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Central interactive hub displaying the base morphological root word
/// with audio pronunciation and on-demand root definition translation with translated audio.
class WordFormationMorphCore extends StatefulWidget {
  final String rootWord;
  final String? rootMeaning;
  final Color primaryColor;
  final bool isDark;

  const WordFormationMorphCore({
    super.key,
    required this.rootWord,
    this.rootMeaning,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  State<WordFormationMorphCore> createState() => _WordFormationMorphCoreState();
}

class _WordFormationMorphCoreState extends State<WordFormationMorphCore> {
  String? _translatedMeaning;
  String? _targetLanguageCode;
  bool _showTranslated = false;

  @override
  void didUpdateWidget(covariant WordFormationMorphCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootMeaning != widget.rootMeaning ||
        oldWidget.rootWord != widget.rootWord) {
      _translatedMeaning = null;
      _targetLanguageCode = null;
      _showTranslated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor;
    final isDark = widget.isDark;
    final rootMeaning = widget.rootMeaning;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: primaryColor,
                size: 14.r,
              ),
              SizedBox(width: 5.w),
              Text(
                'ROOT WORD',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 6.w),
              ScaleButton(
                onTap: () {
                  di.sl<TtsService>().speak(widget.rootWord);
                },
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: primaryColor,
                    size: 15.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Large Root Word
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.rootWord.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.slate900,
                letterSpacing: 1.0,
              ),
            ),
          ),

          if (rootMeaning != null && rootMeaning.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: _translatedMeaning != null
                        ? () => setState(
                              () => _showTranslated = !_showTranslated,
                            )
                        : null,
                    child: Text(
                      _showTranslated && _translatedMeaning != null
                          ? _translatedMeaning!
                          : rootMeaning,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontStyle: _showTranslated
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                TranslateButtonWidget(
                  originalText: rootMeaning,
                  onTranslationComplete: (translated) {
                    setState(() {
                      _translatedMeaning = translated;
                      _showTranslated = true;
                    });
                  },
                  onTranslationWithLanguage: (translated, langCode) {
                    setState(() {
                      _translatedMeaning = translated;
                      _targetLanguageCode = langCode;
                      _showTranslated = true;
                    });
                  },
                  iconSize: 13.r,
                  iconColor: primaryColor,
                  padding: EdgeInsets.all(4.r),
                ),
                if (_showTranslated &&
                    _translatedMeaning != null &&
                    _targetLanguageCode != null &&
                    _targetLanguageCode!.isNotEmpty) ...[
                  SizedBox(width: 4.w),
                  TtsSpeakerButtonWidget(
                    text: _translatedMeaning!,
                    locale: _targetLanguageCode,
                    color: primaryColor,
                    size: 14.r,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
