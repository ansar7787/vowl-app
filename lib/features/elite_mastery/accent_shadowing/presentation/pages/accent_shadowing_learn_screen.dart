import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Accent Shadowing ("Prosody & Cadence Vault").
///
/// Instructs elite learners on native suprasegmental prosody, nuclear stress peaks,
/// function-word reductions, and breath group synchrony before real-time shadowing.
class AccentShadowingLearnScreen extends StatefulWidget {
  final int level;

  const AccentShadowingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<AccentShadowingLearnScreen> createState() =>
      _AccentShadowingLearnScreenState();
}

class _AccentShadowingLearnScreenState
    extends State<AccentShadowingLearnScreen> {
  int _currentIndex = 0;
  late List<Map<String, dynamic>> _quests;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/elite_mastery/accentShadowing_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (levelQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Fallback maintains continuity during testing.
    }
  }

  void _onNext() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _markCompleteAndNavigate();
    }
  }

  void _markCompleteAndNavigate() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
    } catch (_) {}

    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'accentShadowing',
      level: widget.level,
      phase: 'learn',
    );

    context.pushReplacement(
      '/practice?category=elite_mastery&gameType=accentShadowing&level=${widget.level}',
    );
  }

  void _playAudio(String text) {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final current =
        _quests.isNotEmpty ? _quests[_currentIndex] : _fallbackQuests.first;

    final targetPhrase = current['targetPhrase'] as String? ??
        current['phrase'] as String? ??
        current['word'] as String? ??
        'Target Phrase';
    final ipa = current['ipa'] as String? ?? '/.../';
    final flowRule = current['flowRule'] as String? ??
        'Phrase Shadowing: follow native cadence and pitch peak.';
    final speedLevel = (current['speedLevel'] as num? ?? 1.0).toDouble();
    final instruction = current['instruction'] as String? ??
        'Study the native prosodic cadence, nuclear stress peak, and speech reduction rules.';
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final cadenceGuide = current['cadenceGuide'] as String? ??
        'Focus on rhythm: content words are elongated while grammatical function words undergo vowel reduction to schwa /ə/.';
    final authorInsight = current['authorInsight'] as String? ??
        'Shadowing at native velocity trains the articulators to automate motor planning for connected speech and reductions.';

    return LearnPhaseScaffold(
      title: 'Accent Shadowing',
      gameType: 'accentShadowing',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT CADENCE'
          : 'START SHADOWING GYM',
      onComplete: _onNext,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'PROSODY VAULT: ${_currentIndex + 1} OF ${_quests.length}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${speedLevel}x VELOCITY',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Target Phrase Hero Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.slate900,
                    AppColors.indigo500.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 13.sp,
                              color: AppColors.amber400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'NATIVE CADENCE TARGET',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 180.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          ipa,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate400,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '"$targetPhrase"',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 22.sp,
                          color: AppColors.amber400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _playAudio(targetPhrase),
                        tooltip: 'Listen to native speech cadence',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Prosodic Flow Rule Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.indigo400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.waves_rounded,
                        size: 15.sp,
                        color: AppColors.indigo400,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'PROSODIC CONTOUR & FLOW RULE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo400,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    flowRule,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Nuclear Stress & Pitch Peak Analysis Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        size: 15.sp,
                        color: AppColors.cyan400,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'NUCLEAR STRESS & PITCH PEAK ANALYSIS',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan400,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Cadence & Reduction Guide Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 15.sp,
                        color: AppColors.emerald500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'SYNCHRONIZATION & REDUCTION GUIDE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald500,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    cadenceGuide,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            if (hint.isNotEmpty) ...[
              SizedBox(height: 14.h),
              // Auditory Anchor Card
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.slate700,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      size: 16.sp,
                      color: AppColors.slate400,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.slate300,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 14.h),

            // Mental Model Insight Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 18.sp,
                    color: AppColors.amber400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MENTAL MODEL INSIGHT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          authorInsight,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.slate300,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Advance Button
            ElevatedButton(
              key: const Key('learn_continue_button'),
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _quests.length - 1
                    ? 'NEXT CADENCE'
                    : 'START SHADOWING GYM',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'ELT_ACCENTSHADOWING_L1_LEARN_Q1',
      'targetPhrase': 'See you tomorrow.',
      'phrase': 'See you tomorrow.',
      'ipa': '/siː jə təˈmɒrəʊ/',
      'flowRule':
          'Phrase Shadowing: follow the speaker\'s pitch peak instead of giving every word equal strength.',
      'speedLevel': 0.75,
      'instruction':
          'Study the native prosodic cadence, nuclear stress peak, and speech reduction rules.',
      'explanation':
          'In a neutral goodbye the last content word carries the peak, while \'you\' shrinks to a quick /jə/.',
      'hint': 'Notice where the pitch peaks before it drops away.',
      'cadenceGuide':
          'Focus on rhythm: content words are elongated while grammatical function words undergo vowel reduction to schwa /ə/.',
      'authorInsight':
          'Shadowing at native velocity trains the articulators to automate motor planning for connected speech and reductions.'
    },
    {
      'id': 'ELT_ACCENTSHADOWING_L1_LEARN_Q2',
      'targetPhrase': 'Could I have some water?',
      'phrase': 'Could I have some water?',
      'ipa': '/kʊd aɪ hæv səm ˈwɔːtə/',
      'flowRule':
          'Natural Flow: small grammar words shrink so the meaningful word stands out.',
      'speedLevel': 0.75,
      'instruction':
          'Study the native prosodic cadence, nuclear stress peak, and speech reduction rules.',
      'explanation':
          '\'Could I\' and \'have some\' are quick function-word groups; the listener\'s attention lands on \'water\'.',
      'hint': 'Listen for the words that almost vanish.',
      'cadenceGuide':
          'Focus on rhythm: content words are elongated while grammatical function words undergo vowel reduction to schwa /ə/.',
      'authorInsight':
          'Shadowing at native velocity trains the articulators to automate motor planning for connected speech and reductions.'
    },
    {
      'id': 'ELT_ACCENTSHADOWING_L1_LEARN_Q3',
      'targetPhrase': 'Nice to meet you.',
      'phrase': 'Nice to meet you.',
      'ipa': '/naɪs tə ˈmiːt juː/',
      'flowRule':
          'Nuclear Stress: pitch rises on the key content predicate then falls cleanly.',
      'speedLevel': 0.75,
      'instruction':
          'Study the native prosodic cadence, nuclear stress peak, and speech reduction rules.',
      'explanation':
          'Peaks on \'meet\', then glides downward through \'you\'.',
      'hint': 'Listen to how the voice falls at the end.',
      'cadenceGuide':
          'Focus on rhythm: content words are elongated while grammatical function words undergo vowel reduction to schwa /ə/.',
      'authorInsight':
          'Shadowing at native velocity trains the articulators to automate motor planning for connected speech and reductions.'
    },
  ];
}
