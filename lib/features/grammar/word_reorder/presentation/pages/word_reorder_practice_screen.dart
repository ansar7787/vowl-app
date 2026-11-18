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

/// Data model representing a word reorder practice challenge.
class WordReorderPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String targetSentence;
  final List<String> shuffledWords;
  final List<int> correctOrder;
  final String hint;
  final String explanation;
  final String grammarRule;
  final String structureType;

  const WordReorderPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.targetSentence,
    required this.shuffledWords,
    required this.correctOrder,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.structureType,
  });

  factory WordReorderPracticeQuest.fromJson(Map<String, dynamic> json) {
    return WordReorderPracticeQuest(
      id: json['id'] as String? ?? 'wr_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Tap the words in the correct grammatical order',
      targetSentence: json['targetSentence'] as String? ?? '',
      shuffledWords: (json['shuffledWords'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctOrder: (json['correctOrder'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      hint: json['hint'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      grammarRule: json['grammarRule'] as String? ?? 'Syntax & Word Order',
      structureType: json['structureType'] as String? ?? 'S-V-O',
    );
  }
}

/// Interactive Practice Phase screen for Word Reorder: "Scaffolded Block Stacker Gym".
///
/// Features interactive tap-to-assemble sentence slots, dynamic chip pooling,
/// instant order validation, hint revelation, and speech synthesis feedback.
class WordReorderPracticeScreen extends StatefulWidget {
  final int level;

  const WordReorderPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<WordReorderPracticeScreen> createState() =>
      _WordReorderPracticeScreenState();
}

class _WordReorderPracticeScreenState extends State<WordReorderPracticeScreen> {
  List<WordReorderPracticeQuest> _quests = const [
    WordReorderPracticeQuest(
      id: 'FALLBACK_WR_P1',
      level: 1,
      instruction: 'Tap the words in the correct grammatical order',
      targetSentence: 'The students laugh.',
      shuffledWords: ['students', 'The', 'laugh.'],
      correctOrder: [1, 0, 2],
      hint: 'Find who is doing the laughing, and place that before the action word.',
      explanation:
          "English statements begin with the subject before the verb: 'The students' (who) comes before 'laugh' (what they do). There is no object here — the verb alone completes the idea.",
      grammarRule: 'Basic Subject-Verb Order (S-V)',
      structureType: 'S-V',
    ),
    WordReorderPracticeQuest(
      id: 'FALLBACK_WR_P2',
      level: 1,
      instruction: 'Tap the words in the correct grammatical order',
      targetSentence: 'Local musicians perform.',
      shuffledWords: ['musicians', 'Local', 'perform.'],
      correctOrder: [1, 0, 2],
      hint: 'The word describing the musicians stays attached to them, right before the verb.',
      explanation:
          'Local describes musicians, so it stays directly in front of the noun it modifies, and the whole subject phrase comes before the verb perform.',
      grammarRule: 'Basic Subject-Verb Order (S-V)',
      structureType: 'S-V',
    ),
  ];

  int _currentIndex = 0;
  final List<String> _assembledWords = [];
  final List<int> _usedIndices = [];
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
          'assets/curriculum/grammar/wordReorder_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => WordReorderPracticeQuest.fromJson(
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

  void _onWordTappedFromPool(int index, String word) {
    if (_isCorrect == true) return;
    if (_usedIndices.contains(index)) return;

    setState(() {
      _usedIndices.add(index);
      _assembledWords.add(word);
    });

    _checkAutomaticValidation();
  }

  void _onWordTappedFromAssembly(int assemblyIndex) {
    if (_isCorrect == true) return;

    setState(() {
      _assembledWords.removeAt(assemblyIndex);
      _usedIndices.removeAt(assemblyIndex);
      _isCorrect = null;
    });
  }

  void _onReset() {
    if (_isCorrect == true) return;

    setState(() {
      _assembledWords.clear();
      _usedIndices.clear();
      _isCorrect = null;
    });
  }

  void _checkAutomaticValidation() {
    final quest = _quests[_currentIndex];
    if (_assembledWords.length == quest.shuffledWords.length) {
      // Normalize target sentence for comparison (ignoring trailing periods for relaxed check)
      final constructed = _assembledWords.join(' ').trim().toLowerCase().replaceAll('.', '');
      final target = quest.targetSentence.trim().toLowerCase().replaceAll('.', '');

      final isMatch = constructed == target;

      setState(() {
        _isCorrect = isMatch;
      });

      if (isMatch) {
        _speakText(quest.targetSentence);
      }
    } else {
      setState(() {
        _isCorrect = null;
      });
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _assembledWords.clear();
        _usedIndices.clear();
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
      gameType: 'wordReorder',
      level: widget.level,
      phase: 'practice',
    );
    final targetMastery =
        '/game?category=grammar&gameType=wordReorder&level=${widget.level}';
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

    return PracticePhaseScaffold(
      title: 'Block Stacker Gym',
      gameType: 'wordReorder',
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
            // Header Pill & Exercise Counter
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
                    Icons.view_carousel_rounded,
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

            // Sentence Assembly Zone (Target Area)
            Container(
              constraints: BoxConstraints(minHeight: 110.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: _isCorrect == true
                      ? AppColors.emerald500
                      : (_isCorrect == false
                          ? AppColors.rose500
                          : AppColors.violet500.withValues(alpha: 0.3)),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ASSEMBLY DOCK',
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_assembledWords.isNotEmpty && _isCorrect != true)
                        InkWell(
                          onTap: _onReset,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.slate400,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'RESET',
                                  style: TextStyle(
                                    color: AppColors.slate400,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  if (_assembledWords.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        child: Text(
                          'Tap words below in grammatical order',
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: List.generate(_assembledWords.length, (idx) {
                        final word = _assembledWords[idx];
                        return Material(
                          color: _isCorrect == true
                              ? AppColors.emerald500.withValues(alpha: 0.25)
                              : AppColors.violet500.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12.r),
                          child: InkWell(
                            onTap: () => _onWordTappedFromAssembly(idx),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: _isCorrect == true
                                      ? AppColors.emerald500
                                      : AppColors.violet500,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    word,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (_isCorrect != true) ...[
                                    SizedBox(width: 6.w),
                                    Icon(
                                      Icons.close_rounded,
                                      color: AppColors.slate400,
                                      size: 14.r,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Word Pool
            Text(
              'AVAILABLE WORD BLOCKS',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: List.generate(quest.shuffledWords.length, (idx) {
                final word = quest.shuffledWords[idx];
                final isUsed = _usedIndices.contains(idx);

                return Opacity(
                  opacity: isUsed ? 0.35 : 1.0,
                  child: Material(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(12.r),
                    child: InkWell(
                      onTap: isUsed
                          ? null
                          : () => _onWordTappedFromPool(idx, word),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isUsed
                                ? AppColors.slate800
                                : AppColors.slate700,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          word,
                          style: TextStyle(
                            color: isUsed ? AppColors.slate500 : Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Feedback Card
            if (_isCorrect == true) ...[
              SizedBox(height: 16.h),
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
              SizedBox(height: 16.h),
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
                        'Not quite in order. Tap a word to remove it or tap Reset!',
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
