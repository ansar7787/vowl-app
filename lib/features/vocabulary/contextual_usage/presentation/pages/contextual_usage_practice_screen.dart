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

/// Practice Phase Screen for Contextual Usage: "Contextual Usage Gym".
///
/// Features guided active-recall drills:
/// Drill 1: Context Fitting & Gap Resolution.
/// Drill 2: Register & Pragmatic Calibration.
class ContextualUsagePracticeScreen extends StatefulWidget {
  final int level;

  const ContextualUsagePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ContextualUsagePracticeScreen> createState() =>
      _ContextualUsagePracticeScreenState();
}

class _ContextualUsagePracticeScreenState
    extends State<ContextualUsagePracticeScreen> {
  int _currentIndex = 0;
  List<VocabularyQuest> _quests = [];
  bool _isLoading = true;

  String? _selectedOption;
  bool? _isOptionCorrect;
  bool _drillStage2Active = false;
  String? _selectedRegister;
  bool? _isRegisterCorrect;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile =
        'assets/curriculum/vocabulary/contextualUsage_practice_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => VocabularyQuest(
                id: q['id'] as String? ?? 'VOC_CONTEXT_P_L${widget.level}_Q1',
                type: QuestType.vocabulary,
                subtype: GameSubtype.contextualUsage,
                word: q['word'] as String? ?? '',
                correctAnswer: q['correctAnswer'] as String? ?? '',
                options: (q['options'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                instruction: q['instruction'] as String? ??
                    'Analyze the context, tone, and register to select the most appropriate word.',
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
        id: 'VOC_CONTEXT_P_L${widget.level}_FALLBACK',
        type: QuestType.vocabulary,
        subtype: GameSubtype.contextualUsage,
        word: 'BORROW',
        correctAnswer: 'BORROW',
        options: const ['LEND', 'RENT', 'BORROW', 'LOAN'],
        instruction: 'Select the word that best completes the sentence.',
        hint: 'Think about whether the speaker wants to receive something temporarily or hand something over.',
        explanation: 'Borrow means to take something temporarily, intending to return it.',
        prompt: "Could I _____ your pen? I'll give it back after class.",
        contextSentence: "Could I borrow your pen? I'll give it back after class.",
        usageExample: "Could I borrow your pen? I'll give it back after class.",
        nuanceDifference: "Borrow is receiving; Lend is giving temporarily.",
        registerLevel: 1,
        difficulty: 1,
      ),
    ];
  }

  String _getRegisterCategory(int? regLevel) {
    final reg = regLevel ?? 1;
    if (reg <= 3) return 'Casual / Everyday';
    if (reg <= 6) return 'Standard / Conversational';
    return 'Formal / Professional';
  }

  void _onOptionSelected(String option, String correctAnswer) {
    final isCorrect =
        option.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isOptionCorrect = isCorrect;
      if (isCorrect) {
        _drillStage2Active = true;
      }
    });

    if (isCorrect) {
      di.sl<HapticService>().success();
      di.sl<SoundService>().playCorrect();
    } else {
      di.sl<HapticService>().light();
      di.sl<SoundService>().playWrong();
    }
  }

  void _onRegisterSelected(String selectedCategory, String correctCategory) {
    final isCorrect = selectedCategory == correctCategory;

    setState(() {
      _selectedRegister = selectedCategory;
      _isRegisterCorrect = isCorrect;
    });

    if (isCorrect) {
      di.sl<HapticService>().success();
      di.sl<SoundService>().playCorrect();
    } else {
      di.sl<HapticService>().light();
      di.sl<SoundService>().playWrong();
    }
  }

  void _onContinue() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isOptionCorrect = null;
        _drillStage2Active = false;
        _selectedRegister = null;
        _isRegisterCorrect = null;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'contextualUsage',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/game?category=vocabulary&gameType=contextualUsage&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Contextual Usage Gym: Level ${widget.level}',
        gameType: 'contextualUsage',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: () {},
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetRegister = _getRegisterCategory(quest.registerLevel);

    final canContinue =
        (_isOptionCorrect ?? false) && (!_drillStage2Active || (_isRegisterCorrect ?? false));

    return PracticePhaseScaffold(
      title: 'Contextual Usage Gym: Level ${widget.level}',
      gameType: 'contextualUsage',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Practice Quest (${_currentIndex + 1}/${_quests.length})'
          : 'Enter Mastery Arena 🏆',
      isActionEnabled: canContinue,
      onComplete: () {
        if (!canContinue) return;
        _onContinue();
      },
      child: SingleChildScrollView(
        key: const Key('contextual_usage_practice_content'),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drill 1: Context Dilemma & Gap Fill
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1D36) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
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
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'DRILL 1: CONTEXT FIT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6C5CE7),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 20,
                        ),
                        onPressed: () {
                          final textToRead = quest.prompt ?? quest.contextSentence ?? "";
                          if (di.sl.isRegistered<TtsService>() && textToRead.isNotEmpty) {
                            di.sl<TtsService>().speak(textToRead);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.prompt ?? quest.instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: isDark ? Colors.white : AppColors.slate900,
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
                        key: Key('practice_option_${opt.toLowerCase()}'),
                        onTap: () => _onOptionSelected(opt, quest.correctAnswer ?? ""),
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
                    SizedBox(height: 10.h),
                    Text(
                      (_isOptionCorrect ?? false)
                          ? "✅ Perfect contextual match! Direction and nuance are verified."
                          : "❌ Not quite. ${quest.hint ?? 'Review the sentence meaning and try again.'}",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: (_isOptionCorrect ?? false)
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Drill 2: Register & Tone Calibration (Activates after Drill 1)
            if (_drillStage2Active) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E243D) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'DRILL 2: REGISTER CALIBRATION',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.indigoAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'What social register / formality does this sentence use?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Column(
                      children: [
                        'Casual / Everyday',
                        'Standard / Conversational',
                        'Formal / Professional',
                      ].map((cat) {
                        final isSelected = _selectedRegister == cat;
                        final isCorrect = cat == targetRegister;

                        Color tileBg;
                        if (!isSelected) {
                          tileBg = isDark
                              ? const Color(0xFF282D4A)
                              : Colors.white;
                        } else if (isCorrect) {
                          tileBg = Colors.green.shade600;
                        } else {
                          tileBg = Colors.red.shade600;
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: InkWell(
                            key: Key('register_option_${cat.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'),
                            onTap: () => _onRegisterSelected(cat, targetRegister),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: tileBg,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: isSelected
                                      ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.2)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? (isCorrect
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded)
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white54 : Colors.grey),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedRegister != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        (_isRegisterCorrect ?? false)
                            ? "🎯 Calibrated! Register Level ${quest.registerLevel}/10 correctly recognized."
                            : "💡 Notice tone and setting: ${quest.explanation ?? ''}",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: (_isRegisterCorrect ?? false)
                              ? Colors.green
                              : Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
