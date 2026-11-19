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

/// Interactive Learn Phase screen for Emotion Recognition ("Vocal Tone & Prosody Decoder").
///
/// Instructs learners on identifying emotional states through pitch inflections,
/// speech tempo, vocal stress, and prosodic acoustic markers.
class EmotionRecognitionLearnScreen extends StatefulWidget {
  final int level;

  const EmotionRecognitionLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<EmotionRecognitionLearnScreen> createState() =>
      _EmotionRecognitionLearnScreenState();
}

class _EmotionRecognitionLearnScreenState
    extends State<EmotionRecognitionLearnScreen> {
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
        'assets/curriculum/listening/emotionRecognition_learn_${startLevel}_$endLevel.json';

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
          'id': 'LIS_EMOTIONRECOGNITION_LEARN_FALLBACK_1',
          'gameType': 'emotionRecognition',
          'level': widget.level,
          'concept': 'Vocal Tone & Prosody Decoder',
          'textToSpeak': 'Yes! We won! We actually won the game!',
          'targetEmotion': 'happy',
          'targetEmoji': '😊',
          'vocalClues':
              'High dynamic pitch range, quick rhythmic tempo, and upward intonation contours reflect happiness and excitement.',
          'explanation':
              'Cheering and repeating the good news shows joy about the win.',
          'hint': 'Listen to how the speaker reacts to the final result.',
          'rule':
              'Vocal prosody (pitch, tempo, loudness, and resonance) communicates emotions before verbal words are fully processed. Always listen to vocal energy and pitch contour.',
          'proTip':
              'Listen beyond the literal words. Pay attention to pitch peaks, exclamations, and cadence changes to decode authentic emotional intent.',
          'emotionScale': 3,
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

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'emotionRecognition',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=listening&gameType=emotionRecognition&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];
    final textToSpeak = card['textToSpeak'] as String? ?? '';
    final targetEmotion = card['targetEmotion'] as String? ?? 'Emotion';
    final targetEmoji = card['targetEmoji'] as String? ?? '🎭';
    final vocalClues = card['vocalClues'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final hint = card['hint'] as String? ?? '';
    final rule = card['rule'] as String? ?? '';
    final proTip = card['proTip'] as String? ?? '';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Emotion (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Prosody Decoder',
      gameType: 'emotionRecognition',
      level: widget.level,
      actionLabel: actionLabel,
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badges
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
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'MODULE ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(targetEmoji, style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        'LEVEL ${widget.level}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Hero Audio Player Card
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.teal500.withValues(alpha: 0.22),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.teal500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal500.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.teal500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.teal500,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SPOKEN EMOTIONAL DIALOGUE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Tap below to listen to the vocal expression',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Dialogue text quote
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate800
                          : AppColors.slate100.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      '"$textToSpeak"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Play Button
                  Center(
                    child: ElevatedButton.icon(
                      key: const Key('learn_play_audio_button'),
                      onPressed: () => _playAudio(textToSpeak),
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      label: Text(
                        'PLAY AUDIO DIALOGUE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal500,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.teal500.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Target Emotion & Prosody Analysis Card
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
                        Icons.psychology_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'TARGET EMOTION & ACOUSTIC CUES',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Emotion Identifier Pill
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          targetEmoji,
                          style: TextStyle(fontSize: 28.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IDENTIFIED EMOTIONAL STATE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.indigo500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                targetEmotion.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Vocal Prosody Breakdown
                  if (vocalClues.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: AppColors.amber500,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROSODIC ACOUSTIC MARKERS',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amber500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  vocalClues,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate900,
                                    height: 1.35,
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
            SizedBox(height: 14.h),

            // Linguistic Strategy & Decoding Rules Card
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
                        Icons.school_rounded,
                        color: AppColors.teal500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'EMOTION DECODING STRATEGY',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    rule,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color:
                            isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (proTip.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            color: AppColors.emerald500,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'PRO-TIP: $proTip',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: isDark
                              ? AppColors.slate500
                              : AppColors.slate400,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Hint: $hint',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
