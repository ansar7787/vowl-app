import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Learn Phase Screen for Collocations: "Collocation Lab".
///
/// Explores natural lexical partnerships (e.g. DO the laundry vs MAKE a cake),
/// warns against false combinations, and lets learners test interactive word pairing.
class CollocationsLearnScreen extends StatefulWidget {
  final int level;

  const CollocationsLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<CollocationsLearnScreen> createState() =>
      _CollocationsLearnScreenState();
}

class _CollocationsLearnScreenState extends State<CollocationsLearnScreen> {
  int _currentIndex = 0;
  List<VocabularyQuest> _quests = [];
  bool _isLoading = true;

  String? _selectedOption;
  bool? _isOptionCorrect;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile =
        'assets/curriculum/vocabulary/collocations_learn_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => VocabularyQuest(
                id: q['id'] as String? ?? 'VOC_COL_L${widget.level}_Q1',
                type: QuestType.vocabulary,
                subtype: GameSubtype.collocations,
                word: q['word'] as String? ?? '',
                correctAnswer: q['correctAnswer'] as String? ?? '',
                options: (q['options'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                instruction: q['instruction'] as String? ??
                    'Find the word that naturally completes the pair.',
                hint: q['hint'] as String? ?? '',
                explanation: q['explanation'] as String? ?? '',
                wrongCollocations: (q['wrongCollocations'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                contextSentence: q['contextSentence'] as String? ?? '',
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
        id: 'VOC_COLLOCATIONS_L${widget.level}_LEARN_Q1',
        type: QuestType.vocabulary,
        subtype: GameSubtype.collocations,
        word: 'DO',
        correctAnswer: 'LAUNDRY',
        options: const ['BICYCLE', 'WEATHER', 'LAUNDRY', 'GUITAR'],
        instruction: 'Find the word that naturally completes the pair.',
        hint: 'THE PILE OF DIRTY CLOTHES YOU WASH, DRY, AND FOLD',
        explanation:
            "We say DO THE LAUNDRY, not 'make the laundry.' DO is used for everyday chores and tasks.",
        wrongCollocations: const ['make the LAUNDRY', 'have the LAUNDRY'],
        contextSentence:
            'The washing machine broke last week, so I still need to do the laundry by hand.',
        difficulty: 1,
      ),
      VocabularyQuest(
        id: 'VOC_COLLOCATIONS_L${widget.level}_LEARN_Q2',
        type: QuestType.vocabulary,
        subtype: GameSubtype.collocations,
        word: 'MAKE',
        correctAnswer: 'BED',
        options: const ['WINDOW', 'MIRROR', 'BED', 'CARPET'],
        instruction: 'Choose the word that forms a natural pair.',
        hint: 'STRAIGHTENING YOUR SHEETS AND PILLOW SO THE ROOM LOOKS TIDY',
        explanation:
            'MAKE YOUR BED is the standard phrase for tidying it after you sleep.',
        wrongCollocations: const ['do your BED', 'take your BED'],
        contextSentence: 'Before you leave for school, please make your bed.',
        difficulty: 1,
      ),
    ];
  }

  void _onOptionSelected(String option, String correctOption, String anchor) {
    di.sl<HapticService>().selection();
    final isCorrect =
        option.trim().toLowerCase() == correctOption.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isOptionCorrect = isCorrect;
    });

    if (isCorrect) {
      di.sl<SoundService>().playCorrect();
      di.sl<HapticService>().success();
      di.sl<TtsService>().speak('$anchor $correctOption');
    } else {
      di.sl<SoundService>().playWrong();
      di.sl<HapticService>().error();
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isOptionCorrect = null;
      });
    } else {
      _navigateToPractice();
    }
  }

  void _navigateToPractice() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'collocations',
      level: widget.level,
      phase: 'learn',
    );
    context.pushReplacement(
      '/practice?category=vocabulary&gameType=collocations&level=${widget.level}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.indigo500;

    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Collocation Lab',
        gameType: 'collocations',
        level: widget.level,
        onComplete: _navigateToPractice,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final anchor = quest.word ?? 'VERB';
    final correctAnswer = quest.correctAnswer ?? '';
    final options = quest.options ?? [];
    final pair = '$anchor $correctAnswer';

    return LearnPhaseScaffold(
      title: 'Collocation Lab: $anchor',
      gameType: 'collocations',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Pair (${_currentIndex + 1}/${_quests.length})'
          : 'Proceed to Practice ➔',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Natural Collocation Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Lexical Partnership Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildPill(
                          label: 'ANCHOR',
                          text: anchor,
                          color: primaryColor,
                          isDark: isDark,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Icon(
                          Icons.link_rounded,
                          color: primaryColor,
                          size: 22.r,
                        ),
                      ),
                      Expanded(
                        child: _buildPill(
                          label: 'PARTNER',
                          text: _selectedOption ?? '???',
                          color: _isOptionCorrect == true
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          isDark: isDark,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: primaryColor,
                          size: 20.r,
                        ),
                      ),
                      Expanded(
                        child: _buildPill(
                          label: 'COLLOCATION',
                          text: _isOptionCorrect == true ? pair : '???',
                          color: _isOptionCorrect == true
                              ? AppColors.emerald500
                              : AppColors.slate500,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Native Usage Explanation
            _buildCard(
              isDark: isDark,
              accentColor: primaryColor,
              icon: Icons.menu_book_rounded,
              badgeText: 'NATIVE USAGE RULE',
              body: quest.explanation ??
                  "Collocations are words that naturally go together according to native speaker habits.",
            ),
            SizedBox(height: 12.h),

            // Common Mistakes & Contrast Warning
            if (quest.wrongCollocations != null &&
                quest.wrongCollocations!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.rose500.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.rose500, size: 18),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'COMMON TRAPS (UNNATURAL PAIRS)',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.rose500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: quest.wrongCollocations!.map((wrong) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate900
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.rose500.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '✕ $wrong',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rose500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Context Sentence Example Card
            if (quest.contextSentence != null &&
                quest.contextSentence!.isNotEmpty) ...[
              _buildCard(
                isDark: isDark,
                accentColor: AppColors.emerald500,
                icon: Icons.chat_bubble_outline_rounded,
                badgeText: 'NATURAL CONTEXT SENTENCE',
                body: quest.contextSentence!.replaceAll('___', correctAnswer),
              ),
              SizedBox(height: 12.h),
            ],

            // Interactive Pairing Tryout
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app_rounded,
                          color: AppColors.indigo500, size: 18.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'INTERACTIVE COLLOCATION TRYOUT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pair with $anchor: ${quest.hint ?? "Select the natural partner"}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: options.map((option) {
                      final isSelected = _selectedOption == option;
                      final isCorrect = isSelected && _isOptionCorrect == true;
                      final isWrong = isSelected && _isOptionCorrect == false;

                      Color chipBg = isDark
                          ? AppColors.slate800
                          : AppColors.slate100;
                      Color chipBorder = isDark
                          ? AppColors.slate700
                          : AppColors.slate300;
                      Color chipText = isDark
                          ? Colors.white
                          : AppColors.slate800;

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
                        onTap: () =>
                            _onOptionSelected(option, correctAnswer, anchor),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: chipBorder, width: 1.5),
                          ),
                          child: Text(
                            option.toUpperCase(),
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
                  if (_isOptionCorrect != null) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          _isOptionCorrect == true
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: _isOptionCorrect == true
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            _isOptionCorrect == true
                                ? 'Spot on! "$pair" is the natural collocation.'
                                : 'Not quite. Check the native usage rule above.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _isOptionCorrect == true
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Color accentColor,
    required IconData icon,
    required String badgeText,
    required String body,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              height: 1.4,
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}
