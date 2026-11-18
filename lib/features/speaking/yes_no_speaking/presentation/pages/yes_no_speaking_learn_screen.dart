import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Yes / No Speaking ("Statement Verification & Agreement").
///
/// Instructs learners on distinguishing exact spoken sentences from lexical mismatches,
/// spotting pivot contradiction words, and confirming spoken claims accurately.
class YesNoSpeakingLearnScreen extends StatefulWidget {
  final int level;

  const YesNoSpeakingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<YesNoSpeakingLearnScreen> createState() =>
      _YesNoSpeakingLearnScreenState();
}

class _YesNoSpeakingLearnScreenState extends State<YesNoSpeakingLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fallbackCards;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/speaking/yesNoSpeaking_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelCards.isNotEmpty) {
        setState(() {
          _cards = levelCards;
        });
      }
    } catch (_) {
      // Retain fallback cards on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackCards => [
        {
          'id': 'SPK_YESNOSPEAKING_LEARN_FALLBACK_1',
          'prompt': 'My mother cooks rice for dinner.',
          'sampleAnswer': 'My mother cooks pasta for dinner.',
          'isMatch': false,
          'matchLabel': 'Contradiction / Mismatch (NO)',
          'explanation':
              'Rice and pasta are both normal dinner foods, so nothing sounds strange. Only the food word tells you which meal is on the table.',
          'hint': 'The food at the end of the sentence is worth catching.',
          'followUpQuestion': 'Read the sentence aloud, slowly.',
          'instruction':
              'Compare the spoken audio claim with the written text to observe key lexical agreements or differences.',
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  void _onComplete() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'yesNoSpeaking',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=yesNoSpeaking&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard = _cards[_cardIndex];
    final promptText = currentCard['prompt'] as String? ?? '';
    final sampleText = currentCard['sampleAnswer'] as String? ?? '';
    final isMatch = currentCard['isMatch'] as bool? ??
        (promptText.trim().toLowerCase() == sampleText.trim().toLowerCase());
    final explanation = currentCard['explanation'] as String? ?? '';
    final hint = currentCard['hint'] as String? ?? '';
    final followUpQuestion = currentCard['followUpQuestion'] as String? ?? '';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Statement (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Statement Verification',
      gameType: 'yesNoSpeaking',
      level: widget.level,
      actionLabel: actionLabel,
      onComplete: _onComplete,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Badges
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'STATEMENT ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'LEVEL ${widget.level}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Spoken Statement Box
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        color: AppColors.indigo500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'SPOKEN CLAIM (AUDIO)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('yes_no_speaking_learn_prompt_audio'),
                        onTap: () => _playAudio(promptText),
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.indigo500,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '"$promptText"',
                    key: const Key('yes_no_speaking_learn_prompt_text'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // Relation Indicator
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isMatch
                      ? AppColors.emerald500.withValues(alpha: 0.15)
                      : AppColors.rose500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isMatch
                        ? AppColors.emerald500.withValues(alpha: 0.5)
                        : AppColors.rose500.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMatch
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isMatch ? AppColors.emerald500 : AppColors.rose500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isMatch ? 'EXACT MATCH (YES)' : 'CONTRADICTION (NO)',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isMatch
                            ? AppColors.emerald500
                            : AppColors.rose500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Written Statement Box
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: (isMatch ? AppColors.emerald500 : AppColors.rose500)
                      .withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: isMatch
                            ? AppColors.emerald500
                            : AppColors.rose500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'WRITTEN SENTENCE (CLAIM)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isMatch
                                ? AppColors.emerald500
                                : AppColors.rose500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('yes_no_speaking_learn_sample_audio'),
                        onTap: () => _playAudio(sampleText),
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: (isMatch
                                    ? AppColors.emerald500
                                    : AppColors.rose500)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: isMatch
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '"$sampleText"',
                    key: const Key('yes_no_speaking_learn_sample_text'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Native Speaker Insight
            if (explanation.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'NATIVE SPEAKER INSIGHT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        height: 1.45,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Detection Hint
            if (hint.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      color: AppColors.amber500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EAR TRAINING CLUE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.amber500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            hint,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Spoken Drill Prompt
            if (followUpQuestion.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: AppColors.emerald500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPEAKING DRILL',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.emerald500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            followUpQuestion,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
