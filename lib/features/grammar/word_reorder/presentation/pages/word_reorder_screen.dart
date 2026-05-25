import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_instruction.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_floating_tile.dart';

class WordReorderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordReorderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordReorder,
  });

  @override
  State<WordReorderScreen> createState() => _WordReorderScreenState();
}

class _WordReorderScreenState extends State<WordReorderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  List<int> _availableIndices = [];
  List<int> _assembledIndices = [];
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

  void _onWordTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _assembledIndices.add(index);
      _availableIndices.remove(index);
    });
  }

  void _checkSentence(List<int> correctOrder) {
    if (_assembledIndices.isEmpty) return;

    bool correct = true;
    if (_assembledIndices.length != correctOrder.length) {
      correct = false;
    } else {
      for (int i = 0; i < correctOrder.length; i++) {
        if (_assembledIndices[i] != correctOrder[i]) {
          correct = false;
          break;
        }
      }
    }

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
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
              _assembledIndices = [];
              final wordsCount = state.currentQuest.shuffledWords?.length ?? 0;
              _availableIndices = List.generate(wordsCount, (i) => i);
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
            title: 'SYNTAX SHARPSHOOTER!',
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
        final hintUsed = (state is GrammarLoaded) ? state.hintUsed : false;

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Column(
                  children: [
                    SizedBox(height: 10.h),
                    WordReorderInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 20.h),

                    // Concise Assembly Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(minHeight: 120.h),
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 10.h,
                            alignment: WrapAlignment.center,
                            children: _assembledIndices.isEmpty
                                ? [
                                    Text(
                                      "WAITING FOR DATA...",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        letterSpacing: 2,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .shimmer(duration: 2.seconds),
                                  ]
                                : _assembledIndices.map((idx) {
                                    final word = quest.shuffledWords![idx];
                                    return ScaleButton(
                                      onTap: () {
                                        if (_isAnswered) return;
                                        _hapticService.selection();
                                        setState(() {
                                          _assembledIndices.remove(idx);
                                          _availableIndices.add(idx);
                                          _availableIndices.sort();
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          word,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ).animate().scale(
                                      duration: 400.ms,
                                      curve: Curves.elasticOut,
                                    );
                                  }).toList(),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(
                      begin: 0.2,
                      end: 0,
                    ),

                    SizedBox(height: 30.h),

                    // Bouncing Gravity Field
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Wrap(
                          spacing: 12.w,
                          runSpacing: 16.h,
                          alignment: WrapAlignment.center,
                          children: _availableIndices.map((idx) {
                            final word = quest.shuffledWords![idx];
                            final expectedNextIndex =
                                (hintUsed &&
                                        _assembledIndices.length <
                                            quest.correctOrder!.length)
                                    ? quest.correctOrder![
                                        _assembledIndices.length
                                      ]
                                    : -1;

                            return WordReorderFloatingTile(
                              word: word,
                              index: idx,
                              onTap: () => _onWordTap(idx),
                              primaryColor: theme.primaryColor,
                              isDark: isDark,
                              isHighlighted: idx == expectedNextIndex,
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Bottom Submit Button
                    if (!_isAnswered)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: ScaleButton(
                          onTap: _assembledIndices.isEmpty
                              ? null
                              : () => _checkSentence(quest.correctOrder!),
                          child: Container(
                            width: double.infinity,
                            height: 58.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              gradient: LinearGradient(
                                colors: _assembledIndices.isEmpty
                                    ? [
                                        Colors.grey.withValues(alpha: 0.3),
                                        Colors.grey.withValues(alpha: 0.4),
                                      ]
                                    : [
                                        theme.primaryColor,
                                        theme.primaryColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                              ),
                              boxShadow: _assembledIndices.isEmpty
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                "CHECK SENTENCE",
                                style: GoogleFonts.outfit(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: _assembledIndices.isEmpty
                                      ? (isDark ? Colors.white30 : Colors.black26)
                                      : Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                    SizedBox(height: 20.h),
                  ],
                ),
        );
      },
    );
  }
}
