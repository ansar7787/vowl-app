import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'flashcard_learn_collocations_section.dart';

/// Back face of the 3D Discovery Card in Flashcard Learn Phase.
///
/// Features inline AI offline translation with language selection,
/// monetization ad-gating, and instant tap-to-speak audio on every element.
class FlashcardLearnBackFace extends StatefulWidget {
  final PhasedQuest quest;
  final bool isDark;
  final VoidCallback onFlip;
  final List<String> collocations;
  final String? commonMistake;
  final String contextDomain;
  final VoidCallback? onSpeakExample;

  const FlashcardLearnBackFace({
    super.key,
    required this.quest,
    required this.isDark,
    required this.onFlip,
    required this.collocations,
    this.commonMistake,
    required this.contextDomain,
    this.onSpeakExample,
  });

  @override
  State<FlashcardLearnBackFace> createState() => _FlashcardLearnBackFaceState();
}

class _FlashcardLearnBackFaceState extends State<FlashcardLearnBackFace> {
  String? _translatedText;
  String? _translatedLocale;
  bool _showTranslated = true;

  void _speakText(String text, {String? locale}) {
    if (di.sl.isRegistered<TtsService>()) {
      TtsSpeakerButtonWidget.stopAll();
      di.sl<TtsService>().speak(text, locale: locale ?? 'en-US');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? AppColors.indigo500.withValues(alpha: 0.35)
              : AppColors.indigo500.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Word + Audio + Translate + Flip to Front
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleButton(
                onTap: () =>
                    quest.word != null ? _speakText(quest.word!) : null,
                child: Row(
                  children: [
                    Text(
                      quest.word ?? '',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.slate950,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.volume_up_rounded,
                      size: 16.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TranslateButtonWidget(
                    originalText:
                        '${quest.definition ?? ""}\n${quest.example ?? ""}',
                    onTranslationComplete: (t) => mounted
                        ? setState(() {
                            _translatedText = t;
                            _showTranslated = true;
                          })
                        : null,
                    onTranslationWithLanguage: (t, loc) => mounted
                        ? setState(() {
                            _translatedText = t;
                            _translatedLocale = loc;
                            _showTranslated = true;
                          })
                        : null,
                  ),
                  SizedBox(width: 8.w),
                  ScaleButton(
                    onTap: widget.onFlip,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flip_rounded,
                            size: 14.r,
                            color: AppColors.indigo500,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Front',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Translation toggle bar if translation exists
          if (_translatedText != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScaleButton(
                  onTap: () =>
                      setState(() => _showTranslated = !_showTranslated),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 12.r,
                          color: AppColors.indigo500,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _showTranslated ? 'Original' : 'Translated',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showTranslated)
                  TtsSpeakerButtonWidget(
                    text: _translatedText!,
                    color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    locale: _translatedLocale,
                    size: 16.r,
                  ),
              ],
            ),
            SizedBox(height: 8.h),
          ],

          // Definition (Original or Translated, tap to speak)
          ScaleButton(
            onTap: () {
              if (_showTranslated && _translatedText != null) {
                _speakText(_translatedText!, locale: _translatedLocale);
              } else if (quest.definition != null) {
                _speakText(quest.definition!);
              }
            },
            child: Text(
              (_showTranslated && _translatedText != null)
                  ? _translatedText!
                  : (quest.definition ?? ''),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Real-World Sentence with quote and inline listen button
          if (quest.example != null)
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.6)
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 20.r,
                    color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ScaleButton(
                      onTap: () => _speakText(quest.example!),
                      child: Text(
                        quest.example!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          color: isDark
                              ? AppColors.slate200
                              : AppColors.slate800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  ScaleButton(
                    onTap:
                        widget.onSpeakExample ??
                        () => _speakText(quest.example!),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 18.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 14.h),

          // Natural Collocations (Tap to Speak)
          FlashcardLearnCollocationsSection(
            collocations: widget.collocations,
            isDark: isDark,
            onSpeak: _speakText,
          ),

          SizedBox(height: 14.h),

          // Common Mistake Alert Box
          if (widget.commonMistake != null)
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18.r,
                    color: Colors.amber.shade700,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.commonMistake!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
