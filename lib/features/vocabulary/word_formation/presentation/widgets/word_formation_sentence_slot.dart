import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'word_formation_colors.dart';
import 'word_formation_morpheme_formula.dart';
import 'word_formation_slot_content.dart';

/// Card rendering the sentence context with an animated morphological slot
/// and optional on-demand sentence context translation with translated audio.
class WordFormationSentenceSlot extends StatefulWidget {
  final String sentence;
  final String? formedWord;
  final String? rootWord;
  final String? targetRole;
  final String? roleClue;
  final bool isAnswered;
  final bool? isCorrect;
  final Color primaryColor;
  final String? bounceFeedback;
  final int shakeCount;

  const WordFormationSentenceSlot({
    super.key,
    required this.sentence,
    this.formedWord, this.rootWord, this.targetRole, this.roleClue,
    required this.isAnswered, this.isCorrect, required this.primaryColor,
    this.bounceFeedback, this.shakeCount = 0,
  });

  @override
  State<WordFormationSentenceSlot> createState() =>
      _WordFormationSentenceSlotState();
}

class _WordFormationSentenceSlotState extends State<WordFormationSentenceSlot> {
  String? _translatedSentence;
  String? _targetLanguageCode;
  bool _showTranslated = false;

  String _stripEmoji(String text) => text.replaceAll(
        RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}]', unicode: true),
        '',
      );

  @override
  void didUpdateWidget(covariant WordFormationSentenceSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentence != widget.sentence || oldWidget.formedWord != widget.formedWord) {
      _translatedSentence = null;
      _targetLanguageCode = null;
      _showTranslated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = widget.sentence.split('_______');
    final beforeText = parts.isNotEmpty ? parts[0] : widget.sentence;
    final afterText = parts.length > 1 ? parts[1] : '';
    final roleColor = WordFormationColors.forRole(widget.targetRole);
    final textToTranslate = (widget.formedWord != null && widget.formedWord!.isNotEmpty)
        ? widget.sentence.replaceAll('_______', widget.formedWord!)
        : widget.sentence.replaceAll('_______', '_____');

    final statusColor = widget.isCorrect == true
        ? AppColors.gameCorrect
        : (widget.isCorrect == false ? AppColors.gameIncorrect : roleColor);

    final cardContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusColor.withValues(alpha: widget.isCorrect != null ? 0.45 : 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isAnswered && widget.isCorrect == true ? AppColors.gameCorrect : roleColor)
                .withValues(alpha: widget.isAnswered && widget.isCorrect == true ? 0.1 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Root Word Pill, Role Clue Badge, Translation & Sound Buttons
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (widget.rootWord != null && widget.rootWord!.isNotEmpty) ...[
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: widget.primaryColor.withValues(alpha: 0.28), width: 1.0),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ROOT: ${widget.rootWord!.toUpperCase()}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: widget.primaryColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                ScaleButton(
                                  onTap: () => di.sl<TtsService>().speak(widget.rootWord!),
                                  child: Icon(Icons.volume_up_rounded, color: widget.primaryColor, size: 12.r),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.0),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_fix_normal_rounded, color: roleColor, size: 12.r),
                              SizedBox(width: 3.w),
                              Text(
                                widget.targetRole != null ? 'TARGET: ${widget.targetRole!.toUpperCase()}' : 'BLANK',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              // Context Sentence Translation Button
              TranslateButtonWidget(
                originalText: textToTranslate,
                onTranslationComplete: (translated) {
                  setState(() {
                    _translatedSentence = translated;
                    _showTranslated = true;
                  });
                },
                onTranslationWithLanguage: (translated, langCode) {
                  setState(() {
                    _translatedSentence = translated;
                    _targetLanguageCode = langCode;
                    _showTranslated = true;
                  });
                },
                iconSize: 14.r,
                iconColor: roleColor,
                padding: EdgeInsets.all(2.r),
              ),
              if (widget.isAnswered && widget.formedWord != null) ...[
                SizedBox(width: 3.w),
                ScaleButton(
                  onTap: () {
                    final fullText = widget.sentence.replaceAll('_______', widget.formedWord!);
                    di.sl<TtsService>().speak(fullText);
                  },
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volume_up_rounded, color: widget.primaryColor, size: 16.r),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),

          // Main Sentence Flow with Embedded Slot
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.5,
              ),
              children: [
                TextSpan(text: beforeText),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: widget.isAnswered ? statusColor.withValues(alpha: 0.16) : roleColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: widget.isAnswered ? statusColor : roleColor, width: 1.5),
                    ),
                    child: WordFormationSlotContent(
                      isAnswered: widget.isAnswered,
                      formedWord: widget.formedWord,
                      targetRole: widget.targetRole,
                      isCorrect: widget.isCorrect,
                      rootWord: widget.rootWord,
                      roleColor: roleColor,
                    ),
                  ),
                ),
                TextSpan(text: afterText),
              ],
            ),
          ),

          // Translated Sentence Banner (with native-language audio speaker)
          if (_showTranslated && _translatedSentence != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: widget.primaryColor.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded, size: 13.r, color: widget.primaryColor),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showTranslated = false),
                      child: Text(
                        _translatedSentence!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  if (_targetLanguageCode != null && _targetLanguageCode!.isNotEmpty) ...[
                    SizedBox(width: 4.w),
                    TtsSpeakerButtonWidget(
                      text: _translatedSentence!,
                      locale: _targetLanguageCode,
                      color: widget.primaryColor,
                      size: 14.r,
                    ),
                  ],
                  SizedBox(width: 6.w),
                  ScaleButton(
                    onTap: () => setState(() => _showTranslated = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.undo_rounded, size: 10.r, color: widget.primaryColor),
                          SizedBox(width: 3.w),
                          Text(
                            'Original (EN)',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Role Clue or Bounce Feedback
          if (widget.roleClue != null && !widget.isAnswered) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: widget.primaryColor.withValues(alpha: 0.8),
                  size: 14.r,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _stripEmoji(widget.roleClue!),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (widget.isAnswered && widget.isCorrect == true && widget.formedWord != null && widget.rootWord != null) ...[
            SizedBox(height: 12.h),
            WordFormationMorphemeFormula(
              rootWord: widget.rootWord!,
              formedWord: widget.formedWord!,
              targetRole: widget.targetRole,
            ),
          ],

          if (widget.isCorrect == false && widget.bounceFeedback != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.gameIncorrect.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.gameIncorrect.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.replay_rounded, color: AppColors.gameIncorrect, size: 16.r),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _stripEmoji(widget.bounceFeedback!),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gameIncorrect,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return ShakeableWrapper(
      shakeCount: widget.shakeCount,
      child: cardContent,
    );
  }
}
