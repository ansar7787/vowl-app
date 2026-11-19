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

/// Interactive Practice Phase screen for Audio Sentence Order ("Audio Jigsaw Gym").
///
/// Learners listen to spoken audio statements, observe shuffled word tiles,
/// and reconstruct the exact chronological sequence using instant analytical feedback.
class AudioSentenceOrderPracticeScreen extends StatefulWidget {
  final int level;

  const AudioSentenceOrderPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<AudioSentenceOrderPracticeScreen> createState() =>
      _AudioSentenceOrderPracticeScreenState();
}

class _AudioSentenceOrderPracticeScreenState
    extends State<AudioSentenceOrderPracticeScreen> {
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
        'assets/curriculum/listening/audioSentenceOrder_practice_${startLevel}_$endLevel.json';

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
          'id': 'LIS_AUDIOSENTENCEORDER_PRACTICE_FALLBACK_1',
          'textToSpeak': 'I have a car.',
          'question': 'Which sequence matches the spoken sentence exactly?',
          'shuffledTokens': ['have', 'car', 'I', 'a'],
          'options': [
            'I have a car',
            'have I a car',
            'car a have I',
            'I a have car',
          ],
          'correctIndex': 0,
          'correctAnswer': 'I have a car',
          'explanation':
              'Subject (I) comes first, then the verb "have", then the object (a car).',
          'hint':
              'Listen for the small word right after "I" — it changes the whole sentence.',
          'instruction':
              'Listen to the audio and select the sequence that matches the spoken order.',
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
    final correctIndex = currentQuest['correctIndex'] as int? ??
        currentQuest['correctAnswerIndex'] as int? ??
        0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _hasChecked = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _score++;
      }
    });

    final textToSpeak = currentQuest['textToSpeak'] as String? ?? '';
    _playAudio(textToSpeak);
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
        gameType: 'audioSentenceOrder',
        level: widget.level,
        phase: 'practice',
      );
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.slate900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.amber500, size: 28.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Practice Complete!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.slate100 : AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masterful ear! You ordered $_score out of ${_quests.length} sentence sequences accurately.',
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Mastery phase is unlocked! Step into the oscilloscope jigsaw sentence arena.',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.emerald500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement(
                '/game?category=listening&gameType=audioSentenceOrder&level=${widget.level}',
              );
            },
            child: Text(
              'Enter Mastery Arena',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_exerciseIndex];
    final textToSpeak = currentQuest['textToSpeak'] as String? ?? '';
    final shuffledTokens =
        (currentQuest['shuffledTokens'] as List<dynamic>? ?? []).cast<String>();
    final options =
        (currentQuest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = currentQuest['correctIndex'] as int? ??
        currentQuest['correctAnswerIndex'] as int? ??
        0;
    final explanation = currentQuest['explanation'] as String? ?? '';
    final hint = currentQuest['hint'] as String? ?? '';
    final instruction = currentQuest['instruction'] as String? ??
        'Listen to the audio and select the sequence that matches the spoken order.';

    return PracticePhaseScaffold(
      title: 'Audio Jigsaw Gym',
      gameType: 'audioSentenceOrder',
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
            // Exercise Header Badges
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'EXERCISE ${_exerciseIndex + 1} OF ${_quests.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'SCORE: $_score',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Instruction Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.6)
                    : AppColors.slate100,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    size: 18.sp,
                    color: AppColors.indigo500,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Audio Player Control Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.indigo500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.indigo50.withValues(alpha: 0.8),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.indigo500,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SPOKEN SENTENCE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Listen carefully to the word order and cadence.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  ElevatedButton.icon(
                    key: const Key('practice_audio_button'),
                    onPressed: () => _playAudio(textToSpeak),
                    icon: Icon(Icons.play_arrow_rounded, size: 22.sp),
                    label: Text(
                      'Listen Sentence',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo500,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Scrambled Tokens Display Card
            if (shuffledTokens.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCRAMBLED WORD POOL',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate400,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: shuffledTokens.map((token) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.slate700
                                  : AppColors.slate300,
                            ),
                          ),
                          child: Text(
                            token,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // 4 Sequence Options
            Text(
              'SELECT THE CORRECT WORD SEQUENCE:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),

            ...List.generate(options.length, (index) {
              final option = options[index];
              final isSelected = _selectedOptionIndex == index;

              Color borderColor =
                  isDark ? AppColors.slate800 : AppColors.slate200;
              Color bgColor = isDark ? AppColors.slate900 : Colors.white;
              Color textColor =
                  isDark ? AppColors.slate200 : AppColors.slate800;
              IconData? trailingIcon;
              Color iconColor = Colors.transparent;

              if (_hasChecked) {
                if (index == correctIndex) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.15);
                  textColor = AppColors.emerald500;
                  trailingIcon = Icons.check_circle_rounded;
                  iconColor = AppColors.emerald500;
                } else if (isSelected) {
                  borderColor = AppColors.red500;
                  bgColor = AppColors.red500.withValues(alpha: 0.15);
                  textColor = AppColors.red500;
                  trailingIcon = Icons.cancel_rounded;
                  iconColor = AppColors.red500;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.12);
                textColor = AppColors.indigo500;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: InkWell(
                  key: Key('practice_option_$index'),
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_hasChecked && index == correctIndex)
                            ? 2.0
                            : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28.r,
                          height: 28.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (borderColor)
                                : (isDark
                                    ? AppColors.slate800
                                    : AppColors.slate100),
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          SizedBox(width: 8.w),
                          Icon(trailingIcon, color: iconColor, size: 20.sp),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 8.h),

            // Check / Next Action Area
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed:
                    _selectedOptionIndex != null ? _onCheckAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? AppColors.slate800
                      : AppColors.slate200,
                  disabledForegroundColor: isDark
                      ? AppColors.slate600
                      : AppColors.slate400,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Check Answer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            // Post-Check Feedback Card
            if (_hasChecked) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.red500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.red500.withValues(alpha: 0.4),
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
                              : AppColors.red500,
                          size: 22.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'Sequence Confirmed!'
                                : 'Disordered Cadence',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.red500,
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
                          fontSize: 13.sp,
                          height: 1.4,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ],
                    if (hint.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Hint: $hint',
                        style: TextStyle(
                          fontSize: 12.sp,
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
              SizedBox(height: 12.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'Next Question'
                      : 'Complete Practice',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
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
}
