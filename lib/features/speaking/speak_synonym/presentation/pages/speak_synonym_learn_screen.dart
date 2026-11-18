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

/// Interactive Learn Phase screen for Speak Synonym ("Synonym & Lexical Expansion").
///
/// Instructs learners on spoken synonyms, situational replacements, contextual nuances,
/// and natural spoken cadence through audio and visual cues.
class SpeakSynonymLearnScreen extends StatefulWidget {
  final int level;

  const SpeakSynonymLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeakSynonymLearnScreen> createState() =>
      _SpeakSynonymLearnScreenState();
}

class _SpeakSynonymLearnScreenState extends State<SpeakSynonymLearnScreen> {
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
        'assets/curriculum/speaking/speakSynonym_learn_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SPEAKSYNONYM_LEARN_FALLBACK_1',
          'targetWord': 'big',
          'synonymWord': 'large',
          'contextSentence': 'Wow, your new apartment is big!',
          'alternativeSynonyms': ['large', 'huge', 'spacious', 'roomy'],
          'explanation':
              'Keep in mind that "large" is the everyday swap for "big" when you talk about the size of a place or object. "Spacious" and "roomy" go one step further and say there\'s plenty of space inside.',
          'hint':
              "Here's the scene: you're complimenting a friend's place. Which word says it has plenty of room?",
          'instruction':
              'Study "big", its closest spoken synonym "large", and usage contexts.',
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
        gameType: 'speakSynonym',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=speakSynonym&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard = _cards[_cardIndex];
    final targetWord = currentCard['targetWord'] as String? ?? '';
    final synonymWord = currentCard['synonymWord'] as String? ?? '';
    final contextSentence = currentCard['contextSentence'] as String? ?? '';
    final alternativeSynonyms =
        (currentCard['alternativeSynonyms'] as List<dynamic>? ?? [])
            .cast<String>();
    final explanation = currentCard['explanation'] as String? ?? '';
    final hint = currentCard['hint'] as String? ?? '';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Word (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Synonym Discovery',
      gameType: 'speakSynonym',
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
                    'SYNONYM PAIR ${_cardIndex + 1} OF ${_cards.length}',
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

            // Synonym Transformation Card
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
                children: [
                  Row(
                    children: [
                      // Target Word Box
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate800 : Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.indigo500.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ORIGINAL WORD',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.indigo500,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                targetWord.toUpperCase(),
                                key: const Key('speak_synonym_learn_target_word'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.slate100
                                      : AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Synonym Bridge Icon
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sync_alt_rounded,
                            color: AppColors.amber500,
                            size: 20.sp,
                          ),
                        ),
                      ),

                      // Synonym Word Box
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.emerald500.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4.w,
                                children: [
                                  Text(
                                    'SYNONYM',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: AppColors.emerald500,
                                    ),
                                  ),
                                  GestureDetector(
                                    key: const Key(
                                      'speak_synonym_learn_audio_btn',
                                    ),
                                    onTap: () => _playAudio(synonymWord),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: AppColors.emerald500,
                                      size: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                synonymWord.toUpperCase(),
                                key: const Key('speak_synonym_learn_synonym_word'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald500,
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
            ),
            SizedBox(height: 14.h),

            // Context Sentence Card
            if (contextSentence.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark
                        ? AppColors.slate800
                        : AppColors.indigo500.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'SPOKEN USAGE CONTEXT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.indigo500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          key: const Key(
                            'speak_synonym_learn_sentence_audio_btn',
                          ),
                          onTap: () => _playAudio(contextSentence),
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
                      '"$contextSentence"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Alternative Synonyms Chips
            if (alternativeSynonyms.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark
                        ? AppColors.slate800
                        : AppColors.indigo500.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.amber500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'NATURAL VARIATIONS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: alternativeSynonyms.map((syn) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800
                                : AppColors.indigo50.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.indigo500.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            syn,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Native Insight / Nuance Breakdown
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
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Memory Hook / Hint
            if (hint.isNotEmpty) ...[
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
                      Icons.psychology_rounded,
                      color: AppColors.emerald500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEMORY CLUE',
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
            ],
          ],
        ),
      ),
    );
  }
}
