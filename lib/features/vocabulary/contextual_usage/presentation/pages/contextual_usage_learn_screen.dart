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

/// Learn Phase Screen for Contextual Usage: "Context & Register Lab".
///
/// Teaches learners how social context, agent orientation (direction), and
/// register (casual, neutral, formal, academic) dictate natural English word choices.
class ContextualUsageLearnScreen extends StatefulWidget {
  final int level;
  final List<VocabularyQuest>? initialQuests;

  const ContextualUsageLearnScreen({
    super.key,
    required this.level,
    this.initialQuests,
  });

  @override
  State<ContextualUsageLearnScreen> createState() =>
      _ContextualUsageLearnScreenState();
}

class _ContextualUsageLearnScreenState
    extends State<ContextualUsageLearnScreen> {
  int _currentIndex = 0;
  List<VocabularyQuest> _quests = [];
  bool _isLoading = true;

  String? _selectedOption;
  bool? _isOptionCorrect;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuests != null && widget.initialQuests!.isNotEmpty) {
      _quests = widget.initialQuests!;
      _isLoading = false;
    } else {
      _loadCurriculum();
    }
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile =
        'assets/curriculum/vocabulary/contextualUsage_learn_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => VocabularyQuest(
                id: q['id'] as String? ?? 'VOC_CONTEXT_L${widget.level}_Q1',
                type: QuestType.vocabulary,
                subtype: GameSubtype.contextualUsage,
                word: q['word'] as String? ?? '',
                correctAnswer: q['correctAnswer'] as String? ?? '',
                options: (q['options'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                instruction: q['instruction'] as String? ??
                    'Select the word that best completes the sentence.',
                hint: q['hint'] as String? ?? '',
                explanation: q['explanation'] as String? ?? '',
                prompt: q['question'] as String? ?? q['prompt'] as String? ?? '',
                contextSentence: q['contextSentence'] as String? ?? '',
                usageExample: q['usageExample'] as String? ?? '',
                nuanceDifference: q['nuanceDifference'] as String? ?? '',
                registerLevel: q['registerLevel'] as int? ?? 1,
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
        id: 'VOC_CONTEXT_L${widget.level}_FALLBACK_1',
        type: QuestType.vocabulary,
        subtype: GameSubtype.contextualUsage,
        word: 'BORROW',
        correctAnswer: 'BORROW',
        options: const ['LEND', 'RENT', 'BORROW', 'LOAN'],
        instruction: 'Select the word that best completes the sentence.',
        hint:
            'Think about whether the speaker wants to receive something temporarily or hand something over.',
        explanation:
            'Borrow means to take something temporarily, intending to return it.',
        prompt: "Could I _____ your pen? I'll give it back after class.",
        contextSentence:
            "Could I borrow your pen? I'll give it back after class.",
        usageExample: "Could I borrow your pen? I'll give it back after class.",
        nuanceDifference: 'Borrow is receiving; Lend is giving temporarily.',
        registerLevel: 1,
        difficulty: 1,
      ),
      VocabularyQuest(
        id: 'VOC_CONTEXT_L${widget.level}_FALLBACK_2',
        type: QuestType.vocabulary,
        subtype: GameSubtype.contextualUsage,
        word: 'LEND',
        correctAnswer: 'LEND',
        options: const ['BORROW', 'LEND', 'OWE', 'GIVE'],
        instruction: 'Select the word that best completes the sentence.',
        hint:
            'Ask yourself who is doing the giving here — the sister, not the speaker.',
        explanation:
            'Lend means to give something temporarily, expecting it back.',
        prompt: 'My sister offered to _____ me some money until payday.',
        contextSentence:
            'My sister offered to lend me some money until payday.',
        usageExample: 'My sister offered to lend me some money until payday.',
        nuanceDifference: 'Lend is giving temporarily; Borrow is receiving.',
        registerLevel: 1,
        difficulty: 1,
      ),
    ];
  }

  String _getRegisterTitle(int? level) {
    final reg = level ?? 1;
    if (reg <= 2) return 'Casual & Everyday';
    if (reg <= 5) return 'Conversational & Standard';
    if (reg <= 8) return 'Professional & Formal';
    return 'Scholarly & Elite';
  }

  Color _getRegisterColor(int? level) {
    final reg = level ?? 1;
    if (reg <= 2) return Colors.greenAccent;
    if (reg <= 5) return Colors.cyanAccent;
    if (reg <= 8) return Colors.amberAccent;
    return Colors.purpleAccent;
  }

  void _onOptionTapped(String option, String correctAnswer) {
    final isCorrect =
        option.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isOptionCorrect = isCorrect;
    });

    if (isCorrect) {
      di.sl<HapticService>().success();
      di.sl<SoundService>().playCorrect();
    } else {
      di.sl<HapticService>().light();
      di.sl<SoundService>().playWrong();
    }
  }

  void _nextOrAdvance() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isOptionCorrect = null;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'contextualUsage',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=vocabulary&gameType=contextualUsage&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Context & Register Lab',
        gameType: 'contextualUsage',
        level: widget.level,
        onComplete: () {},
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regColor = _getRegisterColor(quest.registerLevel);

    return LearnPhaseScaffold(
      title: 'Context & Register Lab: Level ${widget.level}',
      gameType: 'contextualUsage',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Context Dilemma (${_currentIndex + 1}/${_quests.length})'
          : 'Proceed to Practice ➔',
      onComplete: _nextOrAdvance,
      child: SingleChildScrollView(
        key: const Key('contextual_usage_learn_content'),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Register and Topic Header Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1F1D36), const Color(0xFF141324)]
                      : [const Color(0xFFEDE9FE), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'CONTEXT MATRIX',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6C5CE7),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: regColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: regColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 12.sp, color: regColor),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  _getRegisterTitle(quest.registerLevel),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? regColor : Colors.indigo.shade900,
                                  ),
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
                    'TARGET CHOICE: ${quest.correctAnswer ?? quest.word ?? ""}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    quest.prompt ?? quest.instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Core Pragmatic Rule Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2238)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'PRAGMATIC RULE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.explanation?.isNotEmpty == true
                        ? quest.explanation!
                        : "Look at agent direction and formality in the sentence.",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      height: 1.45,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Nuance & Context Breakdown
            if (quest.nuanceDifference?.isNotEmpty == true) ...[
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF261D36)
                      : const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.purpleAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'CONTEXT & NUANCE COMPARISON',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.purpleAccent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      quest.nuanceDifference!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // In Action / Audio Sample Card
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182824) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.tealAccent,
                    ),
                    onPressed: () {
                      final textToRead = quest.contextSentence ??
                          quest.usageExample ??
                          quest.prompt ??
                          quest.correctAnswer ??
                          "";
                      if (di.sl.isRegistered<TtsService>() && textToRead.isNotEmpty) {
                        di.sl<TtsService>().speak(textToRead);
                      }
                    },
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NATIVE SPEAKER CONTEXT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.teal,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          quest.contextSentence ??
                              quest.usageExample ??
                              "Listen and observe how this word naturally anchors the context.",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.tealAccent : Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Interactive Tryout
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1F38) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INTERACTIVE QUICK TRYOUT',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF6C5CE7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Tap the word that best fits the sentence context:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: (quest.options ?? []).map((opt) {
                      final isSelected = _selectedOption == opt;
                      final isCorrect = opt.trim().toLowerCase() ==
                          (quest.correctAnswer ?? "").trim().toLowerCase();

                      Color btnColor;
                      if (!isSelected) {
                        btnColor = isDark
                            ? const Color(0xFF282D4A)
                            : const Color(0xFFF1F2F6);
                      } else if (isCorrect) {
                        btnColor = Colors.green.shade600;
                      } else {
                        btnColor = Colors.red.shade600;
                      }

                      return InkWell(
                        key: Key('learn_option_${opt.toLowerCase()}'),
                        onTap: () => _onOptionTapped(opt, quest.correctAnswer ?? ""),
                        borderRadius: BorderRadius.circular(10.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: btnColor,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isSelected
                                  ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedOption != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: (_isOptionCorrect ?? false)
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (_isOptionCorrect ?? false)
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: (_isOptionCorrect ?? false)
                                ? Colors.green
                                : Colors.amber,
                            size: 16,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              (_isOptionCorrect ?? false)
                                  ? "Spot on! That matches the context and register perfectly."
                                  : "Check direction/register: ${quest.hint ?? quest.explanation ?? ''}",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                color: (_isOptionCorrect ?? false)
                                    ? Colors.green
                                    : Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
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
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
