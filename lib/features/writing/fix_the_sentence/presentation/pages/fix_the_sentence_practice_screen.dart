import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Fix The Sentence ("Typo & Error Surgeon Gym").
///
/// Prompts learners to diagnose sentence flaws and apply the correct grammatical
/// replacement from a curated surgical word bank.
class FixTheSentencePracticeScreen extends StatefulWidget {
  final int level;

  const FixTheSentencePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<FixTheSentencePracticeScreen> createState() =>
      _FixTheSentencePracticeScreenState();
}

class _FixTheSentencePracticeScreenState
    extends State<FixTheSentencePracticeScreen> {
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
        'assets/curriculum/writing/fixTheSentence_practice_${startLevel}_$endLevel.json';

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
          'id': 'WRT_FIXTHESENTENCE_PRAC_FALLBACK_1',
          'instruction': 'SELECT THE PRECISE GRAMMATICAL FIX',
          'passage': 'My cousin play football at the park every Sunday.',
          'missingWord': 'play',
          'options': ['play', 'to play', 'playing', 'plays'],
          'correctAnswer': 'plays',
          'errorType': 'Agreement Error',
          'hint': 'Check how many people the subject names and ensure third-person agreement.',
          'explanation':
              'One person is doing the action in the habitual present, requiring third-person singular "plays".',
        },
        {
          'id': 'WRT_FIXTHESENTENCE_PRAC_FALLBACK_2',
          'instruction': 'SELECT THE PRECISE GRAMMATICAL FIX',
          'passage': 'The bus to the airport leave from Gate 4 every twenty minutes.',
          'missingWord': 'leave',
          'options': ['leaves', 'to leave', 'leave', 'leaving'],
          'correctAnswer': 'leaves',
          'errorType': 'Agreement Error',
          'hint': 'Determine if "the bus" is singular or plural to select the verb suffix.',
          'explanation':
              '"The bus" is singular and requires the -s verb form "leaves".',
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
          gameType: 'fixTheSentence',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=writing&gameType=fixTheSentence&level=${widget.level}',
        );
      }
      return;
    }

    if (_selectedOptionIndex == null) return;

    final quest = _quests[_questIndex];
    final options = _resolveOptions(quest);
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final selectedOption = options[_selectedOptionIndex!];
    final isCorrect = selectedOption.trim() == correctAnswer.trim();

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrect;
    });
  }

  void _showHint() {
    final quest = _quests[_questIndex];
    final hint = quest['hint'] as String? ??
        'Analyze the subject and tense to select the correct verb or grammatical form.';

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
                    'Surgeon\'s Hint',
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
    final correctAnswer = quest['correctAnswer'] as String? ?? 'correct';
    final missingWord = quest['missingWord'] as String? ?? 'wrong';
    return [missingWord, 'to $correctAnswer', '${correctAnswer}ing', correctAnswer];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];
    final passage = quest['passage'] as String? ?? '';
    final missingWord = quest['missingWord'] as String? ?? '';
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final errorType = quest['errorType'] as String? ?? 'Grammar Error';
    final options = _resolveOptions(quest);
    final explanation = quest['explanation'] as String? ?? '';

    String buttonLabel = 'Check Surgical Fix';
    if (_isChecked) {
      buttonLabel = _questIndex == _quests.length - 1
          ? 'Enter Mastery Game'
          : 'Next Sentence';
    }

    return PracticePhaseScaffold(
      title: 'Typo & Error Surgeon Gym',
      gameType: 'fixTheSentence',
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
            // Stimulus Card with Error Spotlight
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          errorType.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'TARGET FOR REPAIR',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  RichText(
                    text: TextSpan(
                      children: _buildPassageSpans(
                        passage,
                        missingWord,
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Prompt Question
            Text(
              'SELECT THE CORRECT REPLACEMENT WORD:',
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
              final isThisOptionCorrect = optionText.trim() == correctAnswer.trim();

              Color borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
              Color bgColor = isDark ? AppColors.slate900 : Colors.white;

              if (_isChecked) {
                if (isThisOptionCorrect) {
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
                        width: isSelected || (_isChecked && isThisOptionCorrect)
                            ? 2.0
                            : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22.r,
                          height: 22.r,
                          margin: EdgeInsets.only(right: 12.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (_isChecked
                                    ? (isThisOptionCorrect
                                        ? AppColors.emerald500
                                        : AppColors.rose500)
                                    : AppColors.indigo500)
                                : (_isChecked && isThisOptionCorrect
                                    ? AppColors.emerald500
                                    : Colors.transparent),
                            border: Border.all(
                              color: isSelected || (_isChecked && isThisOptionCorrect)
                                  ? Colors.transparent
                                  : (isDark
                                      ? AppColors.slate700
                                      : AppColors.slate300),
                              width: 1.5,
                            ),
                          ),
                          child: (isSelected || (_isChecked && isThisOptionCorrect))
                              ? Icon(
                                  _isChecked
                                      ? (isThisOptionCorrect
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
                              fontSize: 15.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? AppColors.slate100 : AppColors.slate900,
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
                            _isCorrect ? 'Repair Successful!' : 'Incorrect Substitution',
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
                      explanation,
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

  List<TextSpan> _buildPassageSpans(
    String passage,
    String missingWord,
    bool isDark,
  ) {
    if (missingWord.isEmpty || !passage.contains(missingWord)) {
      return [
        TextSpan(
          text: passage,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.slate100 : AppColors.slate900,
            height: 1.45,
          ),
        ),
      ];
    }

    final index = passage.indexOf(missingWord);
    final before = passage.substring(0, index);
    final after = passage.substring(index + missingWord.length);

    return [
      TextSpan(
        text: before,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.slate100 : AppColors.slate900,
          height: 1.45,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.rose500.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: AppColors.rose500,
              width: 1.5,
            ),
          ),
          child: Text(
            missingWord,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.rose500,
            ),
          ),
        ),
      ),
      TextSpan(
        text: after,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.slate100 : AppColors.slate900,
          height: 1.45,
        ),
      ),
    ];
  }
}

