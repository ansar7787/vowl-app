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

/// Interactive Learn Phase screen for Speak Missing Word ("Context & Articulation Discovery").
///
/// Teaches learners to recognize context clues, deduce the missing lexical item,
/// and practice oral articulation with accurate pronunciation and connected speech.
class SpeakMissingWordLearnScreen extends StatefulWidget {
  final int level;

  const SpeakMissingWordLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeakMissingWordLearnScreen> createState() =>
      _SpeakMissingWordLearnScreenState();
}

class _SpeakMissingWordLearnScreenState
    extends State<SpeakMissingWordLearnScreen> {
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
        'assets/curriculum/speaking/speakMissingWord_learn_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SPEAKMISSINGWORD_LEARN_FALLBACK_1',
          'instruction':
              'Study the context clue, discover the missing word, and practice oral articulation.',
          'textWithBlank':
              'I left my ___ on the kitchen table, so I couldn\'t lock the door when I went out.',
          'missingWord': 'keys',
          'completeSentence':
              'I left my keys on the kitchen table, so I couldn\'t lock the door when I went out.',
          'contextClue':
              '\'Lock the door\' points to the thing that opens and closes it.',
          'hint':
              'Small metal things on a ring that you carry in your pocket or bag.',
          'explanation':
              'Keys are usually plural because most people carry a set: \'my keys\', \'car keys\', \'house keys\'. Say \'a key\' only for one single key.',
          'phoneticGuide':
              'Articulate \'keys\' /kiːz/ clearly with a long vowel /iː/ and gentle, vibrating /z/ buzz at the end.',
          'articulationTip':
              'Connect \'keys\' smoothly with the preceding word \'my\' without a glottal stop.',
        },
      ];

  void _playAudio(String text, {double speed = 0.5}) {
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: speed);
      }
    } catch (_) {}
  }

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'speakMissingWord',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=speakMissingWord&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final textWithBlank = card['textWithBlank'] as String? ?? '';
    final missingWord = card['missingWord'] as String? ?? '';
    final completeSentence = card['completeSentence'] as String? ?? '';
    final contextClue = card['contextClue'] as String? ?? '';
    final hint = card['hint'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final phoneticGuide = card['phoneticGuide'] as String? ?? '';
    final articulationTip = card['articulationTip'] as String? ?? '';

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Context & Articulation Discovery',
      gameType: 'speakMissingWord',
      level: widget.level,
      actionLabel: isLast ? 'Start Guided Practice' : 'Next Word Card',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header & Tag
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'WORD DISCOVERY ${_cardIndex + 1} OF ${_cards.length}',
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Context & Oral Production',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Card 1: Sentence Context & Missing Word Revelation
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SITUATION WITH MISSING TARGET WORD',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    textWithBlank,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Missing Word Reveal Highlight Pill
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TARGET SPOKEN WORD',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emerald500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                missingWord.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.emerald500,
                            size: 24.sp,
                          ),
                          onPressed: () =>
                              _playAudio(missingWord, speed: 0.35),
                          tooltip: 'Listen to target word',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Complete Sentence Readout & Audio Buttons
                  Text(
                    'Full sentence in natural spoken English:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    completeSentence,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // TTS Playback Triggers
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 8.h,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo500,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () =>
                            _playAudio(completeSentence, speed: 0.45),
                        icon: Icon(Icons.volume_up_rounded, size: 16.sp),
                        label: Text(
                          'Listen Full Sentence',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.slate200
                              : AppColors.slate800,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.slate700
                                : AppColors.slate300,
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () =>
                            _playAudio(missingWord, speed: 0.35),
                        icon: Icon(Icons.slow_motion_video_rounded,
                            size: 16.sp),
                        label: Text(
                          'Slow Pronunciation',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Card 2: Context Clue & Semantic Explanation
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
                        Icons.lightbulb_rounded,
                        color: AppColors.amber500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'CONTEXT CLUE & USAGE INSIGHT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (contextClue.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      'Context Clue in Sentence:',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      contextClue,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      'Why this word fits:',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (hint.isNotEmpty && hint != contextClue) ...[
                    SizedBox(height: 10.h),
                    Text(
                      'Memory Anchor:',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      hint,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Card 3: Oral Articulation & Pronunciation Tips
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
                        Icons.mic_external_on_rounded,
                        color: AppColors.blue500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ORAL ARTICULATION & DELIVERY',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    phoneticGuide,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  if (articulationTip.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.blue500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.blue500.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.blue500,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              articulationTip,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700,
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
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
