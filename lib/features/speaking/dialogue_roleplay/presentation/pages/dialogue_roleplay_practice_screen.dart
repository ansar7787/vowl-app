import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Dialogue Roleplay ("Conversational Gym").
///
/// Challenges learners to evaluate communicative situations, analyze roleplay prompts,
/// and select the most natural and contextually appropriate conversational response.
class DialogueRoleplayPracticeScreen extends StatefulWidget {
  final int level;

  const DialogueRoleplayPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<DialogueRoleplayPracticeScreen> createState() =>
      _DialogueRoleplayPracticeScreenState();
}

class _DialogueRoleplayPracticeScreenState
    extends State<DialogueRoleplayPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  bool get isCorrect => _isCorrect;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _resetForCurrentQuest();
    _loadCurriculum();
  }

  void _resetForCurrentQuest() {
    _selectedOptionIndex = null;
    _isChecked = false;
    _isCorrect = false;
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/speaking/dialogueRoleplay_practice_${startLevel}_$endLevel.json';

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
          _resetForCurrentQuest();
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'SPK_DIALOGUEROLEPLAY_PRAC_FALLBACK_1',
          'partnerDialogue': 'Hi there! I\'m Tom, I live next door.',
          'instruction': 'Greet the speaker back.',
          'question':
              'When your roleplay partner says: "Hi there! I\'m Tom, I live next door.", which response is the most natural and appropriate?',
          'options': [
            'Nice to meet you. I\'m Aisha.',
            'Could you please repeat that more slowly?',
            'Sorry, I have to run to another meeting now.',
            'That sounds good to me, thank you.',
          ],
          'correctIndex': 0,
          'correctAnswer': 'Nice to meet you. I\'m Aisha.',
          'explanation':
              'Trading names straight after a greeting keeps the exchange balanced, so you are not only receiving information.',
          'hint': 'Say hello and give your own name.',
          'emotionTag': 'Friendly',
          'distractorFeedback': {
            'Could you please repeat that more slowly?':
                'Incorrect: Asking for repetition is unsuitable when responding to an initial neighbor introduction.',
            'Sorry, I have to run to another meeting now?':
                'Incorrect: Abruptly dismissing a neighbor upon introduction is socially awkward.',
            'That sounds good to me, thank you.':
                'Incorrect: Agreeing to a nonexistent plan makes no sense after an introduction.',
          },
        },
      ];

  void _playAudio(String text, {double speed = 0.5}) {
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: speed);
      }
    } catch (_) {}
  }

  void _onSelectOption(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onAction() {
    if (!_isChecked) {
      if (_selectedOptionIndex == null) return;

      final quest = _quests[_questIndex];
      final correctIndex = quest['correctIndex'] as int? ?? 0;
      final isRight = _selectedOptionIndex == correctIndex;

      setState(() {
        _isChecked = true;
        _isCorrect = isRight;
      });

      try {
        if (di.sl.isRegistered<SoundService>()) {
          if (isRight) {
            di.sl<SoundService>().playCorrect();
          } else {
            di.sl<SoundService>().playWrong();
          }
        }
      } catch (_) {}
    } else {
      // Advance or complete
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'dialogueRoleplay',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=speaking&gameType=dialogueRoleplay&level=${widget.level}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final partnerDialogue = quest['partnerDialogue'] as String? ?? '';
    final instruction = quest['instruction'] as String? ?? 'Reply naturally.';
    final question = quest['question'] as String? ??
        'Which response is the most natural and appropriate?';
    final options = (quest['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final emotionTag = quest['emotionTag'] as String? ?? 'Neutral';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString()));

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Conversational Gym',
      gameType: 'dialogueRoleplay',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: _isChecked
          ? (isLast ? 'Complete & Unlock Mastery' : 'Next Question')
          : 'Check Answer',
      isActionEnabled: _selectedOptionIndex != null,
      onComplete: _onAction,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Progress Pill
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
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'PRACTICE CHALLENGE ${_questIndex + 1} OF ${_quests.length}',
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'LEVEL ${widget.level}',
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
            SizedBox(height: 14.h),

            // Partner Dialogue Prompt Box
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.indigo500.withValues(alpha: 0.2),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.indigo500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ROLEPLAY PARTNER',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          emotionTag.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$partnerDialogue"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo500,
                        side: BorderSide(
                          color: AppColors.indigo500.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => _playAudio(partnerDialogue),
                      icon: Icon(Icons.volume_up_rounded, size: 16.sp),
                      label: Text(
                        'Listen Partner Dialogue',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Communicative Goal & Hint Banner
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.amber500,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      hint.isNotEmpty
                          ? 'Goal: $instruction (Hint: $hint)'
                          : 'Goal: $instruction',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.amber400
                            : const Color(0xFFB45309),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Question Text
            Text(
              question,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate200 : AppColors.slate800,
              ),
            ),
            SizedBox(height: 10.h),

            // 4 Option Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final optionText = options[index];
                final isSelected = _selectedOptionIndex == index;
                final isThisCorrect = index == correctIndex;

                Color borderColor;
                Color bgColor;
                Widget? statusIcon;

                if (_isChecked) {
                  if (isThisCorrect) {
                    borderColor = AppColors.emerald500;
                    bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                    statusIcon = Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald500,
                      size: 20.sp,
                    );
                  } else if (isSelected) {
                    borderColor = AppColors.rose500;
                    bgColor = AppColors.rose500.withValues(alpha: 0.12);
                    statusIcon = Icon(
                      Icons.cancel_rounded,
                      color: AppColors.rose500,
                      size: 20.sp,
                    );
                  } else {
                    borderColor =
                        isDark ? AppColors.slate800 : AppColors.slate200;
                    bgColor = isDark ? AppColors.slate900 : Colors.white;
                  }
                } else if (isSelected) {
                  borderColor = AppColors.indigo500;
                  bgColor = AppColors.indigo500.withValues(alpha: 0.08);
                } else {
                  borderColor =
                      isDark ? AppColors.slate800 : AppColors.slate200;
                  bgColor = isDark ? AppColors.slate900 : Colors.white;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('practice_option_$index'),
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => _onSelectOption(index),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isThisCorrect)
                              ? 2.0
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.indigo500
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.indigo500
                                    : (isDark
                                        ? AppColors.slate700
                                        : AppColors.slate300),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
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
                              optionText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate200
                                    : AppColors.slate800,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (statusIcon != null) ...[
                            SizedBox(width: 8.w),
                            statusIcon,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 14.h),

            // Feedback Card (Mounted upon answer check)
            if (_isChecked)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                ? 'EXCELLENT RESPONSE'
                                : 'CONVERSATIONAL CORRECTION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _isCorrect
                          ? (explanation.isNotEmpty
                              ? explanation
                              : 'Well done! "${options[correctIndex]}" is the natural response to keep this roleplay exchange balanced.')
                          : (_selectedOptionIndex != null &&
                                  distractorFeedback.containsKey(
                                      options[_selectedOptionIndex!]))
                              ? distractorFeedback[
                                  options[_selectedOptionIndex!]]!
                              : 'Remember: In this scenario, "${options[correctIndex]}" is the most natural reply.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
