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

/// Interactive Practice Phase screen for Word Linking ("Connected Flow Gym").
///
/// Prompts learners to listen to spoken sentences and identify where fluent native
/// speech links word boundaries smoothly across 4 options with instant feedback.
class WordLinkingPracticeScreen extends StatefulWidget {
  final int level;

  const WordLinkingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<WordLinkingPracticeScreen> createState() =>
      _WordLinkingPracticeScreenState();
}

class _WordLinkingPracticeScreenState
    extends State<WordLinkingPracticeScreen> {
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
        'assets/curriculum/accent/wordLinking_practice_${startLevel}_$endLevel.json';

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
          'id': 'ACC_WORDLINKING_PRACTICE_FALLBACK_1',
          'gameType': 'wordLinking',
          'level': widget.level,
          'instruction':
              'Listen to the sentence and identify where the words link together.',
          'words': ['pick', 'up', 'the', 'phone'],
          'sentence': 'pick up the phone',
          'textToSpeak': 'pick up the phone',
          'linkedPair': 'pick up',
          'linkingType': 'consonant_to_vowel',
          'options': [
            '“pick” ➔ “up”',
            '“up” ➔ “the”',
            '“the” ➔ “phone”',
            'No connected boundary (Full Pause)'
          ],
          'correctAnswer': '“pick” ➔ “up”',
          'correctAnswerIndex': 0,
          'explanation':
              "'Pick' ends in /k/ and 'up' begins with a vowel sound, so the words fuse seamlessly into 'pi-ckup' with no pause between them.",
          'hint':
              'Listen for where the voice moves without stopping between two words.',
          'flowRule':
              'When words connect smoothly in spoken English, ending sounds bridge directly into following sounds.',
          'emoji': '🔗',
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

  void _onSelectOption(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _onCheckAnswer() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final currentQuest =
        _quests.isNotEmpty ? _quests[_exerciseIndex] : _fallbackQuests[0];
    final correctIndex = currentQuest['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _hasChecked = true;
      if (isCorrect) {
        _score++;
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

    try {
      if (isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
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
        gameType: 'wordLinking',
        level: widget.level,
        phase: 'practice',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/mastery?category=accent&gameType=wordLinking&level=${widget.level}',
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest =
        _quests.isNotEmpty ? _quests[_exerciseIndex] : _fallbackQuests[0];

    final instruction = currentQuest['instruction'] as String? ??
        'Listen to the sentence and identify where the words link together.';
    final words = (currentQuest['words'] as List<dynamic>? ?? ['pick', 'up', 'the', 'phone'])
        .cast<String>();
    final sentence = currentQuest['sentence'] as String? ?? words.join(' ');
    final textToSpeak = currentQuest['textToSpeak'] as String? ?? sentence;
    final options = (currentQuest['options'] as List<dynamic>? ??
            [
              '“pick” ➔ “up”',
              '“up” ➔ “the”',
              '“the” ➔ “phone”',
              'No connected boundary (Full Pause)'
            ])
        .cast<String>();
    final correctIndex = currentQuest['correctAnswerIndex'] as int? ?? 0;
    final explanation = currentQuest['explanation'] as String? ?? '';
    final hint = currentQuest['hint'] as String? ?? '';
    final emoji = currentQuest['emoji'] as String? ?? '🔗';

    final isCorrect = _selectedOptionIndex == correctIndex;

    return PracticePhaseScaffold(
      title: 'Connected Flow Gym',
      gameType: 'wordLinking',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status Bar
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

            // Spoken Sentence Audio Player Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.teal500.withValues(alpha: 0.22),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.teal500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal500.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                          Icons.volume_up_rounded,
                          color: AppColors.teal500,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          instruction,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Target Sentence Container
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      '"$sentence"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Play Button
                  ElevatedButton.icon(
                    key: const Key('practice_listen_button'),
                    onPressed: () => _playAudio(textToSpeak),
                    icon: Icon(Icons.play_arrow_rounded, size: 20.sp),
                    label: Text(
                      'Listen to Spoken Sentence',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Options Section
            Text(
              'SELECT THE CONNECTED WORD BOUNDARY:',
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
                  onTap: () => _onSelectOption(index),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_hasChecked && isTargetCorrect)
                            ? 2.0
                            : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (_hasChecked
                                    ? (isTargetCorrect
                                        ? AppColors.emerald500
                                        : AppColors.rose500)
                                    : AppColors.teal500)
                                : (isDark
                                    ? AppColors.slate800
                                    : AppColors.slate100),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.slate300
                                      : AppColors.slate700),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (statusIcon != null) ...[
                          SizedBox(width: 8.w),
                          Icon(statusIcon, color: iconColor, size: 20.sp),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Action / Check Button
            if (!_hasChecked) ...[
              SizedBox(height: 12.h),
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed:
                    _selectedOptionIndex != null ? _onCheckAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.slate800 : AppColors.slate200,
                  disabledForegroundColor:
                      isDark ? AppColors.slate600 : AppColors.slate400,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
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
            ],

            // Feedback Card
            if (_hasChecked) ...[
              SizedBox(height: 12.h),
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18.r),
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
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect ? 'NATURAL FLOW RECOGNIZED!' : 'KEEP PRACTICING',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: isCorrect
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
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.slate200
                              : AppColors.slate800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // Continue Button
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCorrect ? AppColors.emerald500 : AppColors.teal500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'Next Exercise'
                      : 'Complete Practice',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            if (hint.isNotEmpty && !_hasChecked) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.amber500,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
