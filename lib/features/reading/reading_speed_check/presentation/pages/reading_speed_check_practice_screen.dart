import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Practice phase screen for Reading Speed Check mini-game.
/// Provides a guided pacing gym measuring WPM and testing retention comprehension.
class ReadingSpeedCheckPracticeScreen extends StatefulWidget {
  final int level;

  const ReadingSpeedCheckPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadingSpeedCheckPracticeScreen> createState() =>
      _ReadingSpeedCheckPracticeScreenState();
}

class _ReadingSpeedCheckPracticeScreenState
    extends State<ReadingSpeedCheckPracticeScreen> {
  int _questIndex = 0;
  List<Map<String, dynamic>> _quests = [];
  bool _isLoading = true;

  bool _hasStoppedReading = false;
  int _elapsedSeconds = 0;
  Timer? _readingTimer;
  int _computedWpm = 0;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/reading/readingSpeedCheck_practice_${startLevel}_$endLevel.json';

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
          _quests = levelQuests.isNotEmpty ? levelQuests : rawQuests;
          _isLoading = false;
          _initQuest();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _fallbackQuests;
          _isLoading = false;
          _initQuest();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_READINGSPEEDCHECK_PRACTICE_FALLBACK_1',
          'level': widget.level,
          'instruction':
              'Read the passage at your target pace, then test your comprehension.',
          'passage':
              'Community pool: open Monday to Friday from 9 a.m. to 6 p.m. The pool is closed on Saturdays and Sundays.',
          'question': 'On which days is the pool closed?',
          'options': [
            'Only on Sunday',
            'Friday and Saturday',
            'Monday and Friday',
            'Saturday and Sunday',
          ],
          'correctAnswer': 'Saturday and Sunday',
          'timeLimit': 25,
          'wpmTarget': 90,
          'passageWordCount': 20,
          'explanation':
              'The second sentence gives the closing days. Reading for the word "closed" lets you skip the opening hours.',
          'hint': 'Look for which sentence talks about closing.',
        },
      ];

  void _initQuest() {
    _readingTimer?.cancel();
    _hasStoppedReading = false;
    _elapsedSeconds = 0;
    _computedWpm = 0;
    _selectedOptionIndex = null;
    _isChecked = false;
    _isCorrect = false;

    // Start live reading timer
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopReading(int wordCount) {
    _readingTimer?.cancel();
    final elapsedMin = (_elapsedSeconds > 0 ? _elapsedSeconds : 1) / 60.0;
    final wpm = (wordCount / elapsedMin).round();

    setState(() {
      _hasStoppedReading = true;
      _computedWpm = wpm > 0 ? wpm : wordCount * 6;
    });
  }

  void _selectOption(int index) {
    if (_isChecked && _isCorrect) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;
    final quest = _quests[_questIndex];
    final options =
        (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';

    final isRight = _selectedOptionIndex! < options.length &&
        options[_selectedOptionIndex!].trim().toLowerCase() ==
            correctAnswer.trim().toLowerCase();

    setState(() {
      _isChecked = true;
      _isCorrect = isRight;
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _initQuest();
      });
    } else {
      context.pushReplacement(
        '/game?category=reading&gameType=readingSpeedCheck&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Guided Pacing Gym',
        gameType: 'readingSpeedCheck',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: () {},
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final quest =
        _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests[0];
    final passage = quest['passage'] as String? ?? '';
    final question = quest['question'] as String? ?? '';
    final options =
        (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final wordCount = quest['passageWordCount'] as int? ?? 20;
    final wpmTarget = quest['wpmTarget'] as int? ?? 90;
    final explanation = quest['explanation'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final isLastQuest = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Guided Pacing Gym',
      gameType: 'readingSpeedCheck',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _hasStoppedReading
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _hasStoppedReading
                            ? AppColors.emerald500.withValues(alpha: 0.4)
                            : AppColors.teal500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _hasStoppedReading
                          ? 'WPM: $_computedWpm (TARGET: $wpmTarget)'
                          : 'READING TIME: ${_elapsedSeconds}s',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _hasStoppedReading
                            ? AppColors.emerald400
                            : AppColors.teal400,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Quest ${_questIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Timed Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'PASSAGE ($wordCount WORDS)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.teal400,
                          ),
                        ),
                      ),
                      if (!_hasStoppedReading)
                        GestureDetector(
                          onTap: () => _stopReading(wordCount),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.rose500.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: AppColors.rose500),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stop_rounded,
                                    size: 14.r, color: AppColors.rose500),
                                SizedBox(width: 4.w),
                                Text(
                                  'DONE READING',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.rose500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    passage,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.5.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Step 2: Comprehension Check (Revealed after reading)
            if (_hasStoppedReading) ...[
              // Question Header
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.slate700),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.indigo400,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // Option Tiles
              ...List.generate(options.length, (idx) {
                final isSelected = _selectedOptionIndex == idx;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: GestureDetector(
                    onTap: () => _selectOption(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indigo500.withValues(alpha: 0.2)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.indigo400
                              : AppColors.slate700,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.r,
                            height: 24.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.indigo500
                                  : AppColors.slate800,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              options[idx],
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.slate200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: 10.h),

              // Feedback Card
              if (_isChecked) ...[
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _isCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500,
                        size: 22.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCorrect
                                  ? 'SPEED & RETENTION VERIFIED! ($_computedWpm WPM)'
                                  : 'COMPREHENSION CHECK FAILED',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: _isCorrect
                                    ? AppColors.emerald500
                                    : AppColors.rose500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _isCorrect
                                  ? explanation
                                  : (hint.isNotEmpty
                                      ? hint
                                      : 'Re-read the relevant section carefully.'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5.sp,
                                height: 1.4,
                                color: AppColors.slate300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
              ],

              // Action Check/Next Button
              ElevatedButton(
                onPressed: _isChecked
                    ? (_isCorrect ? _onNext : _checkAnswer)
                    : _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCorrect
                      ? AppColors.emerald500
                      : AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isChecked
                      ? (_isCorrect
                          ? (isLastQuest
                              ? 'Complete Gym & Enter Mastery'
                              : 'Next Quest')
                          : 'Re-Check Answer')
                      : 'Check Answer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ] else ...[
              // Prompt to tap done reading
              ElevatedButton(
                onPressed: () => _stopReading(wordCount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'I Have Finished Reading',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
    );
  }
}
