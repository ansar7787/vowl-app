import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Accent Shadowing ("Prosody Gym").
///
/// Challenges learners to discriminate between native suprasegmental cadence,
/// nuclear prominence patterns, and synthetic/distorted speech contours before real-time vocal shadowing.
class AccentShadowingPracticeScreen extends StatefulWidget {
  final int level;

  const AccentShadowingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<AccentShadowingPracticeScreen> createState() =>
      _AccentShadowingPracticeScreenState();
}

class _AccentShadowingPracticeScreenState
    extends State<AccentShadowingPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;
  bool _isCorrect = false;

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
        'assets/curriculum/elite_mastery/accentShadowing_practice_${startLevel}_$endLevel.json';

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

  void _onSelectOption(int index) {
    if (_isAnswerChecked) return;
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
    } catch (_) {}
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheckAnswer() {
    if (_selectedOptionIndex == null || _isAnswerChecked) return;

    final current =
        _quests.isNotEmpty ? _quests[_exerciseIndex] : _fallbackQuests.first;
    final correctIndex = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    try {
      if (isCorrect) {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCorrect();
        }
      } else {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().error();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playWrong();
        }
      }
    } catch (_) {}

    setState(() {
      _isAnswerChecked = true;
      _isCorrect = isCorrect;
    });
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
        _isAnswerChecked = false;
        _isCorrect = false;
      });
    } else {
      _completePracticeAndNavigate();
    }
  }

  void _completePracticeAndNavigate() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'accentShadowing',
      level: widget.level,
      phase: 'practice',
    );

    context.pushReplacement(
      '/game?category=elite_mastery&gameType=accentShadowing&level=${widget.level}',
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
        _quests.isNotEmpty ? _quests[_exerciseIndex] : _fallbackQuests.first;

    final targetPhrase = current['targetPhrase'] as String? ??
        current['phrase'] as String? ??
        current['word'] as String? ??
        'Target Phrase';
    final ipa = current['ipa'] as String? ?? '/.../';
    final speedLevel = (current['speedLevel'] as num? ?? 1.0).toDouble();
    final instruction = current['instruction'] as String? ??
        'Listen to the native cadence and identify the nuclear stress and pitch contour.';
    final prompt = current['prompt'] as String? ??
        'Which prosodic description accurately characterizes this spoken delivery?';
    final options = (current['options'] as List<dynamic>? ?? [prompt])
        .cast<String>();
    final correctIndex = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';

    return PracticePhaseScaffold(
      title: 'Accent Shadowing Practice',
      gameType: 'accentShadowing',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _completePracticeAndNavigate,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header Card
            Container(
              padding: EdgeInsets.all(14.r),
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
                              Icons.hearing_rounded,
                              size: 13.sp,
                              color: AppColors.amber400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'PROSODY SPRINT',
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
                        constraints: BoxConstraints(maxWidth: 170.w),
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
                  SizedBox(height: 10.h),
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
                            fontSize: 16.sp,
                            color: Colors.white,
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('practice_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 22.sp,
                          color: AppColors.amber400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _playAudio(targetPhrase),
                        tooltip: 'Listen to native audio cadence',
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.indigo400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Options List
            for (int i = 0; i < options.length; i++) ...[
              Builder(
                builder: (context) {
                  final isSelected = _selectedOptionIndex == i;
                  Color borderColor = AppColors.slate700;
                  Color backgroundColor = AppColors.slate900;

                  if (_isAnswerChecked) {
                    if (i == correctIndex) {
                      borderColor = AppColors.emerald500;
                      backgroundColor =
                          AppColors.emerald500.withValues(alpha: 0.15);
                    } else if (isSelected) {
                      borderColor = AppColors.rose500;
                      backgroundColor =
                          AppColors.rose500.withValues(alpha: 0.15);
                    }
                  } else if (isSelected) {
                    borderColor = AppColors.indigo500;
                    backgroundColor =
                        AppColors.indigo500.withValues(alpha: 0.2);
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: InkWell(
                      key: Key('practice_option_$i'),
                      onTap: () => _onSelectOption(i),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ||
                                    (_isAnswerChecked && i == correctIndex)
                                ? 1.5
                                : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.indigo500
                                    : AppColors.slate800,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                options[i],
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            SizedBox(height: 12.h),

            // Check or Continue Button
            if (!_isAnswerChecked) ...[
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed:
                    _selectedOptionIndex != null ? _onCheckAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  disabledBackgroundColor: AppColors.slate800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'CHECK CADENCE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ] else ...[
              // Explanation Card
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color:
                        _isCorrect ? AppColors.emerald500 : AppColors.rose500,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 16.sp,
                                color: _isCorrect
                                    ? AppColors.emerald500
                                    : AppColors.rose500,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  _isCorrect
                                      ? 'PROSODIC CADENCE VERIFIED'
                                      : 'PROSODIC DISTORTION DETECTED',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect
                                        ? AppColors.emerald500
                                        : AppColors.rose500,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'NEXT EXERCISE'
                      : 'START MASTERY SHADOWING',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'ELT_ACCENTSHADOWING_L1_PRACTICE_Q1',
      'targetPhrase': 'See you tomorrow.',
      'phrase': 'See you tomorrow.',
      'ipa': '/siː jə təˈmɒrəʊ/',
      'prompt': 'Which prosodic description accurately characterizes this spoken delivery?',
      'options': [
        '\'tomorrow\' — its middle syllable is the loudest point',
        '\'see\' — the opening word leads the beat',
        '\'you\' — the person you\'re talking to gets the stress',
        'Every syllable receives identical pitch and duration without nuclear peak'
      ],
      'correctAnswerIndex': 0,
      'correctAnswer': '\'tomorrow\' — its middle syllable is the loudest point',
      'speedLevel': 0.75,
      'instruction': 'Listen to the native cadence and identify the nuclear stress and pitch contour.',
      'explanation': 'In a neutral goodbye the last content word carries the peak, while \'you\' shrinks to a quick /jə/.',
    },
    {
      'id': 'ELT_ACCENTSHADOWING_L1_PRACTICE_Q2',
      'targetPhrase': 'Could I have some water?',
      'phrase': 'Could I have some water?',
      'ipa': '/kʊd aɪ hæv səm ˈwɔːtə/',
      'prompt': 'Which prosodic description accurately characterizes this spoken delivery?',
      'options': [
        'Every word gets equal time, so \'water\' has no special beat',
        '\'have\' is the loudest word because it is the verb',
        '\'Could I\' and \'have some\' squeeze small, with \'water\' as the peak',
        'Pitch rises sharply on the opening word and flatlines completely'
      ],
      'correctAnswerIndex': 2,
      'correctAnswer': '\'Could I\' and \'have some\' squeeze small, with \'water\' as the peak',
      'speedLevel': 0.75,
      'instruction': 'Listen to the native cadence and identify the nuclear stress and pitch contour.',
      'explanation': '\'Could I\' and \'have some\' are quick function-word groups; the listener\'s attention lands on \'water\'.',
    },
    {
      'id': 'ELT_ACCENTSHADOWING_L1_PRACTICE_Q3',
      'targetPhrase': 'Nice to meet you.',
      'phrase': 'Nice to meet you.',
      'ipa': '/naɪs tə ˈmiːt juː/',
      'prompt': 'Which prosodic description accurately characterizes this spoken delivery?',
      'options': [
        'The voice jumps up on \'you\', like a yes/no question',
        'Peaks on \'meet\', then glides downward through \'you\'',
        'Peaks on \'nice\', then stays flat until the end',
        'The phrase is pronounced as disconnected staccato tokens'
      ],
      'correctAnswerIndex': 1,
      'correctAnswer': 'Peaks on \'meet\', then glides downward through \'you\'',
      'speedLevel': 0.75,
      'instruction': 'Listen to the native cadence and identify the nuclear stress and pitch contour.',
      'explanation': 'Peaks on \'meet\', then glides downward through \'you\'.',
    },
  ];
}
