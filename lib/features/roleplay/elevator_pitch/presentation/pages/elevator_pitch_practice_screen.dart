import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Elevator Pitch ("Pitch Calibration Gym").
///
/// Drills learners on identifying crisp, benefit-first openings, eliminating buzzwords,
/// and structuring compelling 30-second value propositions.
class ElevatorPitchPracticeScreen extends StatefulWidget {
  final int level;

  const ElevatorPitchPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ElevatorPitchPracticeScreen> createState() =>
      _ElevatorPitchPracticeScreenState();
}

class _ElevatorPitchPracticeScreenState
    extends State<ElevatorPitchPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
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
        'assets/curriculum/roleplay/elevatorPitch_practice_${startLevel}_$endLevel.json';

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
      // Fallback quests maintain continuity during testing or missing assets.
    }
  }

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}
  }

  void _onCheck() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final correctIndex = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _hasChecked = true;
    });

    try {
      if (isCorrect) {
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCorrect();
        }
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }
      } else {
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playWrong();
        }
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().error();
        }
      }
    } catch (_) {}
  }

  void _onContinue() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
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
      gameType: 'elevatorPitch',
      level: widget.level,
      phase: 'practice',
    );

    try {
      context.pushReplacement(
        '/game?category=roleplay&gameType=elevatorPitch&level=${widget.level}&phase=mastery',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'ep_practice_l1_q1',
      'level': 1,
      'pitchContext': 'VENTURE CAPITAL & SEED FUNDING',
      'scenarioScene':
          'A colleague rambles for two minutes about her new mentoring program before anyone understands what it does. Pick the pitch definition that captures the true goal.',
      'targetAudience': 'Venture Partner / Managing Director',
      'question':
          'Which pitch articulates the strongest hook and clearest value proposition?',
      'options': [
        'It tells a listener, in the time it takes to cross a lobby, what you offer and why it matters to them.',
        'We leverage next-generation synergistic AI paradigms to optimize omnichannel holistic bandwidth across decentralized stakeholder touchpoints.',
        'So um, basically, we kind of built this thing that maybe people might like if they have ten or fifteen minutes to sit through our 50-slide deck.',
      ],
      'correctAnswerIndex': 0,
      'correctAnswer':
          'It tells a listener, in the time it takes to cross a lobby, what you offer and why it matters to them.',
      'explanation':
          'A powerful pitch lands clarity and listener benefit in seconds without buzzwords or hesitant disclaimers.',
      'hookPowerScore': 0.90,
      'timeLimit': 30,
    },
    {
      'id': 'ep_practice_l1_q2',
      'level': 1,
      'pitchContext': 'COMMUNITY & LOCAL INITIATIVE',
      'scenarioScene':
          'You introduce your weekend neighborhood tool-lending library to someone waiting for the same bus with fifteen seconds to spare.',
      'targetAudience': 'Local Resident / Commuter',
      'question':
          'Which pitch articulates the strongest hook and clearest value proposition?',
      'options': [
        'By disintermediating fragmented cross-functional silos, our turnkey platform unlocks exponential frictionless throughput.',
        'We lend tools instead of everyone buying their own - drill on Tuesday, ladder on Friday, no clutter in anyone\'s garage.',
        'I know you are super busy and probably do not care, but my co-founder and I have been coding for three years and really hope someone tests it out.',
      ],
      'correctAnswerIndex': 1,
      'correctAnswer':
          'We lend tools instead of everyone buying their own - drill on Tuesday, ladder on Friday, no clutter in anyone\'s garage.',
      'explanation':
          'Concrete examples like drills and ladders convey the personal benefit immediately, avoiding both corporate jargon and timid phrasing.',
      'hookPowerScore': 0.90,
      'timeLimit': 30,
    },
    {
      'id': 'ep_practice_l1_q3',
      'level': 1,
      'pitchContext': 'AUDIENCE ADAPTATION & VALUE REALIGNMENT',
      'scenarioScene':
          'The same bus-stop stranger mentions they just moved in and don\'t know anyone yet. Pivot the tool-library pitch to address that.',
      'targetAudience': 'New Resident / Building Neighbor',
      'question':
          'Which pitch articulates the strongest hook and clearest value proposition?',
      'options': [
        'Well, it does a lot of different stuff, like twelve different features, and we have not really decided on the main one yet, but it is pretty cool.',
        'Our core competency resides in orchestrating scalable hyper-converged architectures that dynamically monetize bleeding-edge cloud native vectors.',
        'It\'s how half the building has met each other - borrowing a ladder turns into knowing your neighbors.',
      ],
      'correctAnswerIndex': 2,
      'correctAnswer':
          'It\'s how half the building has met each other - borrowing a ladder turns into knowing your neighbors.',
      'explanation':
          'Leading with social connection directly answers the newcomer\'s stated desire for community.',
      'hookPowerScore': 0.90,
      'timeLimit': 30,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final pitchContext =
        current['pitchContext'] as String? ?? 'ELEVATOR PITCH SCENARIO';
    final scenarioScene = current['scenarioScene'] as String? ?? '';
    final targetAudience =
        current['targetAudience'] as String? ?? 'Stakeholder';
    final question = current['question'] as String? ??
        'Which pitch articulates the strongest hook and clearest value proposition?';
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final correctAnswer = current['correctAnswer'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIndex;

    return PracticePhaseScaffold(
      title: 'Elevator Pitch Practice',
      gameType: 'elevatorPitch',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _markCompleteAndNavigate,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scenario Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
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
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.rocket_launch_rounded,
                              size: 14.sp,
                              color: AppColors.indigo400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'PITCH CHALLENGE ${_exerciseIndex + 1}/${_quests.length}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.indigo400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 150.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          targetAudience.toUpperCase(),
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
                  SizedBox(height: 10.h),
                  Text(
                    pitchContext,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    scenarioScene,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.blue300,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Question prompt
            Text(
              question,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 10.h),

            // Options List
            ...List.generate(options.length, (i) {
              final isSelected = _selectedOptionIndex == i;
              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;

              if (_hasChecked) {
                if (i == correctIndex) {
                  borderColor = AppColors.emerald400;
                  bgColor = AppColors.emerald400.withValues(alpha: 0.15);
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.15);
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo400;
                bgColor = AppColors.indigo500.withValues(alpha: 0.15);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: InkWell(
                  key: Key('practice_option_$i'),
                  onTap: () => _onOptionSelected(i),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_hasChecked && i == correctIndex)
                            ? 2
                            : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22.r,
                          height: 22.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (_hasChecked
                                    ? (i == correctIndex
                                        ? AppColors.emerald400
                                        : AppColors.rose500)
                                    : AppColors.indigo400)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppColors.slate700,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  _hasChecked
                                      ? (i == correctIndex
                                          ? Icons.check
                                          : Icons.close)
                                      : Icons.circle,
                                  size: 14.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            options[i],
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            SizedBox(height: 10.h),

            // Check Answer / Feedback Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  disabledBackgroundColor:
                      AppColors.indigo500.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'CALIBRATE PITCH',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            // Explanation & Continue Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.emerald400.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.emerald400.withValues(alpha: 0.5)
                        : AppColors.rose500.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: isCorrect
                              ? AppColors.emerald400
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'PITCH LOCKED IN!'
                                : 'PITCH CALIBRATION NEEDED',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? AppColors.emerald400
                                  : AppColors.rose500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('practice_audio_button'),
                          onPressed: () => _playAudio(correctAnswer),
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: isCorrect
                                ? AppColors.emerald400
                                : AppColors.cyan400,
                            size: 20.sp,
                          ),
                          tooltip: 'Listen to optimal pitch',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.all(4.r),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.blue300,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex == _quests.length - 1
                      ? 'COMMENCE MASTERY TEST'
                      : 'NEXT PITCH CHALLENGE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
