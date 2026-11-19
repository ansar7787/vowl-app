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

/// Interactive Practice Phase screen for Speed Variance ("Tempo Precision Gym").
///
/// Prompts learners to listen to spoken sentences and evaluate the natural pacing
/// (Accelerated vs Decelerated) across 4 distinct contextual options with instant
/// feedback, explanations, and score tracking.
class SpeedVariancePracticeScreen extends StatefulWidget {
  final int level;

  const SpeedVariancePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeedVariancePracticeScreen> createState() =>
      _SpeedVariancePracticeScreenState();
}

class _SpeedVariancePracticeScreenState
    extends State<SpeedVariancePracticeScreen> {
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
        'assets/curriculum/accent/speedVariance_practice_${startLevel}_$endLevel.json';

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
          'id': 'ACC_SPEEDVARIANCE_PRACTICE_FALLBACK_1',
          'gameType': 'speedVariance',
          'level': widget.level,
          'instruction': 'Determine the natural pacing and speech tempo',
          'word': 'Look out, that shelf is falling!',
          'textToSpeak': 'Look out, that shelf is falling!',
          'options': [
            'Accelerating (sudden danger makes people blurt the warning out fast)',
            'Decelerating (a clear, stretched-out warning gives the listener time to understand)',
            'Steady Monotone (uniform mechanical speed across all syllables without variation)',
            'Compressed Staccato (rapidly clipping syllables to rush past critical details)',
          ],
          'correctAnswer':
              'Accelerating (sudden danger makes people blurt the warning out fast)',
          'correctAnswerIndex': 0,
          'targetSpeed': 1.5,
          'explanation':
              'When something is about to fall, people use short, quick words. Slow speech would arrive after the shelf does.',
          'hint': 'Is there any time to spare in this urgent moment?',
        },
        {
          'id': 'ACC_SPEEDVARIANCE_PRACTICE_FALLBACK_2',
          'gameType': 'speedVariance',
          'level': widget.level,
          'instruction': 'Determine the natural pacing and speech tempo',
          'word': "Take your time, there's no pressure.",
          'textToSpeak': "Take your time, there's no pressure.",
          'options': [
            'Decelerating (a relaxed, reassuring message is said at an unhurried pace)',
            'Accelerating (a short friendly sentence is usually said quickly to keep things moving)',
            'Rigid Metronomic (evenly spaced words that ignore situational reassurance)',
            'Mechanical Staccato (abrupt robot-like pace with zero emotional breathing room)',
          ],
          'correctAnswer':
              'Decelerating (a relaxed, reassuring message is said at an unhurried pace)',
          'correctAnswerIndex': 0,
          'targetSpeed': 0.7,
          'explanation':
              'Telling someone to relax works best when your own voice is relaxed. A fast delivery would add the very pressure you are taking away.',
          'hint': 'What feeling is the speaker trying to give the listener?',
        },
        {
          'id': 'ACC_SPEEDVARIANCE_PRACTICE_FALLBACK_3',
          'gameType': 'speedVariance',
          'level': widget.level,
          'instruction': 'Determine the natural pacing and speech tempo',
          'word': 'Yes! I got the job!',
          'textToSpeak': 'Yes! I got the job!',
          'options': [
            'Accelerating (joyful news bursts out of the speaker quickly)',
            'Decelerating (happy news is held back and said with careful slowness)',
            'Uniform Neutral (speaking at flat baseline speed without excitement)',
            'Sluggish Drag (overly slow delivery that causes conversational drag)',
          ],
          'correctAnswer':
              'Accelerating (joyful news bursts out of the speaker quickly)',
          'correctAnswerIndex': 0,
          'targetSpeed': 1.4,
          'explanation':
              'Excitement triggers high adrenaline and brisk speech velocity.',
          'hint': 'How does your voice sound when you are thrilled with good news?',
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
        gameType: 'speedVariance',
        level: widget.level,
        phase: 'practice',
      );
      try {
        context.pushReplacement(
          '/game?category=accent&gameType=speedVariance&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final instruction =
        current['instruction'] as String? ?? 'Determine the natural pacing';
    final word = current['word'] as String? ?? 'Look out, that shelf is falling!';
    final textToSpeak = current['textToSpeak'] as String? ?? word;
    final options = (current['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final targetSpeed = (current['targetSpeed'] as num?)?.toDouble() ?? 1.0;

    return PracticePhaseScaffold(
      title: 'Speed Variance',
      gameType: 'speedVariance',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. Score & Exercise Tracker
            _buildScoreHeader(),
            SizedBox(height: 14.h),

            // 1. Instruction
            Text(
              instruction,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            // 2. Sentence & Audio Player
            _buildPromptCard(word, textToSpeak, targetSpeed),
            SizedBox(height: 16.h),

            // 3. Hint (if present)
            if (hint.isNotEmpty && !_hasChecked) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hearing_rounded,
                        size: 14.sp, color: AppColors.indigo500),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.indigo500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // 4. Options
            Text(
              'SELECT THE OPTIMAL PACING',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.slate100.withValues(alpha: 0.5),
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),
            ...List.generate(options.length, (idx) {
              return _buildOptionTile(
                index: idx,
                text: options[idx],
                isSelected: _selectedOptionIndex == idx,
                isCorrect: idx == correctIdx,
              );
            }),
            SizedBox(height: 16.h),

            // 5. Explanation card on check
            if (_hasChecked) ...[
              _buildExplanationCard(
                explanation: explanation,
                isCorrect: _selectedOptionIndex == correctIdx,
              ),
              SizedBox(height: 16.h),
            ],

            // 6. Action Button (Check or Continue)
            _buildActionButton(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.slate800),
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
                Icons.av_timer_rounded,
                size: 16.sp,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 6.w),
              Text(
                'EXERCISE ${_exerciseIndex + 1} OF ${_quests.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate100,
                  letterSpacing: 0.5,
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
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(
    String word,
    String textToSpeak,
    double targetSpeed,
  ) {
    final isAccelerated = targetSpeed >= 1.05;
    final speedColor = isAccelerated ? AppColors.amber500 : AppColors.teal500;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: speedColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: speedColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAccelerated ? Icons.speed_rounded : Icons.timelapse_rounded,
                      size: 12.sp,
                      color: speedColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${targetSpeed.toStringAsFixed(1)}x CADENCE',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: speedColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('practice_play_audio_button'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.indigo500,
                    size: 20.sp,
                  ),
                ),
                onPressed: () => _playAudio(textToSpeak),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '"$word"',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
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
  }) {
    Color borderColor = AppColors.slate800;
    Color bgColor = AppColors.slate900;
    Color textColor = Colors.white;

    if (_hasChecked) {
      if (isCorrect) {
        borderColor = AppColors.emerald500;
        bgColor = AppColors.emerald500.withValues(alpha: 0.15);
        textColor = AppColors.emerald500;
      } else if (isSelected && !isCorrect) {
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
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        key: Key('practice_option_$index'),
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _onOptionSelected(index),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? borderColor
                      : AppColors.slate800.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
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
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
              if (_hasChecked && isCorrect)
                Padding(
                  padding: EdgeInsets.only(top: 2.h, left: 6.w),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.emerald500, size: 20.sp),
                ),
              if (_hasChecked && isSelected && !isCorrect)
                Padding(
                  padding: EdgeInsets.only(top: 2.h, left: 6.w),
                  child: Icon(Icons.cancel_rounded,
                      color: AppColors.rose500, size: 20.sp),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard({
    required String explanation,
    required bool isCorrect,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                isCorrect ? 'EXCELLENT PACING!' : 'PACING INSIGHT',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (!_hasChecked) {
      final isEnabled = _selectedOptionIndex != null;
      return ElevatedButton(
        key: const Key('practice_check_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? AppColors.indigo500 : AppColors.slate800,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        onPressed: isEnabled ? _onCheck : null,
        child: Text(
          'CHECK ANSWER',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return ElevatedButton(
      key: const Key('practice_continue_button'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
      onPressed: _onContinue,
      child: Text(
        _exerciseIndex < _quests.length - 1
            ? 'CONTINUE'
            : 'COMPLETE PRACTICE',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
