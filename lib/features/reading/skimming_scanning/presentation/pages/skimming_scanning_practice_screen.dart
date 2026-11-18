import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Skimming & Scanning ("Target Extraction Gym").
///
/// Prompts users to rapidly locate specified entities, dates, times, and proper nouns
/// under targeted search conditions.
class SkimmingScanningPracticeScreen extends StatefulWidget {
  final int level;

  const SkimmingScanningPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SkimmingScanningPracticeScreen> createState() =>
      _SkimmingScanningPracticeScreenState();
}

class _SkimmingScanningPracticeScreenState
    extends State<SkimmingScanningPracticeScreen> {
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
        'assets/curriculum/reading/skimmingScanning_practice_${startLevel}_$endLevel.json';

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
          'id': 'RDG_SKIMMINGSCANNING_PRACTICE_FALLBACK_1',
          'level': widget.level,
          'instruction': 'Scan the sentence to find the day mentioned.',
          'passage': "Maria's book club meets every Thursday evening.",
          'targetItem': 'Thursday',
          'targetInfo': 'Day of the week',
          'options': ['Tuesday', 'Thursday', 'evening', 'book'],
          'correctAnswer': 'Thursday',
          'hint': 'Look for the name of a day of the week.',
          'explanation':
              'The sentence names Thursday as the meeting day, not Tuesday.',
          'strategyBadge': 'VISUAL SACCADE & SCANNING RADAR',
        },
        {
          'id': 'RDG_SKIMMINGSCANNING_PRACTICE_FALLBACK_2',
          'level': widget.level,
          'instruction': 'Search the sentence for the closing time.',
          'passage': "The library closes at six o'clock tonight.",
          'targetItem': 'six',
          'targetInfo': 'Closing time',
          'options': ['seven', 'tonight', 'six', 'library'],
          'correctAnswer': 'six',
          'hint': 'Search for the number that tells the time.',
          'explanation':
              "The library's closing time is six; seven does not appear as a time here.",
          'strategyBadge': 'CAPITALIZATION & NUMERIC ANCHORS',
        },
      ];

  void _onOptionSelected(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheck() {
    if (_selectedOptionIndex == null || _isChecked) return;

    final quest = _quests[_questIndex];
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final selectedOption = options[_selectedOptionIndex!].trim().toLowerCase();
    final correctAnswer =
        (quest['correctAnswer'] as String? ?? '').trim().toLowerCase();

    setState(() {
      _isChecked = true;
      _isCorrect = selectedOption == correctAnswer;
    });
  }

  void _onNextQuest() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _selectedOptionIndex = null;
        _isChecked = false;
        _isCorrect = false;
      });
    }
  }

  void _handleSubmit() {
    if (!_isChecked) {
      _onCheck();
    } else {
      if (_questIndex < _quests.length - 1) {
        _onNextQuest();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_questIndex];

    final badge = currentQuest['strategyBadge'] as String? ??
        'TARGET EXTRACTION GYM';
    final instruction = currentQuest['instruction'] as String? ??
        'Scan the passage to find the target information.';
    final passage = currentQuest['passage'] as String? ?? '';
    final options =
        (currentQuest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer =
        (currentQuest['correctAnswer'] as String? ?? '').trim();
    final targetInfo = currentQuest['targetInfo'] as String? ?? 'Target Entity';
    final explanation = currentQuest['explanation'] as String? ?? '';

    final hasNext = _questIndex < _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Target Extraction Gym',
      gameType: 'skimmingScanning',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _handleSubmit,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strategy Badge & Gym Header
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.indigo50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.indigo500.withValues(alpha: 0.3)
                      : AppColors.indigo500.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'QUESTION ${_questIndex + 1} OF ${_quests.length}',
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
            ),

            SizedBox(height: 14.h),

            // Instruction
            Text(
              instruction,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.slate900,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),

            SizedBox(height: 14.h),

            // Target Objective Pill
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.violet500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.violet500,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'TARGET: $targetInfo',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.violet500
                            : AppColors.indigo600,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Passage Scan Box
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.slate800
                      : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                        Icons.document_scanner_rounded,
                        color: AppColors.indigo500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'PASSAGE TO SCAN',
                          style: TextStyle(
                            color: AppColors.indigo500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Options Selection List
            Text(
              'EXTRACT THE TARGET ITEM',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...options.asMap().entries.map((entry) {
              final idx = entry.key;
              final optText = entry.value;
              final isSelected = _selectedOptionIndex == idx;
              final isOptCorrect =
                  optText.trim().toLowerCase() == correctAnswer.toLowerCase();

              Color borderColor = isDark
                  ? AppColors.slate800
                  : AppColors.slate200;
              Color cardBg = isDark ? AppColors.slate900 : Colors.white;

              if (_isChecked) {
                if (isOptCorrect) {
                  borderColor = AppColors.emerald500;
                  cardBg = isDark
                      ? AppColors.emerald950.withValues(alpha: 0.3)
                      : AppColors.emerald50;
                } else if (isSelected && !isOptCorrect) {
                  borderColor = AppColors.rose500;
                  cardBg = isDark
                      ? AppColors.red900.withValues(alpha: 0.25)
                      : AppColors.red50;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                cardBg = isDark
                    ? AppColors.indigo950.withValues(alpha: 0.3)
                    : AppColors.indigo50;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onOptionSelected(idx),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isOptCorrect)
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (_isChecked
                                      ? (isOptCorrect
                                          ? AppColors.emerald500
                                          : AppColors.rose500)
                                      : AppColors.indigo500)
                                  : (isDark
                                      ? AppColors.slate800
                                      : AppColors.slate100),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.slate300
                                          : AppColors.slate700),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              optText,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_isChecked) ...[
                            if (isOptCorrect)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.emerald500,
                                size: 20.sp,
                              )
                            else if (isSelected && !isOptCorrect)
                              Icon(
                                Icons.cancel_rounded,
                                color: AppColors.rose500,
                                size: 20.sp,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            SizedBox(height: 16.h),

            // Check Button (if not checked)
            if (!_isChecked)
              ElevatedButton(
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  disabledBackgroundColor: isDark
                      ? AppColors.slate800
                      : AppColors.slate200,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'CHECK SELECTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            // Result Feedback Box
            if (_isChecked) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? (isDark
                          ? AppColors.emerald950.withValues(alpha: 0.3)
                          : AppColors.emerald50)
                      : (isDark
                          ? AppColors.red900.withValues(alpha: 0.25)
                          : AppColors.red50),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500
                        : AppColors.rose500,
                    width: 1.5,
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
                              : Icons.warning_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'TARGET EXTRACTION SUCCESSFUL!'
                                : 'TARGET MISMATCH',
                            style: TextStyle(
                              color: _isCorrect
                                  ? (isDark
                                      ? AppColors.emerald400
                                      : AppColors.emerald600)
                                  : (isDark
                                      ? AppColors.rose500
                                      : AppColors.rose700),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation.isNotEmpty
                          ? explanation
                          : (_isCorrect
                              ? 'Target entity was correctly identified from the passage.'
                              : 'The selected option does not match the requested target.'),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate900,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _onNextQuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCorrect
                      ? AppColors.emerald600
                      : AppColors.indigo500,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  hasNext ? 'NEXT QUESTION' : 'COMPLETE PRACTICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
}
