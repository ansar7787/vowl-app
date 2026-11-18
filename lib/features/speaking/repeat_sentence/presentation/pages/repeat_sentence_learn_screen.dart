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

/// Interactive Learn Phase screen for Repeat Sentence ("Sentence Shadowing & Pronunciation Guide").
///
/// Demonstrates the stress-timed metric cadence of English:
/// Content Word Tonic Stress → Connected Phonetic Liaison → Vowel Reduction in Function Particles.
class RepeatSentenceLearnScreen extends StatefulWidget {
  final int level;

  const RepeatSentenceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<RepeatSentenceLearnScreen> createState() =>
      _RepeatSentenceLearnScreenState();
}

class _RepeatSentenceLearnScreenState extends State<RepeatSentenceLearnScreen> {
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
        'assets/curriculum/speaking/repeatSentence_learn_${startLevel}_$endLevel.json';

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
          'id': 'SPK_REPEATSENTENCE_LEARN_FALLBACK_1',
          'instruction':
              'Listen closely and absorb the rhythm, stress patterns, and connected speech.',
          'targetSentence': 'I wake up at seven.',
          'rhythmCadence': 'i **WAKE** **UP** at **SEVEN**',
          'phoneticAnchor':
              'Link the /k/ of \'wake\' into \'up\' (/weɪkʌp/). \'Seven\' /ˈsevən/ is stressed on its first syllable.',
          'connectedLinkingTip': 'Glide \'wake up\' together: wa-kup.',
          'prosodyExplanation':
              '\'Wake up\' is the phrasal verb for ending sleep, and \'at\' goes with clock times. Together they open most routine descriptions.',
          'fluencyHeuristic':
              'Native spoken rhythm is stress-timed: intervals between stressed beats remain steady, accelerating short function words in between.',
        },
      ];

  void _playAudio(String text, {double speed = 0.4}) {
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
        gameType: 'repeatSentence',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=repeatSentence&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final targetSentence = card['targetSentence'] as String? ?? '';
    final instruction = card['instruction'] as String? ?? '';
    final rhythmCadence = card['rhythmCadence'] as String? ?? '';
    final phoneticAnchor = card['phoneticAnchor'] as String? ?? '';
    final connectedLinkingTip = card['connectedLinkingTip'] as String? ?? '';
    final prosodyExplanation = card['prosodyExplanation'] as String? ?? '';
    final fluencyHeuristic = card['fluencyHeuristic'] as String? ?? '';

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Sentence Shadowing & Pronunciation',
      gameType: 'repeatSentence',
      level: widget.level,
      actionLabel: isLast ? 'Start Guided Practice' : 'Next Sentence Card',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pacing & Strategy Pill
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
                    'SHADOWING CARD ${_cardIndex + 1} OF ${_cards.length}',
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
                    'Stress-Timing & Liaison',
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

            // Target Sentence & Audio Audition Card
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
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'TARGET SENTENCE TO SHADOW',
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
                    targetSentence,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // TTS Playback Buttons
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 8.h,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _playAudio(targetSentence, speed: 0.4),
                        icon: Icon(Icons.volume_up_rounded, size: 18.sp),
                        label: Text(
                          'Listen Native',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo500,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _playAudio(targetSentence, speed: 0.25),
                        icon: Icon(Icons.slow_motion_video_rounded, size: 18.sp),
                        label: Text(
                          'Slow (0.6x)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
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
                      ),
                    ],
                  ),
                  if (instruction.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Metric Stress & Rhythmic Cadence Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
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
                          'STRESS & RHYTHMIC CADENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    rhythmCadence,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Uppercase bold words receive heavy tonic beats. Lowercase words compress into quick background transitions.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Phonetic Anchor & Connected Speech Guidance
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: AppColors.emerald500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONNECTED SPEECH & LIAISON',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              connectedLinkingTip,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.slate100
                                    : AppColors.slate800,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (phoneticAnchor.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Divider(
                      height: 1,
                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: AppColors.amber500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PHONETIC PLACEMENT GUIDE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                phoneticAnchor,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5.sp,
                                  color: isDark
                                      ? AppColors.slate300
                                      : AppColors.slate700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Fluency Heuristic & Prosodic Explanation Card
            if (fluencyHeuristic.isNotEmpty || prosodyExplanation.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.indigo500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROSODIC HEURISTIC',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (fluencyHeuristic.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              fluencyHeuristic,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                color: isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (prosodyExplanation.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              prosodyExplanation,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
