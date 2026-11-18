import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Reading Conclusion ("Next Step Predictor Gym").
///
/// Prompts users to analyze premises, predict logical next steps, and select sound conclusions
/// while rejecting premature speculations and premise contradictions.
class ReadingConclusionPracticeScreen extends StatefulWidget {
  final int level;

  const ReadingConclusionPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadingConclusionPracticeScreen> createState() =>
      _ReadingConclusionPracticeScreenState();
}

class _ReadingConclusionPracticeScreenState
    extends State<ReadingConclusionPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

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
        'assets/curriculum/reading/readingConclusion_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final qLevel = q['level'] as int? ?? 1;
        return qLevel == widget.level;
      }).toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          }
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_READINGCONCLUSION_PRACTICE_FALLBACK_1',
          'level': widget.level,
          'instruction':
              'Read the passage and select the correct conclusion.',
          'passage':
              'Maya left her bicycle outside overnight. In the morning, the seat and handlebars were covered in tiny drops of water, even though no one had touched the bike.',
          'options': [
            'It rained during the night.',
            'Maya washed her bicycle before going to bed.',
            'The bicycle was stored inside a garage.',
            'Someone poured water on the bicycle on purpose.',
          ],
          'correctAnswer': 'It rained during the night.',
          'hint':
              'Think about what could leave water on a bike that sat outside all night.',
          'explanation':
              'The bike was left outside, and water appeared on it overnight without anyone touching it. Rain is the simplest and only premise-consistent deduction.',
          'strategyBadge': 'LOGICAL EXTRAPOLATION MATRIX',
          'logicChainSteps': [
            'Bike left outside overnight',
            'Water found on seat & handlebars',
            'No human touched or moved the bike',
            'Precipitation (rain) occurred overnight',
          ],
        },
        {
          'id': 'RDG_READINGCONCLUSION_PRACTICE_FALLBACK_2',
          'level': widget.level,
          'instruction':
              'Read the passage and select the correct conclusion.',
          'passage':
              'Mrs. Ortiz baked a tray of cookies and left them on the counter to cool. When she came back, half the cookies were gone, and her young son had chocolate smudges around his mouth.',
          'options': [
            'The neighbors came inside and ate the cookies.',
            'The cookies were never baked at all.',
            'Her son ate some of the cookies.',
            'Mrs. Ortiz ate the cookies herself.',
          ],
          'correctAnswer': 'Her son ate some of the cookies.',
          'hint': 'Look at what was found on the boy\'s face.',
          'explanation':
              'Cookies went missing, and the boy\'s mouth had chocolate smudges on it. This physical evidence connects him directly to the missing cookies.',
          'strategyBadge': 'PREMISE LINK RADAR',
          'logicChainSteps': [
            'Fresh cookies left unattended on counter',
            'Half of the cookies vanished',
            'Young son has chocolate smudges on mouth',
            'Son consumed the missing cookies',
          ],
        },
      ];

  void _onOptionSelected(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _handleSubmit() {
    if (!_isChecked) {
      if (_selectedOptionIndex == null) return;

      final quest = _quests[_questIndex];
      final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
      final correctAnswer = (quest['correctAnswer'] as String? ?? '').trim();
      final selectedText = options[_selectedOptionIndex!].trim();

      setState(() {
        _isChecked = true;
        _isCorrect =
            selectedText.toLowerCase() == correctAnswer.toLowerCase();
      });
    } else {
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _selectedOptionIndex = null;
          _isChecked = false;
          _isCorrect = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final instruction = quest['instruction'] as String? ??
        'Read the passage and select the correct conclusion.';
    final passage = quest['passage'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = (quest['correctAnswer'] as String? ?? '').trim();
    final explanation = quest['explanation'] as String? ?? '';
    final strategyBadge =
        quest['strategyBadge'] as String? ?? 'PREMISE MATRIX';
    final logicChainSteps = (quest['logicChainSteps'] as List<dynamic>? ?? [])
        .cast<String>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastQuest = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Next Step Predictor Gym',
      gameType: 'readingConclusion',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _handleSubmit,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Strategy Badge Pill & Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_rounded,
                            size: 12.sp, color: AppColors.violet500),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            strategyBadge,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.violet500,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Scenario ${_questIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.slate400
                        : AppColors.slate600,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              instruction,
              style: TextStyle(
                color: isDark ? AppColors.slate300 : AppColors.slate700,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 14.h),

            // 2. Scenario Premises Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                  width: 1.5,
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
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.blue900.withValues(alpha: 0.3)
                          : AppColors.blue50,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'PREMISES IN TEXT',
                      style: TextStyle(
                        color: AppColors.blue500,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 3. Question Prompt
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.blue900.withValues(alpha: 0.25)
                    : AppColors.blue50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.blue500.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 18.sp, color: AppColors.blue500),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Which conclusion necessarily follows from these premises?',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate900,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // 4. Candidate Option Rack
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isTargetCorrect =
                  optionText.trim().toLowerCase() ==
                      correctAnswer.toLowerCase();

              Color borderColor = isDark
                  ? AppColors.slate700
                  : AppColors.slate300;
              Color bgColor = isDark
                  ? AppColors.slate900
                  : Colors.white;
              Widget? trailingIcon;

              if (_isChecked) {
                if (isTargetCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = isDark
                      ? AppColors.emerald950.withValues(alpha: 0.35)
                      : AppColors.emerald50;
                  trailingIcon = Icon(Icons.check_circle_rounded,
                      color: AppColors.emerald500, size: 20.sp);
                } else if (isSelected && !_isCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = isDark
                      ? AppColors.red900.withValues(alpha: 0.35)
                      : AppColors.red50;
                  trailingIcon = Icon(Icons.cancel_rounded,
                      color: AppColors.rose500, size: 20.sp);
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = isDark
                    ? AppColors.indigo950.withValues(alpha: 0.35)
                    : AppColors.indigo50;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: InkWell(
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(14.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_isChecked && isTargetCorrect)
                            ? 1.8
                            : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.indigo500
                                    .withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (_isChecked
                                    ? (isTargetCorrect
                                        ? AppColors.emerald500
                                        : AppColors.rose500)
                                    : AppColors.indigo500)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? AppColors.slate600
                                      : AppColors.slate400),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.slate900,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
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
                ),
              );
            }),

            // 5. Post-Submit Feedback Card
            if (_isChecked) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500
                        : AppColors.rose500,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500)
                          .withValues(alpha: 0.1),
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
                          _isCorrect
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'LOGIC CHAIN VERIFIED!'
                                : 'LOGICAL FALLACY DETECTED',
                            style: TextStyle(
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate800,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                    if (logicChainSteps.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'VALIDATED LOGIC CHAIN:',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: logicChainSteps.map((step) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_right_rounded,
                                    size: 14.sp,
                                    color: AppColors.indigo500),
                                SizedBox(width: 3.w),
                                Flexible(
                                  child: Text(
                                    step,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.indigo400
                                          : AppColors.indigo600,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 18.h),

            // 6. Action Button
            ElevatedButton(
              onPressed: _selectedOptionIndex == null ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? AppColors.slate800
                    : AppColors.slate300,
                disabledForegroundColor: isDark
                    ? AppColors.slate600
                    : AppColors.slate500,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                !_isChecked
                    ? 'Check Conclusion'
                    : (isLastQuest ? 'Complete Practice Phase' : 'Next Scenario'),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
