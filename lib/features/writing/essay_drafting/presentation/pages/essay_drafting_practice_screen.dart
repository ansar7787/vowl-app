import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Essay Drafting ("Essay Outline & Paragraph Gym").
///
/// Prompts learners to evaluate alternative paragraph orderings for an essay topic,
/// identify premature conclusions and scrambled evidence, and select the most logically sound progression.
class EssayDraftingPracticeScreen extends StatefulWidget {
  final int level;

  const EssayDraftingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<EssayDraftingPracticeScreen> createState() =>
      _EssayDraftingPracticeScreenState();
}

class _EssayDraftingPracticeScreenState
    extends State<EssayDraftingPracticeScreen> {
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
        'assets/curriculum/writing/essayDrafting_practice_${startLevel}_$endLevel.json';

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
          'id': 'WRT_ESSAYDRAFTING_PRAC_FALLBACK_1',
          'instruction':
              'Select the paragraph draft that arranges the arguments in the most logically cohesive and compelling order.',
          'essayTopic':
              'Describe why a short morning walk is worth adding to your day',
          'thesisStatement':
              'A short morning walk is an easy, low-cost way to start the day well.',
          'options': [
            'A short walk each morning is one of the easiest ways to start the day well. It gives the body gentle exercise before the day fills up with sitting. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. A habit that small costs almost nothing and keeps paying back until evening.',
            'A habit that small costs almost nothing and keeps paying back until evening. A short walk each morning is one of the easiest ways to start the day well. It gives the body gentle exercise before the day fills up with sitting. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready.',
            'A habit that small costs almost nothing and keeps paying back until evening. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. It gives the body gentle exercise before the day fills up with sitting. A short walk each morning is one of the easiest ways to start the day well.',
            'A short walk each morning is one of the easiest ways to start the day well. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. It gives the body gentle exercise before the day fills up with sitting. A habit that small costs almost nothing and keeps paying back until evening.',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'A short walk each morning is one of the easiest ways to start the day well. It gives the body gentle exercise before the day fills up with sitting. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. A habit that small costs almost nothing and keeps paying back until evening.',
          'hint':
              'Look for the draft that opens with the main premise and moves through rationale and evidence before concluding.',
          'explanation':
              'The opening sentence makes the claim the rest of the paragraph has to support. The reason explains why the claim holds, and only then does the twenty-minute example land, because it shows that reason at work. The closing thought steps back to the payoff.',
          'distractorFeedback': {
            'A habit that small costs almost nothing and keeps paying back until evening. A short walk each morning is one of the easiest ways to start the day well. It gives the body gentle exercise before the day fills up with sitting. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready.':
                'Premature conclusion: opens with the strategic payoff or closing thought before stating the main claim or presenting evidence.',
            'A habit that small costs almost nothing and keeps paying back until evening. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. It gives the body gentle exercise before the day fills up with sitting. A short walk each morning is one of the easiest ways to start the day well.':
                'Inverted rhetorical flow: works backwards from the conclusion to the premise, confusing cause and effect.',
            'A short walk each morning is one of the easiest ways to start the day well. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. It gives the body gentle exercise before the day fills up with sitting. A habit that small costs almost nothing and keeps paying back until evening.':
                'Flawed internal development: inserts specific case illustrations before establishing the logical reasoning behind them.',
          },
        },
      ];

  void _onOptionTap(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheck() {
    if (_selectedOptionIndex == null) return;

    final quest = _quests[_questIndex];
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final isCorrectMatch = _selectedOptionIndex == correctIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrectMatch;
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _resetForCurrentQuest();
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'essayDrafting',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/game?category=writing&gameType=essayDrafting&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final instruction = quest['instruction'] as String? ?? '';
    final essayTopic = quest['essayTopic'] as String? ?? '';
    final thesisStatement = quest['thesisStatement'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {});

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Essay Outline & Paragraph Gym',
      gameType: 'essayDrafting',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: !_isChecked
          ? 'Check Paragraph Draft'
          : (isLast ? 'Start Mastery Phase' : 'Next Exercise'),
      isActionEnabled: _selectedOptionIndex != null || _isChecked,
      onComplete: _isChecked ? _onNext : _onCheck,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress & Strategy Badge
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
                    'PRACTICE EXERCISE ${_questIndex + 1} OF ${_quests.length}',
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
                    color: AppColors.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Deductive Rhetorical Flow',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Topic and Thesis Statement Card
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
                        Icons.article_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ESSAY TOPIC',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    essayTopic,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  if (thesisStatement.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Thesis: "$thesisStatement"',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                  if (instruction.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Selection Prompt
            Text(
              'SELECT THE MOST COHESIVE PARAGRAPH ORDER:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            // Options List
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isCorrectOption = index == correctIndex;

              Color borderColor =
                  isDark ? AppColors.slate800 : AppColors.slate200;
              Color cardBg = isDark ? AppColors.slate900 : Colors.white;
              Color indicatorColor =
                  isDark ? AppColors.slate700 : AppColors.slate300;
              IconData indicatorIcon = Icons.circle_outlined;

              if (_isChecked) {
                if (isCorrectOption) {
                  borderColor = AppColors.emerald500;
                  cardBg = AppColors.emerald500.withValues(alpha: 0.08);
                  indicatorColor = AppColors.emerald500;
                  indicatorIcon = Icons.check_circle_rounded;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  cardBg = AppColors.rose500.withValues(alpha: 0.08);
                  indicatorColor = AppColors.rose500;
                  indicatorIcon = Icons.cancel_rounded;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                cardBg = AppColors.indigo500.withValues(alpha: 0.06);
                indicatorColor = AppColors.indigo500;
                indicatorIcon = Icons.radio_button_checked_rounded;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onOptionTap(index),
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isCorrectOption)
                              ? 1.8
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            indicatorIcon,
                            size: 20.sp,
                            color: indicatorColor,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isDark
                                    ? AppColors.slate100
                                    : AppColors.slate800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Feedback Card (shown after checking)
            if (_isChecked) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.amber500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 20.sp,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.amber500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'COMPELLING & COHESIVE ESSAY DRAFT!'
                                : 'DRAFT ANALYSIS & RHETORICAL FEEDBACK',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                    if (!_isCorrect &&
                        _selectedOptionIndex != null &&
                        distractorFeedback
                            .containsKey(options[_selectedOptionIndex!])) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.rose500.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16.sp,
                              color: AppColors.rose500,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                distractorFeedback[
                                        options[_selectedOptionIndex!]]
                                    .toString(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  color: AppColors.rose500,
                                  height: 1.3,
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
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
