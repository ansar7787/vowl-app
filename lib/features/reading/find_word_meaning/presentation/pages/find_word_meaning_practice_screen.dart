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

/// Data model representing a Find Word Meaning deduction practice exercise.
class FindWordMeaningPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String passage;
  final String maskedPassage;
  final String targetWord;
  final String clueType;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;

  const FindWordMeaningPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.passage,
    required this.maskedPassage,
    required this.targetWord,
    required this.clueType,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
  });

  factory FindWordMeaningPracticeQuest.fromJson(Map<String, dynamic> json) {
    final passage = json['passage'] as String? ??
        'Maria felt happy all through dinner because her brother was finally coming home for the weekend.';
    final target = json['targetWord'] as String? ?? 'happy';
    final masked = json['maskedPassage'] as String? ??
        passage.replaceAll(target, '[ ????? ]');
    final answer = json['correctAnswer'] as String? ?? 'feeling pleased or glad';
    final optionsList = (json['options'] as List<dynamic>? ?? [answer])
        .map((e) => e.toString())
        .toList();

    return FindWordMeaningPracticeQuest(
      id: json['id'] as String? ?? 'RDG_FWM_PRACTICE_DEFAULT',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Deduce the meaning of the masked word from context clues:',
      passage: passage,
      maskedPassage: masked,
      targetWord: target,
      clueType: json['clueType'] as String? ?? 'Inference Clue',
      question: json['question'] as String? ??
          'What does the masked word mean in this context?',
      options: optionsList,
      correctAnswer: answer,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      hint: json['hint'] as String? ??
          'Look at how Maria is feeling about her brother\'s visit.',
      explanation: json['explanation'] as String? ??
          'Maria feels happy because her brother is finally coming home for the weekend.',
    );
  }
}

/// Interactive Practice Phase screen for Find Word Meaning: "Deduction Sandbox Gym".
///
/// Features target-word masked passages, surrounding context clues analysis,
/// meaning deduction options, immediate interactive feedback, and audio guidance.
class FindWordMeaningPracticeScreen extends StatefulWidget {
  final int level;

  const FindWordMeaningPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<FindWordMeaningPracticeScreen> createState() =>
      _FindWordMeaningPracticeScreenState();
}

class _FindWordMeaningPracticeScreenState
    extends State<FindWordMeaningPracticeScreen> {
  List<FindWordMeaningPracticeQuest> _quests = const [
    FindWordMeaningPracticeQuest(
      id: 'FALLBACK_FWM_P1',
      level: 1,
      instruction: 'Deduce the meaning of the masked word from context clues:',
      passage:
          'Maria felt happy all through dinner because her brother was finally coming home for the weekend.',
      maskedPassage:
          'Maria felt [ ????? ] all through dinner because her brother was finally coming home for the weekend.',
      targetWord: 'happy',
      clueType: 'Inference Clue',
      question: 'What does the masked word mean in this context?',
      options: [
        'feeling pleased or glad',
        'hard to do or understand',
        'having a lot to do at one time',
        'feeling cold and uncomfortable',
      ],
      correctAnswer: 'feeling pleased or glad',
      correctAnswerIndex: 0,
      hint: 'Look at how Maria is feeling about her brother\'s visit.',
      explanation:
          'Maria feels happy because her brother is finally coming home for the weekend.',
    ),
    FindWordMeaningPracticeQuest(
      id: 'FALLBACK_FWM_P2',
      level: 1,
      instruction: 'Deduce the meaning of the masked word from context clues:',
      passage:
          'The last question on the test was so difficult that half the class left it blank.',
      maskedPassage:
          'The last question on the test was so [ ????? ] that half the class left it blank.',
      targetWord: 'difficult',
      clueType: 'Definition Clue',
      question: 'What does the masked word mean in this context?',
      options: [
        'extremely colorful and bright',
        'hard to do or understand',
        'quick and effortless to finish',
        'written in very small letters',
      ],
      correctAnswer: 'hard to do or understand',
      correctAnswerIndex: 1,
      hint: 'Notice what the students did — half the class left it blank.',
      explanation:
          'Students left it blank because the question was hard and required too much effort.',
    ),
  ];

  int _currentIndex = 0;
  int _selectedOptionIndex = -1;
  bool _hasChecked = false;
  bool _isCorrect = false;
  bool _showHint = false;
  bool _isLoading = false;

  HapticService? _hapticService;
  SoundService? _soundService;
  TtsService? _ttsService;

  @override
  void initState() {
    super.initState();
    try {
      if (di.sl.isRegistered<HapticService>()) {
        _hapticService = di.sl<HapticService>();
      }
      if (di.sl.isRegistered<SoundService>()) {
        _soundService = di.sl<SoundService>();
      }
      if (di.sl.isRegistered<TtsService>()) {
        _ttsService = di.sl<TtsService>();
      }
    } catch (_) {}
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/reading/findWordMeaning_practice_${startLevel}_$endLevel.json';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final questsRaw = data['quests'] as List<dynamic>? ?? [];

      final loadedQuests = questsRaw
          .whereType<Map<String, dynamic>>()
          .map((q) => FindWordMeaningPracticeQuest.fromJson(q))
          .where((q) => q.level == widget.level)
          .toList();

      if (loadedQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = loadedQuests;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallbacks remain active
    }
  }

  void _selectOption(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    _hapticService?.selection();
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == -1 || _hasChecked) return;

    final quest = _quests[_currentIndex];
    final selectedText = quest.options[_selectedOptionIndex];
    final isRight = selectedText.trim().toLowerCase() ==
        quest.correctAnswer.trim().toLowerCase();

    setState(() {
      _hasChecked = true;
      _isCorrect = isRight;
      if (isRight) {
        _soundService?.playCorrect();
        _hapticService?.success();
      } else {
        _soundService?.playWrong();
        _hapticService?.error();
      }
    });
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

  void _completePractice() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'findWordMeaning',
      level: widget.level,
      phase: 'practice',
    );

    context.pushReplacement(
      '/game?category=reading&gameType=findWordMeaning&level=${widget.level}',
    );
  }

  Color _getClueColor(String clueType) {
    if (clueType.contains('Definition')) {
      return const Color(0xFF38BDF8);
    } else if (clueType.contains('Synonym')) {
      return const Color(0xFF34D399);
    } else if (clueType.contains('Contrast')) {
      return const Color(0xFFF472B6);
    } else {
      return const Color(0xFFA78BFA);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.slate950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_currentIndex];
    final clueColor = _getClueColor(quest.clueType);

    return PracticePhaseScaffold(
      title: 'Deduction Sandbox',
      gameType: 'findWordMeaning',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _completePractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Clue Type Pill & Score
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: clueColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: clueColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, size: 13.sp, color: clueColor),
                      SizedBox(width: 4.w),
                      Text(
                        quest.clueType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: clueColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Quest ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _showHint ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                    color: _showHint ? const Color(0xFFFBBF24) : (isDark ? Colors.white60 : Colors.black45),
                    size: 18.sp,
                  ),
                  tooltip: 'Context Clue Hint',
                  onPressed: () {
                    setState(() {
                      _showHint = !_showHint;
                    });
                    _hapticService?.selection();
                  },
                ),
                if (_ttsService != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.volume_up_rounded,
                        color: isDark ? Colors.white60 : Colors.black45, size: 18.sp),
                    tooltip: 'Listen to passage',
                    onPressed: () => _ttsService?.speak(quest.passage),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // 2. Hint Banner (if toggled)
            if (_showHint) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_rounded,
                        color: const Color(0xFFFBBF24), size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 3. Masked Sentence / Passage Sandbox Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.psychology_rounded, color: clueColor, size: 16.sp),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                'CONTEXT PASSAGE',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasChecked)
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: const Color(0xFF34D399), size: 14.sp),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    quest.targetWord,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF34D399),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildPassageWidget(quest, clueColor, isDark),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 4. Question Prompt
            Text(
              quest.question,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 10.h),

            // 5. Options
            ...List.generate(quest.options.length, (index) {
              final optionText = quest.options[index];
              return _buildOptionTile(
                optionText: optionText,
                index: index,
                quest: quest,
                isDark: isDark,
              );
            }),

            // 6. Rationale / Explanation Card (after checked)
            if (_hasChecked) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? const Color(0xFF34D399).withValues(alpha: 0.12)
                      : const Color(0xFFF87171).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? const Color(0xFF34D399).withValues(alpha: 0.4)
                        : const Color(0xFFF87171).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: _isCorrect ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _isCorrect ? 'EXCELLENT DEDUCTION!' : 'CONTEXT CLUE INSIGHT',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: _isCorrect ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),

            // 7. Action Button (Check Answer / Continue)
            ElevatedButton(
              onPressed: _selectedOptionIndex == -1
                  ? null
                  : (!_hasChecked ? _checkAnswer : _nextExercise),
              style: ElevatedButton.styleFrom(
                backgroundColor: clueColor,
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
                        ? 'NEXT QUESTION →'
                        : 'FINISH PRACTICE →'),
                style: TextStyle(
                  color: _selectedOptionIndex == -1
                      ? (isDark ? Colors.white30 : AppColors.slate400)
                      : Colors.black87,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPassageWidget(
    FindWordMeaningPracticeQuest quest,
    Color clueColor,
    bool isDark,
  ) {
    if (_hasChecked) {
      // Show full passage with revealed target word highlighted
      final lowerPassage = quest.passage.toLowerCase();
      final lowerTarget = quest.targetWord.toLowerCase();
      final index = lowerPassage.indexOf(lowerTarget);

      if (index == -1) {
        return Text(
          quest.passage,
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        );
      }

      final before = quest.passage.substring(0, index);
      final match = quest.passage.substring(index, index + quest.targetWord.length);
      final after = quest.passage.substring(index + quest.targetWord.length);

      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
          children: [
            TextSpan(text: before),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                ),
                child: Text(
                  match,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ),
            ),
            TextSpan(text: after),
          ],
        ),
      );
    } else {
      // Show masked passage with glowing slot
      final masked = quest.maskedPassage;
      const slotToken = '[ ????? ]';

      if (!masked.contains(slotToken)) {
        return Text(
          masked,
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        );
      }

      final parts = masked.split(slotToken);

      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
          children: [
            TextSpan(text: parts[0]),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: clueColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: clueColor, width: 1.5),
                ),
                child: Text(
                  '[ ????? ]',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: clueColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    }
  }

  Widget _buildOptionTile({
    required String optionText,
    required int index,
    required FindWordMeaningPracticeQuest quest,
    required bool isDark,
  }) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrectOption = optionText.trim().toLowerCase() ==
        quest.correctAnswer.trim().toLowerCase();

    Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = isDark ? Colors.white : Colors.black87;
    Widget trailingIcon = const SizedBox.shrink();

    if (_hasChecked) {
      if (isCorrectOption) {
        bgColor = const Color(0xFF34D399).withValues(alpha: 0.15);
        borderColor = const Color(0xFF34D399);
        textColor = const Color(0xFF34D399);
        trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399));
      } else if (isSelected) {
        bgColor = const Color(0xFFF87171).withValues(alpha: 0.15);
        borderColor = const Color(0xFFF87171);
        textColor = const Color(0xFFF87171);
        trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFF87171));
      }
    } else if (isSelected) {
      bgColor = AppColors.indigo500.withValues(alpha: 0.15);
      borderColor = AppColors.indigo500;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => _selectOption(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: borderColor,
                width: isSelected || (_hasChecked && isCorrectOption) ? 1.8 : 1.0,
              ),
              boxShadow: [
                if (!_hasChecked)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
                trailingIcon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
