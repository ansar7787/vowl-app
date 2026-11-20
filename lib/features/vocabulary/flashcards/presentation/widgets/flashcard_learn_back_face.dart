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
import 'flashcard_learn_example_box.dart';

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
  String? _translatedDefinition;
  String? _translatedExample;
  String? _translatedMistake;
  List<String>? _translatedCollocations;
  String? _translatedLocale;
  bool _showTranslated = false;

  void _speakText(String text, {String? locale}) {
    if (di.sl.isRegistered<TtsService>()) {
      TtsSpeakerButtonWidget.stopAll();
      di.sl<TtsService>().speak(text, locale: locale ?? 'en-US');
    }
  }

  String _buildTranslatableContent() {
    return [
      widget.quest.definition ?? '',
      widget.quest.example ?? '',
      widget.commonMistake ?? '',
      widget.collocations.join(', '),
    ].join('\n---\n');
  }

  void _applyTranslation(String fullText, String? locale) {
    final parts = fullText.split(RegExp(r'\n?---\n?'));
    setState(() {
      _translatedDefinition = parts.isNotEmpty && parts[0].isNotEmpty
          ? parts[0].trim()
          : fullText;
      _translatedExample = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1].trim()
          : null;
      _translatedMistake = parts.length > 2 && parts[2].isNotEmpty
          ? parts[2].trim()
          : null;
      _translatedCollocations = parts.length > 3 && parts[3].isNotEmpty
          ? parts[3]
                .split(RegExp(r'[,•\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
          : null;
      _translatedLocale = locale;
      _showTranslated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final isDark = widget.isDark;

    return GestureDetector(
      onTap: widget.onFlip,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            // Header: Word + Sound Button + Translate + Flip Front
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                    SizedBox(width: 8.w),
                    ScaleButton(
                      onTap: () =>
                          quest.word != null ? _speakText(quest.word!) : null,
                      child: Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.indigo500.withValues(alpha: 0.2)
                              : AppColors.indigo500.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 16.r,
                          color: isDark
                              ? AppColors.indigo400
                              : AppColors.indigo600,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TranslateButtonWidget(
                      originalText: _buildTranslatableContent(),
                      onTranslationComplete: (t) => _applyTranslation(t, null),
                      onTranslationWithLanguage: (t, loc) =>
                          _applyTranslation(t, loc),
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
                          color: isDark
                              ? AppColors.slate800
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 12.r,
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

            // Translation toggle bar across all learning content
            if (_translatedDefinition != null) ...[
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
                            _showTranslated ? 'Original (EN)' : 'Translated',
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
                  if (_showTranslated && _translatedDefinition != null)
                    TtsSpeakerButtonWidget(
                      text: _translatedDefinition!,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                      locale: _translatedLocale,
                      size: 16.r,
                    ),
                ],
              ),
              SizedBox(height: 8.h),
            ],

            // Definition (Tapping definition or card flips; dedicated buttons speak)
            Text(
              (_showTranslated && _translatedDefinition != null)
                  ? _translatedDefinition!
                  : (quest.definition ?? ''),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),

            SizedBox(height: 16.h),

            // Real-World Sentence with quote and sound icon
            if (quest.example != null)
              FlashcardLearnExampleBox(
                exampleText: (_showTranslated && _translatedExample != null)
                    ? _translatedExample!
                    : quest.example!,
                isDark: isDark,
                onSpeak: () {
                  if (_showTranslated && _translatedExample != null) {
                    _speakText(_translatedExample!, locale: _translatedLocale);
                  } else {
                    _speakText(quest.example!);
                  }
                },
              ),

            SizedBox(height: 14.h),

            // Natural Collocations (Refined clean pills with speech on tap)
            FlashcardLearnCollocationsSection(
              collocations:
                  (_showTranslated &&
                      _translatedCollocations != null &&
                      _translatedCollocations!.isNotEmpty)
                  ? _translatedCollocations!
                  : widget.collocations,
              isDark: isDark,
              onSpeak: _speakText,
            ),

            SizedBox(height: 14.h),

            // Common Mistake Alert Box (Translates in sync)
            if (widget.commonMistake != null)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
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
                        (_showTranslated && _translatedMistake != null)
                            ? _translatedMistake!
                            : widget.commonMistake!,
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
      ),
    );
  }
}
