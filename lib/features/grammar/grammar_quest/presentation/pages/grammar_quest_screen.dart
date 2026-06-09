import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_instruction.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentence.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass.dart';

class GrammarQuestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GrammarQuestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.grammarQuest,
  });

  @override
  State<GrammarQuestScreen> createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

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

  void _onQuadrantSelect(int index, int correctIndex) {
    if (_isAnswered) return;

    _hapticService.selection();

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
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
            title: 'SENTINEL!',
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
        final options =
            quest?.options ??
            ["Subject", "Verb", "Object", "Tense"]; // Fallback options

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    final double estimatedContentHeight = (isCompact ? 30.h : 40.h) + (isCompact ? 60.h : 90.h) + (isCompact ? 180.r : 280.r) + 40.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
                    final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(4.0, 15.0) : 4.0;
                    final double gapMiddle = remainingHeight > 0 ? (gapUnit * 1.5).clamp(6.0, 20.0) : 6.0;
                    final double gapBottom = remainingHeight > 0 ? (gapUnit * 2.5).clamp(10.0, 30.0) : 10.0;

                    return Column(
                      children: [
                        SizedBox(height: gapTop),
                        isCompact
                            ? SizedBox(
                                height: 25.h,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: GrammarQuestInstruction(primaryColor: theme.primaryColor),
                                ),
                              )
                            : GrammarQuestInstruction(primaryColor: theme.primaryColor),
                        SizedBox(height: gapMiddle),
                        GrammarQuestSentence(
                          text: quest.sentence ?? quest.question ?? "",
                          isDark: isDark,
                          isCompact: isCompact,
                        ),
                        SizedBox(height: gapMiddle * 1.5),
                        GrammarQuestCompass(
                          options: options,
                          correctAnswerIndex: quest.correctAnswerIndex ?? 0,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          isAnswered: _isAnswered,
                          isCorrect: _isCorrect,
                          onQuadrantSelect: (index) => _onQuadrantSelect(index, quest.correctAnswerIndex ?? 0),
                          isCompact: isCompact,
                        ),
                        SizedBox(height: gapBottom),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
