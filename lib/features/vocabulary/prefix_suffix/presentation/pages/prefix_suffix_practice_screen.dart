import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Practice Phase Screen for Prefix Suffix: Affix Association Gym.
///
/// Features guided active-recall drills:
/// Drill 1: Select the correct affix matching target meaning.
/// Drill 2: Type or confirm the synthesized word.
class PrefixSuffixPracticeScreen extends StatefulWidget {
  final int level;

  const PrefixSuffixPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<PrefixSuffixPracticeScreen> createState() =>
      _PrefixSuffixPracticeScreenState();
}

class _PrefixSuffixPracticeScreenState
    extends State<PrefixSuffixPracticeScreen> {
  int _currentIndex = 0;
  List<VocabularyQuest> _quests = [];
  bool _isLoading = true;

  String? _selectedAffix;
  bool? _isAffixCorrect;
  bool _drillStage2Active = false;
  final TextEditingController _spellingController = TextEditingController();
  bool? _isSpellingCorrect;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  @override
  void dispose() {
    _spellingController.dispose();
    super.dispose();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile =
        'assets/curriculum/vocabulary/prefixSuffix_practice_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => VocabularyQuest(
                id: q['id'] as String? ?? 'VOC_PS_P_L${widget.level}_Q1',
                type: QuestType.vocabulary,
                subtype: GameSubtype.prefixSuffix,
                word: q['word'] as String? ?? '',
                rootWord: q['rootWord'] as String? ?? '',
                correctAnswer: q['correctAnswer'] as String? ?? '',
                options: (q['options'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                instruction: q['instruction'] as String? ??
                    'Select the correct affix for this meaning.',
                hint: q['hint'] as String? ?? '',
                explanation: q['explanation'] as String? ?? '',
                meaningBreakdown: q['meaningBreakdown'] as String? ?? '',
                difficulty: q['difficulty'] as int? ?? 1,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _quests = filtered.isNotEmpty ? filtered : _buildFallbackQuests();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _buildFallbackQuests();
          _isLoading = false;
        });
      }
    }
  }

  List<VocabularyQuest> _buildFallbackQuests() {
    return [
      VocabularyQuest(
        id: 'VOC_PREFIXSUFFIX_L${widget.level}_PRACTICE_Q1',
        type: QuestType.vocabulary,
        subtype: GameSubtype.prefixSuffix,
        word: 'REDO',
        rootWord: 'DO',
        correctAnswer: 'RE-',
        options: const ['MIS-', 'DE-', 'PRE-', 'RE-'],
        instruction: 'Select or drag the correct affix to match the target meaning.',
        hint: 'This prefix shows an action happening one more time, often to fix a mistake.',
        explanation: "RE- means 'again.' Added to DO, it forms REDO.",
        meaningBreakdown: 'RE- (again) + DO ➔ REDO',
        difficulty: 1,
      ),
      VocabularyQuest(
        id: 'VOC_PREFIXSUFFIX_L${widget.level}_PRACTICE_Q2',
        type: QuestType.vocabulary,
        subtype: GameSubtype.prefixSuffix,
        word: 'UNLOCK',
        rootWord: 'LOCK',
        correctAnswer: 'UN-',
        options: const ['DIS-', 'DE-', 'UN-', 'MIS-'],
        instruction: 'Pick the prefix that reverses the action.',
        hint: 'Turning a key to open a door that was secured shut.',
        explanation: 'UN- reverses an action. Added to LOCK, it forms UNLOCK.',
        meaningBreakdown: 'UN- (reverses action) + LOCK ➔ UNLOCK',
        difficulty: 1,
      ),
    ];
  }

  void _onAffixChosen(String affix, String correctAffix, String combinedWord) {
    if (_isAffixCorrect == true) return;
    di.sl<HapticService>().selection();

    final cleanChosen = affix.replaceAll('-', '').trim().toLowerCase();
    final cleanCorrect = correctAffix.replaceAll('-', '').trim().toLowerCase();
    final isCorrect = cleanChosen == cleanCorrect;

    setState(() {
      _selectedAffix = affix;
      _isAffixCorrect = isCorrect;
      if (isCorrect) {
        _drillStage2Active = true;
      }
    });

    if (isCorrect) {
      di.sl<SoundService>().playCorrect();
      di.sl<HapticService>().success();
    } else {
      di.sl<SoundService>().playWrong();
      di.sl<HapticService>().error();
    }
  }

  void _checkSpelling(String targetWord) {
    final input = _spellingController.text.trim().toLowerCase();
    final isRight = input == targetWord.trim().toLowerCase();

    setState(() {
      _isSpellingCorrect = isRight;
    });

    if (isRight) {
      di.sl<SoundService>().playCorrect();
      di.sl<HapticService>().success();
      di.sl<TtsService>().speak(targetWord);
    } else {
      di.sl<SoundService>().playWrong();
      di.sl<HapticService>().error();
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAffix = null;
        _isAffixCorrect = null;
        _drillStage2Active = false;
        _isSpellingCorrect = null;
        _spellingController.clear();
      });
    } else {
      _navigateToMastery();
    }
  }

  void _navigateToMastery() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'prefixSuffix',
      level: widget.level,
      phase: 'practice',
    );
    final targetTest =
        '/game?category=vocabulary&gameType=prefixSuffix&level=${widget.level}';
    context.pushReplacement(targetTest);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.amber;

    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Affix Gym',
        gameType: 'prefixSuffix',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: _navigateToMastery,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final rootWord = quest.rootWord ?? quest.word ?? 'ROOT';
    final correctAnswer = quest.correctAnswer ?? '';
    final options = quest.options ?? [];
    final targetWord = quest.word ?? rootWord;

    final isExerciseComplete =
        _isAffixCorrect == true && (_isSpellingCorrect == true || !_drillStage2Active);

    return PracticePhaseScaffold(
      title: 'Affix Gym: Level ${widget.level}',
      gameType: 'prefixSuffix',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Drill (${_currentIndex + 1}/${_quests.length})'
          : 'Enter Mastery Arena 🏆',
      onComplete: () {
        if (!isExerciseComplete) return;
        _onNext();
      },
      onHint: () {
        if (quest.hint != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hint: ${quest.hint}'),
              duration: const Duration(seconds: 3),
              backgroundColor: isDark ? AppColors.slate800 : AppColors.slate900,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drill 1: Affix Selection Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
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
                          'DRILL 1: AFFIX MATCHING',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'BASE: $rootWord',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.hint ?? quest.instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: options.map((affix) {
                      final isSelected = _selectedAffix == affix;
                      final isCorrect = isSelected && _isAffixCorrect == true;
                      final isWrong = isSelected && _isAffixCorrect == false;

                      Color chipBg =
                          isDark ? AppColors.slate800 : AppColors.slate100;
                      Color chipBorder =
                          isDark ? AppColors.slate700 : AppColors.slate300;
                      Color chipText =
                          isDark ? Colors.white : AppColors.slate800;

                      if (isCorrect) {
                        chipBg = AppColors.emerald500.withValues(alpha: 0.2);
                        chipBorder = AppColors.emerald500;
                        chipText = AppColors.emerald500;
                      } else if (isWrong) {
                        chipBg = AppColors.rose500.withValues(alpha: 0.2);
                        chipBorder = AppColors.rose500;
                        chipText = AppColors.rose500;
                      }

                      return InkWell(
                        onTap: () => _onAffixChosen(affix, correctAnswer, targetWord),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: chipBorder, width: 1.5),
                          ),
                          child: Text(
                            affix.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: chipText,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Drill 2: Spelling Confirmation Card
            if (_drillStage2Active) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isSpellingCorrect == true
                        ? AppColors.emerald500
                        : AppColors.indigo500.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DRILL 2: WORD SYNTHESIS CONFIRMATION',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.indigo500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Type the complete synthesized word ($rootWord + $_selectedAffix):',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _spellingController,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. $targetWord',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 10.h),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            onSubmitted: (_) => _checkSpelling(targetWord),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () => _checkSpelling(targetWord),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indigo500,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: const Text('Check'),
                        ),
                      ],
                    ),
                    if (_isSpellingCorrect != null) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            _isSpellingCorrect == true
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _isSpellingCorrect == true
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            size: 18.r,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              _isSpellingCorrect == true
                                  ? 'Synthesized correctly: ${targetWord.toUpperCase()}'
                                  : 'Target word is: ${targetWord.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: _isSpellingCorrect == true
                                    ? AppColors.emerald500
                                    : AppColors.rose500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Explanatory Reinforcement Card
            if (quest.explanation != null && (quest.explanation ?? '').isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade600, size: 18.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.explanation!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          height: 1.4,
                          color:
                              isDark ? AppColors.slate300 : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
