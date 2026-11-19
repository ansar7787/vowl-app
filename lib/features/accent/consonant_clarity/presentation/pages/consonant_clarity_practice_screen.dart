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

/// Interactive Practice Phase screen for Consonant Clarity ("Consonant Precision Gym").
///
/// Prompts learners to listen to spoken words and identify the target consonant phoneme
/// across 4 distinct options with instant feedback, explanations, and score tracking.
class ConsonantClarityPracticeScreen extends StatefulWidget {
  final int level;

  const ConsonantClarityPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ConsonantClarityPracticeScreen> createState() =>
      _ConsonantClarityPracticeScreenState();
}

class _ConsonantClarityPracticeScreenState
    extends State<ConsonantClarityPracticeScreen> {
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
        'assets/curriculum/accent/consonantClarity_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
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
          'id': 'ACC_CONSONANTCLARITY_PRACTICE_FALLBACK_1',
          'gameType': 'consonantClarity',
          'level': widget.level,
          'instruction': 'Identify the consonant sound in this word',
          'word': 'pen',
          'textToSpeak': 'pen',
          'options': ['/p/', '/b/', '/t/', '/k/'],
          'correctAnswer': '/p/',
          'correctAnswerIndex': 0,
          'mouthPosition':
              'Seal both lips, build air pressure, and pop them apart with a puff of air and quiet throat.',
          'explanation':
              "'Pen' opens with /p/. The lips seal, pressure builds, and the release sends a quick puff of breath out.",
          'hint': 'Hold your palm before your lips. Feel the puff of air.',
        },
        {
          'id': 'ACC_CONSONANTCLARITY_PRACTICE_FALLBACK_2',
          'gameType': 'consonantClarity',
          'level': widget.level,
          'instruction': 'Identify the consonant sound in this word',
          'word': 'boat',
          'textToSpeak': 'boat',
          'options': ['/b/', '/p/', '/d/', '/m/'],
          'correctAnswer': '/b/',
          'correctAnswerIndex': 0,
          'mouthPosition':
              'Press lips together and hum in your throat before they open gently into "oat".',
          'explanation':
              "'Boat' starts with /b/, the voiced partner of /p/. Vocal cords vibrate before release.",
          'hint': 'Feel the vocal buzz under your fingers while lips are shut.',
        },
        {
          'id': 'ACC_CONSONANTCLARITY_PRACTICE_FALLBACK_3',
          'gameType': 'consonantClarity',
          'level': widget.level,
          'instruction': 'Identify the consonant sound in this word',
          'word': 'milk',
          'textToSpeak': 'milk',
          'options': ['/m/', '/b/', '/n/', '/w/'],
          'correctAnswer': '/m/',
          'correctAnswerIndex': 0,
          'mouthPosition':
              'Close your lips and hum so voiced sound flows continuously out through your nose.',
          'explanation':
              "'Milk' begins with /m/. Air escapes through the nose, making it prolongable.",
          'hint': 'Pinch your nose to test the nasal airflow.',
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

  void _selectOption(int index) {
    if (_hasChecked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final quest = _quests[_exerciseIndex % _quests.length];
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final isCorrect = options.isNotEmpty &&
        _selectedOptionIndex! < options.length &&
        options[_selectedOptionIndex!] == correctAnswer;

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
      if (isCorrect) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  void _nextExercise() {
    if (_exerciseIndex + 1 < _quests.length) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
      });
    } else {
      _onPracticeComplete();
    }
  }

  void _onPracticeComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'consonantClarity',
      level: widget.level,
      phase: 'practice',
    );

    if (mounted) {
      try {
        context.pushReplacement(
          '/mastery?category=accent&gameType=consonantClarity&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests[_exerciseIndex % _quests.length];
    final word = quest['word'] as String? ?? 'Word';
    final textToSpeak = quest['textToSpeak'] as String? ?? word;
    final instruction = quest['instruction'] as String? ??
        'Identify the consonant sound in this word';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final mouthPosition = quest['mouthPosition'] as String? ?? '';

    final isCorrect = _hasChecked &&
        _selectedOptionIndex != null &&
        _selectedOptionIndex! < options.length &&
        options[_selectedOptionIndex!] == correctAnswer;

    return PracticePhaseScaffold(
      title: 'Consonant Precision Gym',
      gameType: 'consonantClarity',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _onPracticeComplete,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score and Progress Header
            _buildScoreHeader(),
            SizedBox(height: 16.h),

            // Instruction Card
            _buildInstructionCard(instruction),
            SizedBox(height: 16.h),

            // Target Word Card
            _buildTargetWordCard(word, textToSpeak),
            SizedBox(height: 20.h),

            // 4 Distinct Consonant Options Grid
            _buildOptionsGrid(options, correctAnswer),
            SizedBox(height: 24.h),

            // Check Answer Button (only before checking)
            if (!_hasChecked) _buildCheckButton(),

            // Feedback and Explanation Card (after checking)
            if (_hasChecked) ...[
              _buildFeedbackCard(isCorrect, mouthPosition, explanation),
              SizedBox(height: 20.h),
              _buildContinueButton(),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.w,
        runSpacing: 6.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 18.sp,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 8.w),
              Text(
                'EXERCISE ${_exerciseIndex + 1} OF ${_quests.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate200,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'SCORE: $_score',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(String instruction) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.indigo500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 22.sp,
            color: AppColors.indigo500,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetWordCard(String word, String textToSpeak) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Text(
                'TARGET WORD',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                  letterSpacing: 0.8,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('practice_listen_button'),
                onPressed: () => _playAudio(textToSpeak),
                icon: Icon(
                  Icons.volume_up_rounded,
                  size: 18.sp,
                  color: AppColors.white,
                ),
                label: Text(
                  'Listen',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '“$word”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid(List<String> options, String correctAnswer) {
    return Column(
      children: List.generate(options.length, (index) {
        final opt = options[index];
        final isSelected = _selectedOptionIndex == index;
        final isAnswer = opt == correctAnswer;

        Color borderColor = AppColors.slate200;
        Color bgColor = AppColors.white;
        Color textColor = AppColors.slate800;

        if (_hasChecked) {
          if (isAnswer) {
            borderColor = AppColors.emerald500;
            bgColor = AppColors.emerald500.withValues(alpha: 0.1);
            textColor = AppColors.emerald500;
          } else if (isSelected && !isAnswer) {
            borderColor = AppColors.rose500;
            bgColor = AppColors.rose500.withValues(alpha: 0.1);
            textColor = AppColors.rose500;
          }
        } else if (isSelected) {
          borderColor = AppColors.indigo500;
          bgColor = AppColors.indigo500.withValues(alpha: 0.08);
          textColor = AppColors.indigo500;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            key: Key('practice_option_$index'),
            onTap: () => _selectOption(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (_hasChecked && isAnswer) ? 2 : 1,
                ),
                boxShadow: [
                  if (!isSelected && !_hasChecked)
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? borderColor : AppColors.slate100,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: 'Courier',
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (_hasChecked && isAnswer)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 24.sp,
                      color: AppColors.emerald500,
                    )
                  else if (_hasChecked && isSelected && !isAnswer)
                    Icon(
                      Icons.cancel_rounded,
                      size: 24.sp,
                      color: AppColors.rose500,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCheckButton() {
    final isEnabled = _selectedOptionIndex != null;

    return ElevatedButton(
      key: const Key('practice_check_button'),
      onPressed: isEnabled ? _checkAnswer : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo500,
        disabledBackgroundColor: AppColors.slate200,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: isEnabled ? 3 : 0,
      ),
      child: Text(
        'CHECK ANSWER',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: isEnabled ? AppColors.white : AppColors.slate400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
      bool isCorrect, String mouthPosition, String explanation) {
    return Container(
      key: const Key('practice_explanation_card'),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.emerald500.withValues(alpha: 0.1)
            : AppColors.rose500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
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
                    : Icons.error_outline_rounded,
                size: 24.sp,
                color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  isCorrect ? 'EXCELLENT ARTICULATION!' : 'KEEP PRACTICING',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: isCorrect
                        ? AppColors.emerald500
                        : AppColors.rose500,
                  ),
                ),
              ),
            ],
          ),
          if (mouthPosition.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              mouthPosition,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
                height: 1.35,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.slate700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      key: const Key('practice_continue_button'),
      onPressed: _nextExercise,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo500,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        _exerciseIndex + 1 < _quests.length
            ? 'CONTINUE TO NEXT WORD'
            : 'COMPLETE PRACTICE',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
