import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Describe Situation Writing ("Guided Description & Cohesion Gym").
///
/// Prompts learners to evaluate observational descriptions and select the most
/// grammatically coherent, richly detailed narrative that logically links the scene anchors.
class DescribeSituationWritingPracticeScreen extends StatefulWidget {
  final int level;

  const DescribeSituationWritingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<DescribeSituationWritingPracticeScreen> createState() =>
      _DescribeSituationWritingPracticeScreenState();
}

class _DescribeSituationWritingPracticeScreenState
    extends State<DescribeSituationWritingPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

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
        'assets/curriculum/writing/describeSituationWriting_practice_${startLevel}_$endLevel.json';

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

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
            _resetForCurrentQuest();
          }
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'WRT_DESCRIBESITUATIONWRITING_PRAC_FALLBACK_1',
          'instruction': 'Select the most cohesive and grammatically complete description.',
          'situation':
              'It is seven o\'clock on a weekday morning. Describe what you do at home before you leave for work or school.',
          'emojis': ['⏰', '🪥', '🥣', '🎒'],
          'options': [
            'My alarm rings at seven, so I wake up and brush my teeth. I eat cereal with milk in the kitchen. Then I take my bag and leave.',
            'Alarm seven wake teeth brush cereal milk bag door leave right now.',
            'Because the alarm rings at seven o\'clock in the morning before leaving.',
            'I left my bag at work yesterday so my teeth were clean.',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'My alarm rings at seven, so I wake up and brush my teeth. I eat cereal with milk in the kitchen. Then I take my bag and leave.',
          'hint': 'Look for complete sentences with clear subjects, active verbs, and time order.',
          'explanation':
              'A well-formed description uses transitional sequencing (so, Then) to connect distinct chronological actions into a clear narrative.',
          'distractorFeedback': {
            'Alarm seven wake teeth brush cereal milk bag door leave right now.':
                'Keyword salad without grammatical glue words or complete predicate structures.',
            'Because the alarm rings at seven o\'clock in the morning before leaving.':
                'A dangling subordinate fragment lacking a main independent clause.',
            'I left my bag at work yesterday so my teeth were clean.':
                'Illogical causal connection that contradicts the morning routine premise.',
          },
        },
        {
          'id': 'WRT_DESCRIBESITUATIONWRITING_PRAC_FALLBACK_2',
          'instruction': 'Select the description that best balances all scene participants.',
          'situation':
              'The English lesson is about to start. Describe what the teacher and the students do in the classroom.',
          'emojis': ['🗣️', '📖', '🪑', '👩‍🏫'],
          'options': [
            'The teacher greets the class and writes on the board, while students sit at their desks and open their books.',
            'Teacher board write book open students talk sitting chair classroom.',
            'Although the teacher arrived early before the bell rang.',
            'Only the teacher talks for sixty minutes without students.',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'The teacher greets the class and writes on the board, while students sit at their desks and open their books.',
          'hint': 'Ensure both the teacher and the students have clear, active roles.',
          'explanation':
              'Using "while" effectively coordinates the parallel actions of teacher and students in the setting.',
          'distractorFeedback': {
            'Teacher board write book open students talk sitting chair classroom.':
                'Unstructured word list lacking prepositions, auxiliary verbs, and sentence boundaries.',
            'Although the teacher arrived early before the bell rang.':
                'Dependent clause that terminates without resolving its main action.',
            'Only the teacher talks for sixty minutes without students.':
                'Fails to describe what the students do as requested by the situation prompt.',
          },
        },
      ];

  void _onOptionSelected(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheck() {
    if (_isChecked) {
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'describeSituationWriting',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=writing&gameType=describeSituationWriting&level=${widget.level}',
        );
      }
      return;
    }

    if (_selectedOptionIndex == null) return;

    final quest = _quests[_questIndex];
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrect;
    });
  }

  void _showHint() {
    final quest = _quests[_questIndex];
    final hint = quest['hint'] as String? ??
        'Identify chronological connectors and complete sentences.';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.amber500,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Cohesion Hint',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                hint,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.slate300 : AppColors.slate700,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Got It',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _resolveOptions(Map<String, dynamic> quest) {
    final rawOptions = quest['options'] as List<dynamic>?;
    if (rawOptions != null && rawOptions.isNotEmpty) {
      return rawOptions.map((e) => e.toString()).toList();
    }
    final modelAnswer = quest['modelAnswer'] as String? ??
        quest['correctAnswer'] as String? ??
        'The scene unfolds with clear actions.';
    return [
      modelAnswer,
      'A collection of words with no active verbs or punctuation',
      'Because of the observed events taking place in the scene.',
      'An unrelated description with inconsistent time anchors.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];
    final situation = quest['situation'] as String? ?? '';
    final emojis = (quest['emojis'] as List<dynamic>? ?? []).cast<String>();
    final options = _resolveOptions(quest);
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final distractorFeedback =
        quest['distractorFeedback'] as Map<String, dynamic>? ?? {};

    String buttonLabel = 'Check Answer';
    if (_isChecked) {
      buttonLabel = _questIndex == _quests.length - 1
          ? 'Enter Mastery Game'
          : 'Next Exercise';
    }

    return PracticePhaseScaffold(
      title: 'Guided Description Gym',
      gameType: 'describeSituationWriting',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: buttonLabel,
      isActionEnabled: _selectedOptionIndex != null || _isChecked,
      onComplete: _onCheck,
      onHint: _showHint,
      isHintAvailable: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Situation Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 18.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SITUATION PROMPT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    situation,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  if (emojis.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Key scene anchors: ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                          ),
                        ),
                        ...emojis.map(
                          (em) => Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Text(em, style: TextStyle(fontSize: 18.sp)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Prompt Question
            Text(
              'SELECT THE OPTIMAL COHESIVE DESCRIPTION:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            // Options List
            ...List.generate(options.length, (idx) {
              final optionText = options[idx];
              final isSelected = _selectedOptionIndex == idx;

              Color borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
              Color bgColor = isDark ? AppColors.slate900 : Colors.white;

              if (_isChecked) {
                if (idx == correctIndex) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                } else if (isSelected && !_isCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.12);
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.08);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: GestureDetector(
                  onTap: () => _onOptionSelected(idx),
                  child: Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_isChecked && idx == correctIndex)
                            ? 2.0
                            : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22.r,
                          height: 22.r,
                          margin: EdgeInsets.only(top: 2.h, right: 10.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (_isChecked
                                    ? (idx == correctIndex
                                        ? AppColors.emerald500
                                        : AppColors.rose500)
                                    : AppColors.indigo500)
                                : (_isChecked && idx == correctIndex
                                    ? AppColors.emerald500
                                    : Colors.transparent),
                            border: Border.all(
                              color: isSelected || (_isChecked && idx == correctIndex)
                                  ? Colors.transparent
                                  : (isDark
                                      ? AppColors.slate700
                                      : AppColors.slate300),
                              width: 1.5,
                            ),
                          ),
                          child: (isSelected || (_isChecked && idx == correctIndex))
                              ? Icon(
                                  _isChecked
                                      ? (idx == correctIndex
                                          ? Icons.check
                                          : Icons.close)
                                      : Icons.circle,
                                  size: 13.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isDark ? AppColors.slate100 : AppColors.slate900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Feedback Card
            if (_isChecked) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.r),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect ? 'Well Observed!' : 'Refine Your Description',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _isCorrect
                          ? explanation
                          : (distractorFeedback[options[_selectedOptionIndex!]]
                                  as String? ??
                              explanation),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
