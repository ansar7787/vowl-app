import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

/// Data model representing a read-and-answer practice exercise.
class ReadAndAnswerPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String passageTopic;
  final String passage;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String evidenceLine;
  final String hint;
  final String explanation;
  final int passageWordCount;

  const ReadAndAnswerPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.passageTopic,
    required this.passage,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.evidenceLine,
    required this.hint,
    required this.explanation,
    required this.passageWordCount,
  });

  factory ReadAndAnswerPracticeQuest.fromJson(Map<String, dynamic> json) {
    final passage = json['passage'] as String? ??
        'The library is open from 9 a.m. to 6 p.m. on weekdays. On Saturday it closes at noon. It is closed on Sunday.';
    final topic = json['passageTopic'] as String? ?? 'Library Notice';
    final answer = json['correctAnswer'] as String? ?? 'At noon';
    final optionsList = (json['options'] as List<dynamic>? ?? [answer])
        .map((e) => e.toString())
        .toList();

    return ReadAndAnswerPracticeQuest(
      id: json['id'] as String? ?? 'RDG_PRACTICE_DEFAULT',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Read the passage and select the correct answer.',
      passageTopic: topic,
      passage: passage,
      question: json['question'] as String? ??
          'At what time does the library close on Saturday?',
      options: optionsList,
      correctAnswer: answer,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      evidenceLine: json['evidenceLine'] as String? ??
          'On Saturday it closes at noon',
      hint: json['hint'] as String? ??
          'Weekdays and Saturday have different closing times, so read the second sentence closely.',
      explanation: json['explanation'] as String? ??
          'The notice gives Saturday its own shorter day: the library closes at noon, much earlier than the 6 p.m. weekday closing.',
      passageWordCount: json['passageWordCount'] as int? ?? 25,
    );
  }
}

/// Interactive Practice Phase screen for Read & Answer: "Paragraph-by-Paragraph Check Gym".
///
/// Features authentic reading passage, interactive comprehension options,
/// dynamic evidence line highlighting, rationale discovery, and auditory feedback.
class ReadAndAnswerPracticeScreen extends StatefulWidget {
  final int level;

  const ReadAndAnswerPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadAndAnswerPracticeScreen> createState() =>
      _ReadAndAnswerPracticeScreenState();
}

class _ReadAndAnswerPracticeScreenState
    extends State<ReadAndAnswerPracticeScreen> {
  List<ReadAndAnswerPracticeQuest> _quests = const [
    ReadAndAnswerPracticeQuest(
      id: 'FALLBACK_RAA_P1',
      level: 1,
      instruction: 'Read the passage and select the correct answer.',
      passageTopic: 'Library Notice',
      passage:
          'The library is open from 9 a.m. to 6 p.m. on weekdays. On Saturday it closes at noon. It is closed on Sunday.',
      question: 'At what time does the library close on Saturday?',
      options: [
        'At noon',
        'At 6 p.m.',
        'At 9 a.m.',
        'At 5 p.m.',
      ],
      correctAnswer: 'At noon',
      correctAnswerIndex: 0,
      evidenceLine: 'On Saturday it closes at noon',
      hint:
          'Weekdays and Saturday have different closing times, so read the second sentence closely.',
      explanation:
          'The notice gives Saturday its own shorter day: the library closes at noon, much earlier than the 6 p.m. weekday closing.',
      passageWordCount: 25,
    ),
  ];

  int _currentIndex = 0;
  int _selectedOptionIndex = -1;
  bool _hasChecked = false;
  bool _isCorrect = false;
  bool _showHint = false;
  bool _isLoading = false;

  TtsService? _ttsService;
  SoundService? _soundService;
  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    try {
      if (di.sl.isRegistered<TtsService>()) {
        _ttsService = di.sl<TtsService>();
      }
      if (di.sl.isRegistered<SoundService>()) {
        _soundService = di.sl<SoundService>();
      }
      if (di.sl.isRegistered<HapticService>()) {
        _hapticService = di.sl<HapticService>();
      }
    } catch (_) {}
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/reading/readAndAnswer_practice_${startLevel}_$endLevel.json';

      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests
          .where((q) => (q['level'] as int? ?? startLevel) == widget.level)
          .map((q) => ReadAndAnswerPracticeQuest.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          } else if (rawQuests.isNotEmpty) {
            _quests = rawQuests
                .take(3)
                .map((q) => ReadAndAnswerPracticeQuest.fromJson(q))
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    _hapticService?.selection();
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == -1 || _hasChecked) return;

    final quest = _quests[_currentIndex];
    final selectedOption = quest.options[_selectedOptionIndex];
    final isCorrect = (selectedOption == quest.correctAnswer) ||
        (_selectedOptionIndex == quest.correctAnswerIndex);

    setState(() {
      _hasChecked = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      _soundService?.playCorrect();
      _hapticService?.success();
    } else {
      _soundService?.playWrong();
      _hapticService?.error();
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _ttsService?.speak(text);
    } catch (_) {}
  }

  void _nextExercise() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = -1;
        _hasChecked = false;
        _isCorrect = false;
        _showHint = false;
      });
    } else {
      _completePractice();
    }
  }

  Future<void> _completePractice() async {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'readAndAnswer',
      level: widget.level,
      phase: 'practice',
    );
    if (!mounted) return;
    context.pushReplacement(
      '/game?category=reading&gameType=readAndAnswer&level=${widget.level}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.slate950,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PracticePhaseScaffold(
      title: 'Paragraph-by-Paragraph Check',
      gameType: 'readAndAnswer',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _completePractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress tracker chip row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Question ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      color: AppColors.teal500,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.passageTopic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Reading Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.teal500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 14.r,
                                color: AppColors.teal500,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  'READING PASSAGE (${quest.passageWordCount} WORDS)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.teal500,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.teal500,
                          size: 20.r,
                        ),
                        onPressed: () => _speak(quest.passage),
                        tooltip: 'Listen to Passage',
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    quest.passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate950,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Question Prompt Box
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.amber500,
                    size: 22.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      quest.question,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate950,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Options List
            Column(
              children: List.generate(quest.options.length, (index) {
                final option = quest.options[index];
                final isSelected = _selectedOptionIndex == index;

                Color borderColor =
                    isDark ? AppColors.slate800 : AppColors.slate200;
                Color bgColor = isDark ? AppColors.slate900 : Colors.white;

                if (_hasChecked) {
                  final isOptionCorrect = (option == quest.correctAnswer) ||
                      (index == quest.correctAnswerIndex);
                  if (isOptionCorrect) {
                    borderColor = AppColors.teal500;
                    bgColor = AppColors.teal500.withValues(alpha: 0.15);
                  } else if (isSelected && !isOptionCorrect) {
                    borderColor = Colors.redAccent;
                    bgColor = Colors.redAccent.withValues(alpha: 0.12);
                  }
                } else if (isSelected) {
                  borderColor = AppColors.teal500;
                  bgColor = AppColors.teal500.withValues(alpha: 0.1);
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: InkWell(
                    onTap: () => _onOptionSelected(index),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_hasChecked && (option == quest.correctAnswer || index == quest.correctAnswerIndex)) ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28.r,
                            height: 28.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.teal500
                                  : (isDark
                                      ? AppColors.slate800
                                      : AppColors.slate100),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : AppColors.slate700),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white : AppColors.slate950,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 8.h),

            // Hint Button & Box
            if (!_hasChecked) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _showHint = !_showHint);
                    _hapticService?.selection();
                  },
                  icon: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.amber500,
                    size: 18.r,
                  ),
                  label: Text(
                    _showHint ? 'Hide Clue' : 'Need a reading clue?',
                    style: TextStyle(
                      color: AppColors.amber500,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_showHint) ...[
                Container(
                  margin: EdgeInsets.only(top: 4.h, bottom: 12.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    quest.hint,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.slate700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],

            // Explanation & Evidence Rationale upon check
            if (_hasChecked) ...[
              Container(
                margin: EdgeInsets.only(top: 8.h, bottom: 14.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.teal500.withValues(alpha: 0.12)
                      : Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.teal500.withValues(alpha: 0.4)
                        : Colors.redAccent.withValues(alpha: 0.4),
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
                          color:
                              _isCorrect ? AppColors.teal500 : Colors.redAccent,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'EVIDENCE VERIFIED!'
                                : 'MISMATCHED EVIDENCE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isCorrect
                                  ? AppColors.teal500
                                  : Colors.redAccent,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (quest.evidenceLine.isNotEmpty) ...[
                      Text(
                        'Supporting Text Quote: "${quest.evidenceLine}"',
                        style: TextStyle(
                          color: _isCorrect
                              ? AppColors.teal500
                              : Colors.redAccent,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 6.h),
                    ],
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate900,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 14.h),

            // Action Button (Check Answer / Continue)
            ElevatedButton(
              onPressed: _selectedOptionIndex == -1
                  ? null
                  : (!_hasChecked ? _checkAnswer : _nextExercise),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal500,
                disabledBackgroundColor:
                    isDark ? AppColors.slate800 : AppColors.slate200,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                !_hasChecked
                    ? 'CHECK ANSWER'
                    : (_currentIndex < _quests.length - 1
                        ? 'NEXT PASSAGE CHECK →'
                        : 'FINISH PRACTICE →'),
                style: TextStyle(
                  color: _selectedOptionIndex == -1
                      ? (isDark ? Colors.white30 : AppColors.slate400)
                      : Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
