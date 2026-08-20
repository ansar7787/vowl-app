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
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_jigsaw_wrapper.dart';

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

  void _submitAnswer(bool correct) {
    if (_isAnswered) return;

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'SENTINEL!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;

        String targetText = "";
        if (quest != null) {
          if (quest.options != null &&
              quest.options!.isNotEmpty &&
              quest.correctAnswerIndex != null &&
              quest.correctAnswerIndex! < quest.options!.length) {
            targetText = quest.options![quest.correctAnswerIndex!];
          } else {
            targetText = quest.correctAnswer ?? quest.sentence ?? "";
          }
        }

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: false, // Stack needs finite space to anchor to bottom
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 24.h),
                            GrammarQuestInstruction(
                              primaryColor: theme.primaryColor,
                            ),
                            SizedBox(height: 24.h),
                            if (_isAnswered)
                              Text(
                                targetText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.w), // No padding for Jigsaw wrapper as it provides its own padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isAnswered && targetText.isNotEmpty)
                              DynamicJigsawWrapper(
                                expectedText: targetText,
                                primaryColor: theme.primaryColor,
                                onConfirmed: () => _submitAnswer(true),
                                onSkipped: () => _submitAnswer(false),
                                isPositioned: false,
                              ),
                            SizedBox(height: _isAnswered ? 160.h : 60.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
