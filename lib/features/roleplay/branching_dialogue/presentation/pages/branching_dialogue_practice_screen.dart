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

/// Interactive Practice Phase screen for Branching Dialogue ("Scaffolded Consequence Gym").
///
/// Gives learners immediate, low-stakes practice evaluating conversational paths,
/// selecting optimal assertive responses, and reviewing realistic consequence feedback.
class BranchingDialoguePracticeScreen extends StatefulWidget {
  final int level;

  const BranchingDialoguePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<BranchingDialoguePracticeScreen> createState() =>
      _BranchingDialoguePracticeScreenState();
}

class _BranchingDialoguePracticeScreenState
    extends State<BranchingDialoguePracticeScreen> {
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
        'assets/curriculum/roleplay/branchingDialogue_practice_${startLevel}_$endLevel.json';

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
          'id': 'bd_practice_fallback_1',
          'persona': 'Maria, a new coworker',
          'scene':
              "It is your first day at a new job. Maria, who sits at the next desk, turns to you and says: 'Hi, I don't think we've met yet. What's your name?'",
          'options': [
            "Hi, I'm Alex. Nice to meet you, Maria.",
            "Good afternoon. My name is Alex Turner, and it is a pleasure to make your acquaintance.",
            "I'm doing okay, thanks, just getting used to the desk.",
          ],
          'correctAnswerIndex': 0,
          'consequencePreviews': [
            "Realistically, you introduce yourself clearly and the conversation gets off to a friendly start.",
            "In this moment, Maria gets your name, but the formal wording feels stiff for a casual desk introduction.",
            "In this moment, Maria still doesn't know your name, since you answered a different question than the one she asked.",
          ],
          'explanation':
              "Maria asked a simple, direct question, so a short, friendly answer with your name fits best. The very formal version answers correctly but sounds out of place for a first chat with a desk neighbour. The last option responds to 'how are you' instead of 'what's your name,' so it doesn't actually give Maria the information she asked for.",
        },
        {
          'id': 'bd_practice_fallback_2',
          'persona': 'A neighbour in your apartment building',
          'scene':
              "You're getting your mail when a neighbour you've never spoken to says: 'Oh, hey — are you new here? I don't think I've seen you before.'",
          'options': [
            "Yes, I moved from three streets over because my old landlord kept raising the rent, and honestly the whole building had issues with the heating too, so it's a long story really.",
            "Yes, looking back, that was more of a first reaction, so there might be a better way to handle it.",
            "Yeah, I just moved in last week. I'm Sam, by the way.",
          ],
          'correctAnswerIndex': 2,
          'consequencePreviews': [
            "You may notice that the neighbour gets more personal history than they were expecting from a first hallway chat.",
            "In this moment, the neighbour learns almost nothing and the conversation has nowhere to go.",
            "You confirm you're new, add your name, and open the door to further conversation.",
          ],
          'explanation':
              "A short confirmation plus your name gives the neighbour just enough to continue the conversation naturally. Answering with only 'Yes' leaves the exchange flat, while the long answer overshares personal details a new neighbour hasn't asked for.",
        },
        {
          'id': 'bd_practice_fallback_3',
          'persona': 'Someone at a work networking event',
          'scene':
              "You're at a work event, checking your phone because you're waiting for an important call, when someone taps your shoulder and says: 'Hi, I don't think we've officially met!'",
          'options': [
            "Sorry, I'm busy right now.",
            "Hi, I'm Jordan — sorry, I'm just waiting on a call, but great to meet you.",
            "Oh, hi! So how do you know people here? Are you with one of the sponsor companies, or did you come through a colleague, or—",
          ],
          'correctAnswerIndex': 1,
          'consequencePreviews': [
            "As a result, the person walks away without an introduction, and the interaction feels dismissive.",
            "Realistically, you introduce yourself and honestly explain your distraction without seeming rude.",
            "In this moment, you launch into a full conversation, but you may miss the call you were actually waiting for.",
          ],
          'explanation':
              "Giving your name and a quick, honest reason for being distracted respects both your situation and the other person's effort to introduce themselves.",
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
        gameType: 'branchingDialogue',
        level: widget.level,
        phase: 'practice',
      );
      try {
        context.pushReplacement(
          '/game?category=roleplay&gameType=branchingDialogue&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final persona = current['persona'] as String? ?? 'Conversational Partner';
    final scene = current['scene'] as String? ?? '';
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final consequences = (current['consequencePreviews'] as List<dynamic>? ?? []).cast<String>();
    final explanation = current['explanation'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Branching Dialogue',
      gameType: 'branchingDialogue',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status & Persona Bar
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
                        constraints: BoxConstraints(maxWidth: 200.w),
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
                              Icons.person_pin_rounded,
                              size: 14.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                persona,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.indigo500,
                                ),
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
                          size: 22.sp,
                        ),
                        onPressed: () => _playAudio(scene),
                        tooltip: 'Listen to conversational prompt',
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

            // Instructions text
            Text(
              'Select your response:',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        // Show consequence preview if checked
                        if (_hasChecked && index < consequences.length) ...[
                          SizedBox(height: 10.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: isThisCorrect
                                  ? AppColors.emerald500.withValues(alpha: 0.08)
                                  : AppColors.slate800.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.alt_route_rounded,
                                  size: 14.sp,
                                  color: isThisCorrect ? AppColors.emerald500 : AppColors.amber500,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    consequences[index],
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontStyle: FontStyle.italic,
                                      color: isThisCorrect
                                          ? AppColors.emerald500
                                          : AppColors.slate100.withValues(alpha: 0.8),
                                      height: 1.35,
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
                          isCorrect ? 'EXCELLENT STRATEGY!' : 'STRATEGIC FEEDBACK',
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
