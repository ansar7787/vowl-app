import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_instruction.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_floating_tile.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_assembly_card.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_check_button.dart';

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
  final List<int> _availableIndices = [];
  final List<int> _assembledIndices = [];
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

  void _onWordRemove(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _assembledIndices.remove(index);
      _availableIndices.add(index);
      _availableIndices.sort();
    });
  }

  void _checkSentence(List<int> correctOrder) {
    if (_assembledIndices.isEmpty) return;

    bool correct = _assembledIndices.length == correctOrder.length;
    if (correct) {
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
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });
    context.read<GrammarBloc>().add(SubmitAnswer(correct));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            // FIX: was `state.lastAnswerCorrect != null` and `state.lastAnswerCorrect`
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
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
        } else 
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final hintUsed = (state is GrammarLoaded) ? state.hintUsed : false;
        final shuffledWords = quest?.shuffledWords ?? [];
        final correctOrder = quest?.correctOrder ?? [];
        final expectedNextIndex =
            (hintUsed && _assembledIndices.length < correctOrder.length)
            ? correctOrder[_assembledIndices.length]
            : -1;

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
                    WordReorderAssemblyCard(
                      assembledIndices: _assembledIndices,
                      shuffledWords: shuffledWords,
                      primaryColor: theme.primaryColor,
                      isDark: isDark,
                      isAnswered: _isAnswered,
                      onWordRemove: _onWordRemove,
                    ),
                    SizedBox(height: 30.h),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Wrap(
                          spacing: 12.w,
                          runSpacing: 16.h,
                          alignment: WrapAlignment.center,
                          children: _availableIndices.map((idx) {
                            return WordReorderFloatingTile(
                              word: shuffledWords[idx],
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
                    if (!_isAnswered)
                      WordReorderCheckButton(
                        hasWords: _assembledIndices.isNotEmpty,
                        isDark: isDark,
                        primaryColor: theme.primaryColor,
                        onCheck: () => _checkSentence(correctOrder),
                      ),
                    SizedBox(height: 20.h),
                  ],
                ),
        );
      },
    );
  }
}
