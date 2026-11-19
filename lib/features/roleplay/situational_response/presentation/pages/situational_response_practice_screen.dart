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

/// Interactive Practice Phase screen for Situational Response ("Tone Calibrator Gym").
///
/// Gives learners rapid, low-stakes drills selecting situational responses with
/// matched formality, calibrated tone, and cultural social etiquette.
class SituationalResponsePracticeScreen extends StatefulWidget {
  final int level;

  const SituationalResponsePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SituationalResponsePracticeScreen> createState() =>
      _SituationalResponsePracticeScreenState();
}

class _SituationalResponsePracticeScreenState
    extends State<SituationalResponsePracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  int _score = 0;
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
        'assets/curriculum/roleplay/situationalResponse_practice_${startLevel}_$endLevel.json';

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

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
        });
      } else if (mounted && rawQuests.isNotEmpty) {
        final startIdx = ((widget.level - 1) % 10) * 3;
        final sublist = rawQuests.skip(startIdx).take(3).toList();
        if (sublist.isNotEmpty) {
          setState(() {
            _quests = sublist;
          });
        }
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'sr_practice_fallback_1',
          'scene':
              "A man holding the elevator door asks, 'Which floor?' You're heading to the third.",
          'options': [
            "Third floor. Why do you ask?",
            "Three, please. Thanks for waiting.",
            "I can press it myself, thanks.",
            "Whichever one you're getting off at.",
          ],
          'correctAnswerIndex': 1,
          'formalityScore': 40,
          'culturalNote':
              "In shared spaces like elevators, a short answer and a quick thank-you is the whole expected exchange.",
          'explanation':
              "Giving the floor plus a brief thanks answers him directly and acknowledges the courtesy. Questioning his motive or refusing his help turns a friendly moment into friction.",
        },
        {
          'id': 'sr_practice_fallback_2',
          'scene':
              "A barista calls out, 'Oat latte for Sam?' and holds up a cup. That's your order.",
          'options': [
            "Is this the one I ordered?",
            "Could you check that again?",
            "That's mine, thanks.",
            "Just leave it on the counter.",
          ],
          'correctAnswerIndex': 2,
          'formalityScore': 30,
          'culturalNote':
              "Baristas call names because orders pile up; a quick claim of the cup keeps the line moving.",
          'explanation':
              "Confirming it's yours completes the handoff with no fuss. Asking her to re-verify suggests you doubt something that already matches.",
        },
        {
          'id': 'sr_practice_fallback_3',
          'scene':
              "You're at the café waiting for a friend. She texts: 'Running 5 min late!'",
          'options': [
            "No problem, I'll grab us a table.",
            "You're always late, you know.",
            "Okay.",
            "Then I'll head out in five minutes.",
          ],
          'correctAnswerIndex': 0,
          'formalityScore': 20,
          'culturalNote':
              "Between friends, five minutes late is usually unremarkable; reassuring her removes any pressure she feels.",
          'explanation':
              "A relaxed reply that also does something useful keeps the mood light. Blame or ultimatums for a tiny delay damage interpersonal goodwill.",
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
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIdx;

    setState(() {
      _hasChecked = true;
      if (isCorrect) {
        _score += 100;
      }
    });

    try {
      if (di.sl.isRegistered<HapticService>()) {
        if (isCorrect) {
          di.sl<HapticService>().success();
        } else {
          di.sl<HapticService>().error();
        }
      }
      if (di.sl.isRegistered<SoundService>()) {
        if (isCorrect) {
          di.sl<SoundService>().playCorrect();
        } else {
          di.sl<SoundService>().playWrong();
        }
      }
    } catch (_) {}
  }

  void _onContinue() {
    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'situationalResponse',
        level: widget.level,
        phase: 'practice',
      );
      try {
        context.pushReplacement(
          '/game?category=roleplay&gameType=situationalResponse&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final scene = current['scene'] as String? ?? '';
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final formalityScore = current['formalityScore'] as int? ?? 40;
    final culturalNote = current['culturalNote'] as String? ?? '';
    final explanation = current['explanation'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Situational Response',
      gameType: 'situationalResponse',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status & Scenario Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
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
                    runSpacing: 8.h,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 180.w),
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
                              Icons.public_rounded,
                              size: 14.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'FORMALITY: $formalityScore%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'SCORE: $_score',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('practice_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.indigo500,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(scene),
                        tooltip: 'Listen to situation',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    scene,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate100,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Prompt instructions
            Text(
              'Select the appropriate response:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.slate100.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),

            // Options List
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isThisCorrect = index == correctIdx;

              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;
              Color textColor = AppColors.slate100;

              if (_hasChecked) {
                if (isThisCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.15);
                  textColor = AppColors.emerald500;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.15);
                  textColor = AppColors.rose500;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.15);
                textColor = AppColors.indigo500;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: InkWell(
                  key: Key('practice_option_$index'),
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_hasChecked && isThisCorrect) ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26.r,
                          height: 26.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected || (_hasChecked && isThisCorrect)
                                ? borderColor.withValues(alpha: 0.2)
                                : AppColors.slate800,
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (_hasChecked && isThisCorrect)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                            size: 20.sp,
                          )
                        else if (_hasChecked && isSelected)
                          Icon(
                            Icons.cancel_rounded,
                            color: AppColors.rose500,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 8.h),

            // Check Answer Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.slate800,
                  disabledForegroundColor: AppColors.slate100.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'CONFIRM RESPONSE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

            // Explanation & Next Steps Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: isCorrect ? AppColors.emerald500 : AppColors.amber500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isCorrect ? 'WELL CALIBRATED!' : 'COMMUNICATION FEEDBACK',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isCorrect ? AppColors.emerald500 : AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.slate100,
                        height: 1.4,
                      ),
                    ),
                    if (culturalNote.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 15.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              culturalNote,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.slate100.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? AppColors.emerald500 : AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex == _quests.length - 1 ? 'COMPLETE PRACTICE' : 'NEXT SITUATION',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

