import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Data model representing a grammar quest practice exercise.
class GrammarQuestPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String sentence;
  final String targetWord;
  final List<String> options;
  final String correctAnswer;
  final String hint;
  final String explanation;
  final String grammarRule;

  const GrammarQuestPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.sentence,
    required this.targetWord,
    required this.options,
    required this.correctAnswer,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
  });

  factory GrammarQuestPracticeQuest.fromJson(Map<String, dynamic> json) {
    return GrammarQuestPracticeQuest(
      id: json['id'] as String? ?? 'gq_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ?? 'Choose what fits',
      sentence: json['sentence'] as String? ?? '',
      targetWord: json['targetWord'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      grammarRule: json['grammarRule'] as String? ?? 'Rule',
    );
  }
}

/// Interactive Practice Phase screen for Grammar Quest: "Rule Completion Gym".
///
/// Provides sentence completion, instant validation, immediate feedback,
/// audible playback, and dynamic hint revelations.
class GrammarQuestPracticeScreen extends StatefulWidget {
  final int level;

  const GrammarQuestPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<GrammarQuestPracticeScreen> createState() =>
      _GrammarQuestPracticeScreenState();
}

class _GrammarQuestPracticeScreenState
    extends State<GrammarQuestPracticeScreen> {
  List<GrammarQuestPracticeQuest> _quests = const [
    GrammarQuestPracticeQuest(
      id: 'FALLBACK_GQ_P1',
      level: 1,
      instruction: 'CHOOSE WHAT FITS',
      sentence: 'I ___ from Brazil.',
      targetWord: 'am',
      options: ['am', 'is', 'are', 'be'],
      correctAnswer: 'am',
      hint: "There is only one form of 'be' that ever goes with 'I'.",
      explanation:
          "'I' always takes 'am'. It never changes, no matter what comes after it: I am from Brazil, I am tired, I am here.",
      grammarRule: "Verb 'To Be': Present Tense with I",
    ),
    GrammarQuestPracticeQuest(
      id: 'FALLBACK_GQ_P2',
      level: 1,
      instruction: 'COMPLETE THE THOUGHT',
      sentence: 'My brother ___ a doctor.',
      targetWord: 'is',
      options: ['be', 'am', 'is', 'are'],
      correctAnswer: 'is',
      hint: "'My brother' means 'he'. Which form of 'be' matches he/she/it?",
      explanation:
          "'My brother' can be replaced with 'he', and 'he/she/it' always takes 'is'. Compare: My sister is a nurse. The dog is friendly.",
      grammarRule: "Verb 'To Be': Third-Person Singular",
    ),
    GrammarQuestPracticeQuest(
      id: 'FALLBACK_GQ_P3',
      level: 1,
      instruction: 'COMPLETE THE MESSAGE',
      sentence: 'Yes, they ___ home now.',
      targetWord: 'are',
      options: ['is', 'are', 'am', 'be'],
      correctAnswer: 'are',
      hint: "'They' is plural, like 'we' and 'you'.",
      explanation:
          "Plural subjects such as 'they', 'we', and 'you' all take 'are'. Only 'he/she/it' takes 'is', and only 'I' takes 'am'.",
      grammarRule: "Verb 'To Be': Plural Subjects",
    ),
  ];

  int _currentIndex = 0;
  String? _selectedOption;
  bool? _isCorrect;
  bool _showHint = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final startLevel = ((widget.level - 1) ~/ 10) * 10 + 1;
      final endLevel = startLevel + 9;
      final batchFile =
          'assets/curriculum/grammar/grammarQuest_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => GrammarQuestPracticeQuest.fromJson(
              Map<String, dynamic>.from(q as Map)))
          .where((q) => q.level == widget.level)
          .toList();

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _quests = loaded;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Gracefully fall back to pre-seeded static quests
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _speakText(String text) {
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _onOptionSelected(String option) {
    if (_isCorrect == true) return;

    final quest = _quests[_currentIndex];
    final isMatch =
        option.trim().toLowerCase() == quest.correctAnswer.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isCorrect = isMatch;
    });

    if (isMatch) {
      _speakText(quest.sentence.replaceAll('___', quest.correctAnswer));
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isCorrect = null;
        _showHint = false;
      });
    } else {
      _onComplete();
    }
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'grammarQuest',
      level: widget.level,
      phase: 'practice',
    );
    final targetMastery =
        '/game?category=grammar&gameType=grammarQuest&level=${widget.level}';
    context.pushReplacement(targetMastery);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet500),
        ),
      );
    }

    final quest = _quests[_currentIndex];

    // Build sentence preview with selected or blank token
    final displaySentence = _selectedOption != null
        ? quest.sentence.replaceAll('___', '[ ${_selectedOption!} ]')
        : quest.sentence;

    return PracticePhaseScaffold(
      title: 'Rule Completion Gym',
      gameType: 'grammarQuest',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT EXERCISE'
          : 'READY FOR MASTERY →',
      isActionEnabled: _isCorrect == true,
      onHint: () => setState(() => _showHint = true),
      isHintAvailable: !_showHint && _isCorrect != true,
      onComplete: () {
        if (_currentIndex < _quests.length - 1) {
          _onNext();
        } else {
          _onComplete();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Rule badge & Exercise counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.grammarRule.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Exercise ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Instruction Banner
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.slate800),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.rule_rounded,
                    color: AppColors.violet500,
                    size: 22.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      quest.instruction,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Sentence Card
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _isCorrect == true
                      ? AppColors.emerald500
                      : (_isCorrect == false
                          ? AppColors.rose500
                          : AppColors.slate800),
                  width: _isCorrect != null ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SENTENCE PROMPT',
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.violet500,
                          size: 20.r,
                        ),
                        onPressed: () => _speakText(
                          quest.sentence.replaceAll('___', quest.correctAnswer),
                        ),
                        tooltip: 'Hear sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    displaySentence,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Options Grid / List
            Text(
              'SELECT THE CORRECT OPTION',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...quest.options.map((option) {
              final isSelected = _selectedOption == option;
              final isTarget = option.trim().toLowerCase() ==
                  quest.correctAnswer.trim().toLowerCase();

              Color optBg = AppColors.slate900;
              Color optBorder = AppColors.slate800;
              Color optText = Colors.white;

              if (isSelected) {
                if (_isCorrect == true) {
                  optBg = AppColors.emerald500.withValues(alpha: 0.2);
                  optBorder = AppColors.emerald500;
                  optText = AppColors.emerald400;
                } else if (_isCorrect == false) {
                  optBg = AppColors.rose500.withValues(alpha: 0.2);
                  optBorder = AppColors.rose500;
                  optText = AppColors.rose500;
                }
              } else if (_isCorrect == true && isTarget) {
                optBg = AppColors.emerald500.withValues(alpha: 0.2);
                optBorder = AppColors.emerald500;
                optText = AppColors.emerald400;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: optBg,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    onTap: () => _onOptionSelected(option),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: optBorder, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              color: optText,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isSelected && _isCorrect == true)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.emerald500,
                              size: 20.r,
                            )
                          else if (isSelected && _isCorrect == false)
                            Icon(
                              Icons.cancel_rounded,
                              color: AppColors.rose500,
                              size: 20.r,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Immediate Feedback Card
            if (_isCorrect == true) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald400,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        quest.explanation,
                        style: TextStyle(
                          color: AppColors.emerald400,
                          fontSize: 13.sp,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_isCorrect == false) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel_rounded,
                      color: AppColors.rose500,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Not quite right. Try another option!',
                        style: TextStyle(
                          color: AppColors.rose500,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Hint Card
            if (_showHint) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          color: AppColors.amber400,
                          fontSize: 12.sp,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
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
