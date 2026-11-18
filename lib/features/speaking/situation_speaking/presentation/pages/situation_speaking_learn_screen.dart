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

/// Interactive Learn Phase screen for Situation Speaking ("Contextual Response Discovery").
///
/// Instructs learners on situational awareness, communicative goals, tone & register,
/// pragmatic rules, and natural spoken phrase structures.
class SituationSpeakingLearnScreen extends StatefulWidget {
  final int level;

  const SituationSpeakingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SituationSpeakingLearnScreen> createState() =>
      _SituationSpeakingLearnScreenState();
}

class _SituationSpeakingLearnScreenState
    extends State<SituationSpeakingLearnScreen> {
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
        'assets/curriculum/speaking/situationSpeaking_learn_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SITUATIONSPEAKING_LEARN_FALLBACK_1',
          'situationText':
              'A new neighbor has just moved into the flat across from yours. You meet in the corridor and she smiles and says hello. Your name is Priya.',
          'targetPhrase': "Hi, I'm Priya. Nice to meet you.",
          'sampleAnswer':
              "Hello! I'm Priya, I've just seen you moving in. Nice to meet you.",
          'tone': 'Warm & Friendly',
          'culturalTip':
              'Native speakers rarely say only their name. Giving your name plus "Nice to meet you" is the standard two-part greeting: it shares information and conveys warmth.',
          'hint':
              'Give your name in a full, friendly sentence, then add the classic greeting.',
          'keyVocabulary': [
            'Priya',
            'Nice to meet you',
            'Moved into',
            'Corridor',
          ],
          'instruction':
              'Study the scenario context, ideal spoken response, and communicative tone.',
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
        gameType: 'situationSpeaking',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=situationSpeaking&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard = _cards[_cardIndex];
    final situationText = currentCard['situationText'] as String? ?? '';
    final targetPhrase = currentCard['targetPhrase'] as String? ?? '';
    final sampleAnswer = currentCard['sampleAnswer'] as String? ?? '';
    final tone = currentCard['tone'] as String? ?? 'Polite & Natural';
    final culturalTip = currentCard['culturalTip'] as String? ?? '';
    final hint = currentCard['hint'] as String? ?? '';
    final keyVocabulary =
        (currentCard['keyVocabulary'] as List<dynamic>? ?? []).cast<String>();

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Situation (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Situation Speaking Discovery',
      gameType: 'situationSpeaking',
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
                    'SITUATION ${_cardIndex + 1} OF ${_cards.length}',
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

            // Scenario Context Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.indigo500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.indigo500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.theater_comedy_outlined,
                              color: AppColors.indigo500,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REAL-LIFE SCENARIO',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.indigo500,
                                ),
                              ),
                              Text(
                                'Level ${widget.level} - Context',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.slate100 : AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 14.sp,
                              color: AppColors.indigo400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              tone,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    situationText,
                    key: const Key('situation_speaking_learn_situation_text'),
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Target Spoken Phrase Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.record_voice_over_outlined,
                          color: AppColors.emerald500,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'RECOMMENDED SPOKEN RESPONSE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.emerald500,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('situation_speaking_learn_audio_btn'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald500,
                          size: 24.sp,
                        ),
                        tooltip: 'Listen to native pronunciation',
                        onPressed: () => _playAudio(
                          sampleAnswer.isNotEmpty ? sampleAnswer : targetPhrase,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate800
                          : AppColors.indigo50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '"$targetPhrase"',
                      key: const Key('situation_speaking_learn_target_phrase'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate100 : AppColors.slate900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Pragmatic & Cultural Tip
            if (culturalTip.isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.amber500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMUNICATION TIP',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.amber500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            culturalTip,
                            key: const Key('situation_speaking_learn_cultural_tip'),
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.4,
                              color: isDark ? AppColors.slate100 : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 14.h),

            // Key Phrases / Vocabulary Chips
            if (keyVocabulary.isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KEY PHRASES & WORDS',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: keyVocabulary.map((vocab) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.indigo500.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            vocab,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 14.h),

            // Extended Model Response
            if (sampleAnswer.isNotEmpty && sampleAnswer != targetPhrase)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 16.sp,
                          color: isDark ? AppColors.slate400 : AppColors.slate600,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'EXTENDED NATIVE FORMULATION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: isDark ? AppColors.slate400 : AppColors.slate600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"$sampleAnswer"',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),

            if (hint.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  '💡 $hint',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
