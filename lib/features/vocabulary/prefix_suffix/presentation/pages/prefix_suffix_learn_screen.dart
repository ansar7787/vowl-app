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

/// Learn Phase Screen for Prefix Suffix: Affix Morphology Laboratory.
///
/// Teaches prefix and suffix mechanisms, root fusions, and morphological alterations.
/// Interactive tryout lets learners attach affixes to roots and see real-time meaning transformations.
class PrefixSuffixLearnScreen extends StatefulWidget {
  final int level;

  const PrefixSuffixLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PrefixSuffixLearnScreen> createState() => _PrefixSuffixLearnScreenState();
}

class _PrefixSuffixLearnScreenState extends State<PrefixSuffixLearnScreen> {
  int _currentIndex = 0;
  List<VocabularyQuest> _quests = [];
  bool _isLoading = true;

  String? _selectedAffix;
  bool? _isAffixCorrect;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile = 'assets/curriculum/vocabulary/prefixSuffix_learn_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => VocabularyQuest(
                id: q['id'] as String? ?? 'VOC_PS_L${widget.level}_Q1',
                type: QuestType.vocabulary,
                subtype: GameSubtype.prefixSuffix,
                word: q['word'] as String? ?? '',
                rootWord: q['rootWord'] as String? ?? '',
                correctAnswer: q['correctAnswer'] as String? ?? '',
                options: (q['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                instruction: q['instruction'] as String? ?? 'Pick the affix that completes the word.',
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
        id: 'VOC_PREFIXSUFFIX_L${widget.level}_LEARN_Q1',
        type: QuestType.vocabulary,
        subtype: GameSubtype.prefixSuffix,
        word: 'REDO',
        rootWord: 'DO',
        correctAnswer: 'RE-',
        options: const ['MIS-', 'DE-', 'PRE-', 'RE-'],
        instruction: 'Pick the prefix that completes the word for this meaning.',
        hint: 'This prefix shows an action happening one more time, often to fix a mistake.',
        explanation: "RE- means 'again.' Added to DO, it forms REDO — to perform an action a second time.",
        meaningBreakdown: "RE- (again) + DO (root) ➔ REDO",
        difficulty: 1,
      ),
      VocabularyQuest(
        id: 'VOC_PREFIXSUFFIX_L${widget.level}_LEARN_Q2',
        type: QuestType.vocabulary,
        subtype: GameSubtype.prefixSuffix,
        word: 'UNLOCK',
        rootWord: 'LOCK',
        correctAnswer: 'UN-',
        options: const ['DIS-', 'DE-', 'UN-', 'MIS-'],
        instruction: 'Pick the prefix that reverses the action.',
        hint: 'Turning a key to open a door that was secured shut.',
        explanation: 'UN- reverses an action. Added to LOCK, it forms UNLOCK — to open something that was locked.',
        meaningBreakdown: 'UN- (reverses action) + LOCK (root) ➔ UNLOCK',
        difficulty: 1,
      ),
    ];
  }

  void _onAffixSelected(String affix, String correctAffix, String combinedWord) {
    di.sl<HapticService>().selection();
    final cleanSelected = affix.replaceAll('-', '').trim().toLowerCase();
    final cleanCorrect = correctAffix.replaceAll('-', '').trim().toLowerCase();
    final isCorrect = cleanSelected == cleanCorrect;

    setState(() {
      _selectedAffix = affix;
      _isAffixCorrect = isCorrect;
    });

    if (isCorrect) {
      di.sl<SoundService>().playCorrect();
      di.sl<HapticService>().success();
      if (combinedWord.isNotEmpty) {
        di.sl<TtsService>().speak(combinedWord);
      }
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
      });
    } else {
      _navigateToPractice();
    }
  }

  void _navigateToPractice() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'prefixSuffix',
      level: widget.level,
      phase: 'learn',
    );
    context.pushReplacement(
      '/practice?category=vocabulary&gameType=prefixSuffix&level=${widget.level}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.indigo500;

    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Affix Lab',
        gameType: 'prefixSuffix',
        level: widget.level,
        onComplete: _navigateToPractice,
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
    final isPrefix = correctAnswer.endsWith('-') || (!correctAnswer.startsWith('-') && !options.any((o) => o.startsWith('-')));

    return LearnPhaseScaffold(
      title: 'Affix Lab: ${isPrefix ? 'Prefixes' : 'Suffixes'}',
      gameType: 'prefixSuffix',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Concept (${_currentIndex + 1}/${_quests.length})'
          : 'Proceed to Practice ➔',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affix Fusion Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
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
                    'Affix Architecture: ${isPrefix ? 'Prefix' : 'Suffix'}',
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
                      if (isPrefix) ...[
                        Expanded(
                          child: _buildPill(
                            label: 'PREFIX',
                            text: _selectedAffix ?? '?',
                            color: _isAffixCorrect == true
                                ? AppColors.emerald500
                                : AppColors.amber500,
                            isDark: isDark,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            Icons.add_circle_rounded,
                            color: primaryColor,
                            size: 20.r,
                          ),
                        ),
                        Expanded(
                          child: _buildPill(
                            label: 'BASE ROOT',
                            text: rootWord,
                            color: primaryColor,
                            isDark: isDark,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _buildPill(
                            label: 'BASE ROOT',
                            text: rootWord,
                            color: primaryColor,
                            isDark: isDark,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            Icons.add_circle_rounded,
                            color: primaryColor,
                            size: 20.r,
                          ),
                        ),
                        Expanded(
                          child: _buildPill(
                            label: 'SUFFIX',
                            text: _selectedAffix ?? '?',
                            color: _isAffixCorrect == true
                                ? AppColors.emerald500
                                : AppColors.amber500,
                            isDark: isDark,
                          ),
                        ),
                      ],
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: primaryColor,
                          size: 20.r,
                        ),
                      ),
                      Expanded(
                        child: _buildPill(
                          label: 'RESULT',
                          text: _isAffixCorrect == true ? targetWord : '???',
                          color: _isAffixCorrect == true
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

            // Morphological Definition Card
            _buildCard(
              isDark: isDark,
              accentColor: primaryColor,
              icon: Icons.menu_book_rounded,
              badgeText: 'MORPHOLOGICAL FORMATION',
              body: quest.explanation ??
                  'Affixes alter the core meaning or part of speech of the root word.',
            ),
            SizedBox(height: 12.h),

            // Target Meaning Breakdown Card
            if ((quest.meaningBreakdown ?? '').isNotEmpty) ...[
              _buildCard(
                isDark: isDark,
                accentColor: AppColors.amber500,
                icon: Icons.lightbulb_outline_rounded,
                badgeText: 'MEANING BREAKDOWN',
                body: quest.meaningBreakdown!,
              ),
              SizedBox(height: 12.h),
            ],

            // Interactive Affix Tryout Section
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
                          'INTERACTIVE AFFIX FUSION TRYOUT',
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
                    quest.instruction.isNotEmpty
                        ? quest.instruction
                        : 'Select the correct affix to synthesize the word:',
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
                    children: options.map((affix) {
                      final isSelected = _selectedAffix == affix;
                      final isCorrect = isSelected && _isAffixCorrect == true;
                      final isWrong = isSelected && _isAffixCorrect == false;

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
                        onTap: () => _onAffixSelected(affix, correctAnswer, targetWord),
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
                  if (_isAffixCorrect != null) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          _isAffixCorrect == true
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: _isAffixCorrect == true
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            _isAffixCorrect == true
                                ? 'Perfect! Affix fusion complete ➔ $targetWord'
                                : 'Notice the target meaning: ${quest.hint ?? "Try another affix"}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _isAffixCorrect == true
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
                fontSize: 14.sp,
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
              Text(
                badgeText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: accentColor,
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
