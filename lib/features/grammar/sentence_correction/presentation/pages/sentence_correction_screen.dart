import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_instruction.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_diagnostic_word.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_options_panel.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_feedback.dart';

class SentenceCorrectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceCorrectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceCorrection,
  });

  @override
  State<SentenceCorrectionScreen> createState() => _SentenceCorrectionScreenState();
}

class _SentenceCorrectionScreenState extends State<SentenceCorrectionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _selectedWordIndex;
  String? _selectedOption;
  List<String>? _shuffledOptions;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  List<int> _getCorrectIndices(List<String> words, GrammarQuest quest) {
    if (quest.incorrectPart == null) return [0];

    final cleanTarget = quest.incorrectPart!.toLowerCase().replaceAll('"', '').trim();
    final targetWords = cleanTarget.split(' ').where((w) => w.isNotEmpty).toList();

    if (targetWords.isEmpty) return [0];

    final cleanSentenceWords = words.map((w) => w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '')).toList();
    final cleanTargetWords = targetWords.map((w) => w.replaceAll(RegExp(r'[^\w]'), '')).toList();

    List<int> matchingIndices = [];

    // Contiguous search match
    for (int i = 0; i <= cleanSentenceWords.length - cleanTargetWords.length; i++) {
      bool match = true;
      for (int j = 0; j < cleanTargetWords.length; j++) {
        if (!cleanSentenceWords[i + j].contains(cleanTargetWords[j]) &&
            !cleanTargetWords[j].contains(cleanSentenceWords[i + j])) {
          match = false;
          break;
        }
      }
      if (match) {
        for (int j = 0; j < cleanTargetWords.length; j++) {
          matchingIndices.add(i + j);
        }
        break;
      }
    }

    if (matchingIndices.isEmpty) {
      for (int i = 0; i < cleanSentenceWords.length; i++) {
        for (var targetW in cleanTargetWords) {
          if (cleanSentenceWords[i] == targetW ||
              (cleanSentenceWords[i].isNotEmpty && targetW.contains(cleanSentenceWords[i]))) {
            matchingIndices.add(i);
          }
        }
      }
    }

    if (matchingIndices.isEmpty) {
      final fallbackIdx = words.indexWhere((w) {
        final cleanW = w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        return cleanW.contains(cleanTargetWords.first) || cleanTargetWords.first.contains(cleanW);
      });
      matchingIndices.add(fallbackIdx != -1 ? fallbackIdx : 0);
    }

    return matchingIndices;
  }

  void _onWordTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedWordIndex = index;
      _selectedOption = null;
    });
  }

  void _confirmRepair(List<int> correctIndices, GrammarQuest quest, List<String> words) {
    if (_selectedWordIndex == null || _selectedOption == null) return;

    bool isWordCorrect = correctIndices.contains(_selectedWordIndex);
    int chosenIndex = quest.options?.indexOf(_selectedOption!) ?? -1;
    bool isOptionCorrect = (_selectedOption == quest.correctAnswer) ||
        (chosenIndex == quest.correctAnswerIndex);
    bool overallCorrect = isWordCorrect && isOptionCorrect;

    if (kDebugMode) {
      print("=== SYNTAX REPAIR DIAGNOSTICS ===");
      print("Sentence: ${quest.sentence}");
      print("Words split list: $words");
      print("Tapped Word Index: $_selectedWordIndex (Word: ${words[_selectedWordIndex!]})");
      print("Target Error Indices calculated: $correctIndices");
      print("Is Word Target Correct? $isWordCorrect");
      print("Tapped Option: '$_selectedOption'");
      print("Correct Answer: '${quest.correctAnswer}'");
      print("Options List: ${quest.options}");
      print("Correct Answer Index: ${quest.correctAnswerIndex}");
      print("Is Option Correct? $isOptionCorrect");
      print("Overall Resolution Correct? $overallCorrect");
      print("================================");
    }

    if (overallCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = overallCorrect;
    });
    context.read<GrammarBloc>().add(SubmitAnswer(overallCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedWordIndex = null;
              _selectedOption = null;
              _shuffledOptions = isRetry
                  ? (List.from(state.currentQuest.options ?? [])..shuffle())
                  : null;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SYNTAX SURGEON!',
            enableDoubleUp: true,
          );
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final rawSentence = quest?.sentence ?? "";
        final cleanSentence = rawSentence.replaceAll('"', '').replaceAll('Fix:', '').trim();
        final words = cleanSentence.split(' ').where((w) => w.isNotEmpty).toList();

        if (quest != null && _shuffledOptions == null) {
          _shuffledOptions = List<String>.from(quest.options ?? []);
          _shuffledOptions!.shuffle();
        }

        final List<int> correctIndices = quest == null ? [] : _getCorrectIndices(words, quest);

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          useScrolling: true,
          child: quest == null
              ? const SizedBox()
              : Column(
                  children: [
                    SizedBox(height: 10.h),
                    SentenceCorrectionInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 12.h),
                    Text(
                      "Tap the incorrect word to diagnose, then choose the repair option.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Diagnostic Context Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.05),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10.w,
                          runSpacing: 16.h,
                          children: List.generate(words.length, (i) {
                            return SentenceCorrectionDiagnosticWord(
                              text: words[i],
                              index: i,
                              isSuspected: _selectedWordIndex == i,
                              isCorrectZap: _isAnswered && _isCorrect == true && correctIndices.contains(i),
                              isWrongZap: _isAnswered && _isCorrect == false && _selectedWordIndex == i,
                              isDark: isDark,
                              primaryColor: theme.primaryColor,
                              onTap: () => _onWordTap(i),
                            );
                          }),
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),

                    SizedBox(height: 20.h),

                    // Scanner Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10.r,
                          height: 10.r,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.8, 1.8),
                          duration: 1.seconds,
                        )
                        .shimmer(color: theme.primaryColor),
                        SizedBox(width: 14.w),
                        Text(
                          "SCANNER ARMED: SEEKING GLITCHES",
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: theme.primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    // Options Panel
                    if (_selectedWordIndex != null) ...[
                      SizedBox(height: 24.h),
                      SentenceCorrectionOptionsPanel(
                        options: _shuffledOptions ?? [],
                        selectedOption: _selectedOption,
                        isAnswered: _isAnswered,
                        isDark: isDark,
                        primaryColor: theme.primaryColor,
                        onOptionSelect: (option) {
                          _hapticService.selection();
                          setState(() => _selectedOption = option);
                        },
                        onConfirm: () => _confirmRepair(correctIndices, quest, words),
                      ),
                    ],

                    // Correction Feedback
                    if (_isAnswered && _isCorrect == false) ...[
                      SizedBox(height: 24.h),
                      SentenceCorrectionFeedback(
                        correction: quest.correctedPart ?? "",
                        primaryColor: theme.primaryColor,
                      ),
                    ],

                    SizedBox(height: 20.h),
                  ],
                ),
        );
      },
    );
  }
}
