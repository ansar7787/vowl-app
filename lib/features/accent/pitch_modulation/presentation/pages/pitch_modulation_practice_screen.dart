import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Pitch Modulation ("Pitch Modulation Gym").
///
/// Prompts learners to identify vocal pitch movement, contour endings, and attitudinal
/// nuances across 4 distinct options with instant feedback, explanations, and score tracking.
class PitchModulationPracticeScreen extends StatefulWidget {
  final int level;

  const PitchModulationPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<PitchModulationPracticeScreen> createState() =>
      _PitchModulationPracticeScreenState();
}

class _PitchModulationPracticeScreenState
    extends State<PitchModulationPracticeScreen> {
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
        'assets/curriculum/accent/pitchModulation_practice_${startLevel}_$endLevel.json';

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
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'pitchModulation_practice_fallback_1',
          'gameType': 'pitchModulation',
          'level': widget.level,
          'instruction':
              'Listen to this short reply, then decide where the pitch finishes.',
          'word': 'Thank you.',
          'textToSpeak': 'Thank you.',
          'options': [
            'Finishes lower than it started',
            'Finishes higher than it started',
            'Monotone plateau with zero perceptible pitch variation',
            'Abrupt staccato jump to falsetto register without melodic glide',
          ],
          'correctAnswer': 'Finishes lower than it started',
          'correctAnswerIndex': 0,
          'modulationPattern':
              "Falling: pitch peaks early on 'thank' and settles low by the end of 'you'.",
          'explanation':
              "In a plain thank-you the pitch peaks on 'thank' and then settles down through 'you'. That drop gives the reply a finished, closed feel.",
          'hint':
              'Compare the very first syllable with the very last one. Which sits higher?',
        },
        {
          'id': 'pitchModulation_practice_fallback_2',
          'gameType': 'pitchModulation',
          'level': widget.level,
          'instruction':
              'Listen once, then pick the description that matches the end of this question.',
          'word': 'Are you coming?',
          'textToSpeak': 'Are you coming?',
          'options': [
            'The voice lifts on the last word',
            'The voice sinks on the last word',
            'Continuous rising inflection that leaves the phrase hanging questioningly',
            'Rapid pitch fluctuation with erratic ungrounded peaks',
          ],
          'correctAnswer': 'The voice lifts on the last word',
          'correctAnswerIndex': 0,
          'modulationPattern':
              'Rising: pitch climbs through the last stressed syllable and stays high.',
          'explanation':
              "Yes/no questions climb through the last stressed syllable, 'com-', and stay up, signaling an answer is wanted.",
          'hint': "Follow 'coming' from its first sound to its last.",
        },
        {
          'id': 'pitchModulation_practice_fallback_3',
          'gameType': 'pitchModulation',
          'level': widget.level,
          'instruction':
              'Does the voice travel anywhere, or does it mostly stay put?',
          'word': 'Nothing much.',
          'textToSpeak': 'Nothing much.',
          'options': [
            'Stays near one level, barely moving',
            'Travels through clear ups and downs',
            'Monotone plateau with zero perceptible pitch variation',
            'Abrupt staccato jump to falsetto register without melodic glide',
          ],
          'correctAnswer': 'Stays near one level, barely moving',
          'correctAnswerIndex': 0,
          'modulationPattern':
              'Level delivery: very narrow pitch range, little rise or fall.',
          'explanation':
              "Replying 'nothing much' in a nearly level voice conveys low-key delivery with no extra excitement or concern.",
          'hint': 'Picture a line on a screen. Is it bumpy or flat?',
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
  }

  void _onCheck() {
    if (_selectedOptionIndex == null || _hasChecked) return;
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIdx;

    setState(() {
      _hasChecked = true;
      if (isCorrect) _score++;
    });

    try {
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
        gameType: 'pitchModulation',
        level: widget.level,
        phase: 'practice',
      );
      try {
        context.pushReplacement(
          '/game?category=accent&gameType=pitchModulation&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final instruction = current['instruction'] as String? ??
        'Identify how pitch moves across the spoken utterance';
    final word = current['word'] as String? ?? 'Pitch phrase';
    final textToSpeak = current['textToSpeak'] as String? ?? word;
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Pitch Modulation',
      gameType: 'pitchModulation',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: () {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'pitchModulation',
          level: widget.level,
          phase: 'practice',
        );
        try {
          context.pushReplacement(
            '/game?category=accent&gameType=pitchModulation&level=${widget.level}',
          );
        } catch (_) {}
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target phrase & audio prompt card
            _buildPromptCard(word, textToSpeak, instruction),
            SizedBox(height: 20.h),

            // Options list
            Text(
              'SELECT THE MATCHING PITCH CONTOUR:',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.slate100.withValues(alpha: 0.6),
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 12.h),

            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _buildOptionTile(
                  index: index,
                  text: optionText,
                  isSelected: isSelected,
                  isCorrect: index == correctIdx,
                  showResult: _hasChecked,
                ),
              );
            }),

            SizedBox(height: 16.h),

            // Action / Check button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.slate800.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white38,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'CHECK ANSWER',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

            // Explanation card & Continue button
            if (_hasChecked) ...[
              _buildExplanationCard(isCorrect, explanation, hint),
              SizedBox(height: 16.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCorrect ? AppColors.emerald500 : AppColors.teal500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'CONTINUE'
                      : 'COMPLETE PRACTICE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
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

  Widget _buildPromptCard(
      String word, String textToSpeak, String instruction) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.25),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'PITCH DYNAMICS',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'SCORE: $_score',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                key: const Key('practice_play_audio_button'),
                onTap: () => _playAudio(textToSpeak),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.teal500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Listen',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            instruction,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: AppColors.slate800.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.slate800,
              ),
            ),
            child: Text(
              '“$word”',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.teal500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
  }) {
    Color borderColor = AppColors.slate800;
    Color bgColor = AppColors.slate900.withValues(alpha: 0.6);
    Widget? trailingIcon;

    if (showResult) {
      if (isCorrect) {
        borderColor = AppColors.emerald500;
        bgColor = AppColors.emerald500.withValues(alpha: 0.15);
        trailingIcon = Icon(
          Icons.check_circle_rounded,
          color: AppColors.emerald500,
          size: 20.sp,
        );
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.rose500;
        bgColor = AppColors.rose500.withValues(alpha: 0.15);
        trailingIcon = Icon(
          Icons.cancel_rounded,
          color: AppColors.rose500,
          size: 20.sp,
        );
      }
    } else if (isSelected) {
      borderColor = AppColors.teal500;
      bgColor = AppColors.teal500.withValues(alpha: 0.15);
    }

    return InkWell(
      key: Key('practice_option_$index'),
      onTap: () => _onOptionSelected(index),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 26.w,
              height: 26.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.teal500
                    : AppColors.slate800.withValues(alpha: 0.5),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: 8.w),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(
      bool isCorrect, String explanation, String hint) {
    return Container(
      key: const Key('practice_explanation_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.emerald500.withValues(alpha: 0.1)
            : AppColors.rose500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCorrect
              ? AppColors.emerald500.withValues(alpha: 0.3)
              : AppColors.rose500.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  isCorrect ? 'EXCELLENT EAR!' : 'PITCH BREAKDOWN',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.slate100.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
          if (hint.isNotEmpty && !isCorrect) ...[
            SizedBox(height: 8.h),
            Text(
              'Tip: $hint',
              style: TextStyle(
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.slate100.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
