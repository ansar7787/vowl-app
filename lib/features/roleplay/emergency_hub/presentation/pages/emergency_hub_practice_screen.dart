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

/// Interactive Practice Phase screen for Emergency Hub ("Crisis Response Gym").
///
/// Drills learners on identifying life-saving, timely dispatch decisions
/// while rejecting hazardous panic or dangerous delays under pressure.
class EmergencyHubPracticeScreen extends StatefulWidget {
  final int level;

  const EmergencyHubPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<EmergencyHubPracticeScreen> createState() =>
      _EmergencyHubPracticeScreenState();
}

class _EmergencyHubPracticeScreenState
    extends State<EmergencyHubPracticeScreen> {
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
        'assets/curriculum/roleplay/emergencyHub_practice_${startLevel}_$endLevel.json';

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
      gameType: 'emergencyHub',
      level: widget.level,
      phase: 'practice',
    );

    try {
      context.pushReplacement(
        '/game?category=roleplay&gameType=emergencyHub&level=${widget.level}&phase=mastery',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'eh_practice_l1_q1',
      'level': 1,
      'emergencyCategory': 'DOMESTIC NUISANCE & TRIAGE',
      'crisisScene':
          'A neighbor\'s dog has been barking loudly for the past twenty minutes. Input code!',
      'urgencyLevel': 1,
      'question':
          'Select the correct emergency dispatch action for this situation:',
      'options': [
        'THIS IS NOT AN EMERGENCY',
        'Wait until tomorrow morning to see if the situation resolves itself naturally.',
        'Rush blindly into the active danger zone without any safety gear or training.',
      ],
      'correctAnswerIndex': 0,
      'correctAnswer': 'THIS IS NOT AN EMERGENCY',
      'explanation':
          'Noise alone isn\'t a danger to life or safety, so it doesn\'t need police, fire, or medical help.',
      'urgencyScore': 0.95,
      'timeLimit': 30,
    },
    {
      'id': 'eh_practice_l1_q2',
      'level': 1,
      'emergencyCategory': 'MEDICAL EMERGENCY & FIRST RESPONDER',
      'crisisScene':
          'A man is lying motionless on the sidewalk and does not respond when people call out to him. Input medical code!',
      'urgencyLevel': 4,
      'question':
          'Select the correct emergency dispatch action for this situation:',
      'options': [
        'Post on a neighborhood social forum to ask bystanders what they think you should do.',
        'CALL FOR AN AMBULANCE',
        'Attempt invasive emergency surgery on the spot using unsterilized kitchen utensils.',
      ],
      'correctAnswerIndex': 1,
      'correctAnswer': 'CALL FOR AN AMBULANCE',
      'explanation':
          'An unresponsive person needs paramedics right away, since they can check breathing and start treatment on the spot.',
      'urgencyScore': 0.95,
      'timeLimit': 30,
    },
    {
      'id': 'eh_practice_l1_q3',
      'level': 1,
      'emergencyCategory': 'FIRE & STRUCTURAL HAZARD',
      'crisisScene':
          'Flames are rising from a trash can outside a shop, and the plastic bin is starting to melt. Input fire code!',
      'urgencyLevel': 3,
      'question':
          'Select the correct emergency dispatch action for this situation:',
      'options': [
        'Ignore the situation completely since it is taking place outside your own property.',
        'Scream loudly in the street while running in circles to incite mass panic.',
        'CALL THE FIRE BRIGADE',
      ],
      'correctAnswerIndex': 2,
      'correctAnswer': 'CALL THE FIRE BRIGADE',
      'explanation':
          'Even a small outdoor fire can spread to the shop front, so trained firefighters should handle it.',
      'urgencyScore': 0.95,
      'timeLimit': 30,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final emergencyCategory =
        current['emergencyCategory'] as String? ?? 'CRISIS SCENARIO';
    final crisisScene = current['crisisScene'] as String? ?? '';
    final urgencyLevel = current['urgencyLevel'] as int? ?? 3;
    final question = current['question'] as String? ??
        'Select the correct emergency dispatch action for this situation:';
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final correctAnswer = current['correctAnswer'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIndex;

    return PracticePhaseScaffold(
      title: 'Emergency Hub Practice',
      gameType: 'emergencyHub',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _markCompleteAndNavigate,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crisis Scene Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.35),
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
                          color: AppColors.rose500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13.sp,
                              color: AppColors.rose500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'URGENCY: $urgencyLevel/5',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.rose500,
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
                          emergencyCategory.toUpperCase(),
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
                    crisisScene,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
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

            // Check Answer / Evaluate Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose500,
                  disabledBackgroundColor:
                      AppColors.rose500.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'DISPATCH ACTION',
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
                              : Icons.warning_rounded,
                          color: isCorrect
                              ? AppColors.emerald400
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'TRIAGE PROTOCOL VERIFIED!'
                                : 'CRITICAL DISPATCH ERROR',
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
                          tooltip: 'Listen to dispatch order',
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
                      : 'NEXT CRISIS SCENARIO',
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
