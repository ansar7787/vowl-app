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

/// Interactive Learn Phase screen for Audio Sentence Order ("Audio Transition Anchors").
///
/// Instructs learners on decoding speech rhythm, identifying acoustic pause markers,
/// and mapping spoken cadence into correct syntactic word sequences.
class AudioSentenceOrderLearnScreen extends StatefulWidget {
  final int level;

  const AudioSentenceOrderLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<AudioSentenceOrderLearnScreen> createState() =>
      _AudioSentenceOrderLearnScreenState();
}

class _AudioSentenceOrderLearnScreenState
    extends State<AudioSentenceOrderLearnScreen> {
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
        'assets/curriculum/listening/audioSentenceOrder_learn_${startLevel}_$endLevel.json';

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
          'id': 'LIS_AUDIOSENTENCEORDER_LEARN_FALLBACK_1',
          'textToSpeak': 'I have a car.',
          'correctSentence': 'I have a car',
          'orderedTokens': ['I', 'have', 'a', 'car'],
          'cadenceAnchor':
              'Listen for the rhythmic pulse: natural English links content chunks smoothly with slight pauses at clause boundaries.',
          'intonationPattern':
              'Falling terminal pitch confirms completion. The final token carries descending intonation.',
          'explanation':
              'Subject (I) comes first, then the verb "have", then the object (a car). This is the most basic English word order: who, then what they do, then what they act on.',
          'hint':
              'Listen for the small word right after "I" — it changes the whole sentence.',
          'instruction':
              'Listen to the spoken cadence and observe how word chunks anchor the sentence flow.',
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
        gameType: 'audioSentenceOrder',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=listening&gameType=audioSentenceOrder&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard = _cards[_cardIndex];
    final textToSpeak = currentCard['textToSpeak'] as String? ?? '';
    final correctSentence = currentCard['correctSentence'] as String? ?? '';
    final orderedTokens =
        (currentCard['orderedTokens'] as List<dynamic>? ?? []).cast<String>();
    final cadenceAnchor = currentCard['cadenceAnchor'] as String? ?? '';
    final intonationPattern = currentCard['intonationPattern'] as String? ?? '';
    final explanation = currentCard['explanation'] as String? ?? '';
    final hint = currentCard['hint'] as String? ?? '';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Cadence (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Audio Transition Anchors',
      gameType: 'audioSentenceOrder',
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
                    'CADENCE MODEL ${_cardIndex + 1} OF ${_cards.length}',
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

            // Audio Player & Full Spoken Sentence Card
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
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SPOKEN SENTENCE AUDIO',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        key: const Key('audio_sentence_order_learn_audio_btn'),
                        onPressed: () => _playAudio(textToSpeak),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo500,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        label: Text(
                          'Listen',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '"$textToSpeak"',
                      key: const Key('audio_sentence_order_learn_transcript'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark ? AppColors.slate100 : AppColors.slate900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Chronological Word Sequence Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        color: AppColors.emerald500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SYNTACTIC & AUDITORY SEQUENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.emerald500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    key: const Key('audio_sentence_order_learn_tokens_wrap'),
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: List.generate(orderedTokens.length, (idx) {
                      final token = orderedTokens[idx];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18.r,
                              height: 18.r,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.emerald500,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              token,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Full Sequence: "$correctSentence"',
                    key: const Key('audio_sentence_order_learn_sequence_text'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Cadence Anchor & Intonation Pattern Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.slate50,
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
                        Icons.waves_rounded,
                        color: AppColors.indigo500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'CADENCE & INTONATION ANCHORS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    cadenceAnchor,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.45,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                  if (intonationPattern.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.trending_down_rounded,
                            color: AppColors.amber500,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              intonationPattern,
                              style: TextStyle(
                                fontSize: 12.sp,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.amber100
                                    : AppColors.slate800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Syntactic Explanation
            if (explanation.isNotEmpty) ...[
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
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.amber500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'GRAMMATICAL FLOW EXPLANATION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.amber500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                    if (hint.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Hint: $hint',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate500,
                        ),
                      ),
                    ],
                  ],
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
