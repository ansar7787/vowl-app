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

/// Interactive Learn Phase screen for Pronunciation Focus ("Phonetic Articulation Guide").
///
/// Instructs learners on articulatory positioning, vocal cord voicing,
/// airflow dynamics, and connected sentence speech for targeted English phonemes.
class PronunciationFocusLearnScreen extends StatefulWidget {
  final int level;

  const PronunciationFocusLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PronunciationFocusLearnScreen> createState() =>
      _PronunciationFocusLearnScreenState();
}

class _PronunciationFocusLearnScreenState
    extends State<PronunciationFocusLearnScreen> {
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
        'assets/curriculum/speaking/pronunciationFocus_learn_${startLevel}_$endLevel.json';

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
          'id': 'SPK_PRONUNCIATIONFOCUS_LEARN_FALLBACK_1',
          'instruction':
              'Study the target sound, articulatory positioning, and acoustic distinction.',
          'targetPhoneme': '[p]',
          'textToSpeak': 'Please put the pan on the stove.',
          'phoneticHint':
              'At the start of a stressed word, English [p] is aspirated, roughly [pʰ]: the burst is followed by a tiny breath.',
          'articulatoryPlacement':
              'Close both lips, let pressure build behind them, then open with a quick burst. Your voice stays off until the vowel begins.',
          'hint':
              'Hold a hand near your mouth: "please", "put" and "pan" should each push out a small puff of air.',
          'commonMistakes': [
            'Voicing it so "pan" sounds like "ban"',
            'Releasing no air, which makes the [p] sound like a [b] to English ears',
          ],
          'phoneticGuide':
              'Articulate "[p]" cleanly with correct vocal fold resonance and tongue posture.',
          'connectedSpeechTip':
              'Keep the sound natural and fluid when embedded within complete sentences.',
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
        gameType: 'pronunciationFocus',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/game?category=speaking&gameType=pronunciationFocus&level=${widget.level}&phase=practice',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_cardIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _cardIndex == _cards.length - 1;

    final targetPhoneme = card['targetPhoneme'] as String? ?? '[sound]';
    final textToSpeak = card['textToSpeak'] as String? ?? '';
    final phoneticHint = card['phoneticHint'] as String? ?? '';
    final articulatoryPlacement =
        card['articulatoryPlacement'] as String? ?? card['explanation'] as String? ?? '';
    final hint = card['hint'] as String? ?? '';
    final commonMistakes = (card['commonMistakes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final phoneticGuide = card['phoneticGuide'] as String? ?? '';
    final connectedSpeechTip = card['connectedSpeechTip'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Pronunciation Guide',
      gameType: 'pronunciationFocus',
      level: widget.level,
      actionLabel: isLast ? 'Start Guided Practice' : 'Next Phonetic Card',
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
                    'PHONETIC FOCUS ${_cardIndex + 1} OF ${_cards.length}',
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
                    'Acoustic & Articulation',
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

            // Card 1: Target Phoneme Hero Crucible
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
                        Icons.graphic_eq_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'TARGET SOUND & SENTENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded),
                        color: AppColors.indigo500,
                        iconSize: 22.sp,
                        tooltip: 'Play spoken sentence',
                        onPressed: () => _playAudio(textToSpeak),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Phoneme Crucible Center Display
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.indigo500.withValues(alpha: 0.2),
                            AppColors.blue500.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            targetPhoneme,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.indigo400,
                              letterSpacing: 2.0,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'TARGET PHONEME',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Spoken Sentence
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate950 : AppColors.slate50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRACTICE SENTENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          textToSpeak,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.slate100 : AppColors.slate900,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Card 2: Articulatory Mechanics & Mouth Placement
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
                        Icons.record_voice_over_rounded,
                        color: AppColors.emerald500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ARTICULATORY MECHANICS & PLACEMENT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    articulatoryPlacement,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                      height: 1.5,
                    ),
                  ),
                  if (phoneticHint.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 16.sp,
                            color: AppColors.emerald500,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              phoneticHint,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.emerald400
                                    : AppColors.emerald600,
                                height: 1.4,
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

            // Card 3: Common Pitfalls & Practical Tips
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
                        Icons.warning_amber_rounded,
                        color: AppColors.amber500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'COMMON PRONUNCIATION PITFALLS',
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
                  if (commonMistakes.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    ...commonMistakes.map(
                      (m) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.amber500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  color: isDark
                                      ? AppColors.slate300
                                      : AppColors.slate700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              hint,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.amber500
                                    : AppColors.amber600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (phoneticGuide.isNotEmpty || connectedSpeechTip.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 16.sp,
                          color: AppColors.blue500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '$phoneticGuide $connectedSpeechTip',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.4,
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
