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

/// Interactive Practice Phase screen for Listening Inference ("Inference Deduction Gym").
///
/// Learners listen to spoken scenarios, read between the lines, and select
/// the best deduction for the question asked.
class ListeningInferencePracticeScreen extends StatefulWidget {
  final int level;

  const ListeningInferencePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ListeningInferencePracticeScreen> createState() =>
      _ListeningInferencePracticeScreenState();
}

class _ListeningInferencePracticeScreenState
    extends State<ListeningInferencePracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  bool _isCorrect = false;
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
        'assets/curriculum/listening/listeningInference_practice_${startLevel}_$endLevel.json';

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
          'id': 'LIS_LISTENINGINFERENCE_PRACTICE_FALLBACK_1',
          'gameType': 'listeningInference',
          'level': widget.level,
          'instruction':
              'Listen closely and infer what is really happening.',
          'question': 'How does she feel?',
          'textToSpeak': 'She was laughing and clapping her hands.',
          'options': ['Happy', 'Tired'],
          'correctIndex': 0,
          'correctAnswerIndex': 0,
          'correctAnswer': 'Happy',
          'emoji': '😊',
          'hint': 'Think about what laughing and clapping usually show.',
          'explanation':
              "Laughing and clapping are things people do when they feel happy or excited. The sentence never says 'happy' directly, so you infer her feeling from her actions.",
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

  void _onCheckAnswer() {
    if (_selectedOptionIndex == null || _hasChecked) return;
    final currentQuest = _quests[_exerciseIndex];
    final correctIndex = (currentQuest['correctIndex'] as int?) ??
        (currentQuest['correctAnswerIndex'] as int?) ??
        0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _hasChecked = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _score += 10;
      }
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
        _isCorrect = false;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'listeningInference',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/mastery?category=listening&gameType=listeningInference&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_exerciseIndex];
    final textToSpeak = currentQuest['textToSpeak'] as String? ?? '';
    final question = currentQuest['question'] as String? ??
        'What can you infer from the audio?';
    final options = (currentQuest['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = (currentQuest['correctIndex'] as int?) ??
        (currentQuest['correctAnswerIndex'] as int?) ??
        0;
    final explanation = currentQuest['explanation'] as String? ?? '';
    final hint = currentQuest['hint'] as String? ?? '';
    final emoji = currentQuest['emoji'] as String? ?? '💡';

    return PracticePhaseScaffold(
      title: 'Inference Lens Gym',
      gameType: 'listeningInference',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badges
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
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'EXERCISE ${_exerciseIndex + 1} OF ${_quests.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        'SCORE: $_score',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Spoken Audio Player Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.teal500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.teal500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal500.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.teal500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.radar_rounded,
                          color: AppColors.teal500,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          question,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Play Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('practice_audio_play_button'),
                      onPressed: () => _playAudio(textToSpeak),
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      label: Text(
                        'LISTEN TO SITUATION',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal500,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Options List
            Text(
              'SELECT INFERRED CONCLUSION',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),

            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isTargetCorrect = index == correctIndex;

              Color borderColor =
                  isDark ? AppColors.slate800 : AppColors.slate200;
              Color bgColor = isDark ? AppColors.slate900 : Colors.white;
              Color textColor = isDark ? Colors.white : AppColors.slate900;
              IconData? statusIcon;
              Color? iconColor;

              if (_hasChecked) {
                if (isTargetCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                  textColor = AppColors.emerald500;
                  statusIcon = Icons.check_circle_rounded;
                  iconColor = AppColors.emerald500;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.12);
                  textColor = AppColors.rose500;
                  statusIcon = Icons.cancel_rounded;
                  iconColor = AppColors.rose500;
                }
              } else if (isSelected) {
                borderColor = AppColors.teal500;
                bgColor = AppColors.teal500.withValues(alpha: 0.1);
                textColor = AppColors.teal500;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: InkWell(
                  key: Key('practice_option_$index'),
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(14.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 13.h,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_hasChecked && isTargetCorrect)
                            ? 2
                            : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            color: isSelected ||
                                    (_hasChecked && isTargetCorrect)
                                ? (iconColor ?? AppColors.teal500)
                                    .withValues(alpha: 0.15)
                                : isDark
                                    ? AppColors.slate800
                                    : AppColors.slate100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: isSelected ||
                                        (_hasChecked && isTargetCorrect)
                                    ? (iconColor ?? AppColors.teal500)
                                    : isDark
                                        ? AppColors.slate400
                                        : AppColors.slate600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (statusIcon != null) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            statusIcon,
                            color: iconColor,
                            size: 20.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),

            // Feedback / Explanation Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.35)
                        : AppColors.rose500.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'EXCELLENT INFERENCE!'
                                : 'INCORRECT DEDUCTION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (explanation.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        explanation,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (hint.isNotEmpty && !_isCorrect) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Hint: $hint',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Action Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheckAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  disabledBackgroundColor:
                      isDark ? AppColors.slate800 : AppColors.slate200,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'CHECK ANSWER',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: _selectedOptionIndex != null
                        ? Colors.white
                        : (isDark ? AppColors.slate600 : AppColors.slate400),
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCorrect ? AppColors.emerald500 : AppColors.teal500,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'CONTINUE'
                      : 'COMPLETE PRACTICE',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
}
