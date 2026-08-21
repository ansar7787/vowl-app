import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_instruction.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_passage.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_statement.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_coin_zone.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_result.dart';
import 'package:vowl/core/presentation/game_mechanics/evidence_highlight_wrapper.dart';
import 'package:vowl/core/presentation/game_mechanics/error_journal_collector.dart';

class TrueFalseReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TrueFalseReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.trueFalseReading,
  });

  @override
  State<TrueFalseReadingScreen> createState() => _TrueFalseReadingScreenState();
}

class _TrueFalseReadingScreenState extends State<TrueFalseReadingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _coinX = 0.0;
  double _coinY = 0.0;
  double _coinRotation = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  bool? _pendingAnswer;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onFlick(Offset delta) {
    if (_isAnswered || _pendingAnswer != null) return;
    setState(() {
      _coinX += delta.dx;
      _coinY += delta.dy;
      _coinRotation += (delta.dx + delta.dy) / 100;
      _hapticService.selection();
    });

    if (_coinX.abs() > 100.w) {
      final bool pending = _coinX > 0;
      
      final String correct = (context.read<ReadingBloc>().state as ReadingLoaded).currentQuest!.correctAnswer ?? "";
      final bool isCorrect = (pending ? "true" : "false") == correct.trim().toLowerCase();

      if (!isCorrect) {
        setState(() {
          _pendingAnswer = pending;
        });
        _submitFinalAnswer(false, (context.read<ReadingBloc>().state as ReadingLoaded).currentQuest as ReadingQuest, true);
      } else {
        setState(() {
          _pendingAnswer = pending;
        });
      }
    }
  }

  void _submitFinalAnswer(bool nailedEvidence, ReadingQuest quest, [bool failedCoin = false]) {
    if (_pendingAnswer == null) return;

    if (!nailedEvidence || failedCoin) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _coinX = _pendingAnswer! ? 120.w : -120.w;
        _coinY = 0.0;
      });
      ErrorJournalCollector.record(
        userId: 'local',
        gameType: widget.gameType.name,
        question: quest.question ?? quest.instruction,
        userAnswer: failedCoin ? (_pendingAnswer! ? "True" : "False") : 'Failed to find evidence',
        correctAnswer: failedCoin ? (quest.correctAnswer ?? '') : (quest.evidenceLine ?? ''),
        level: widget.level,
      );
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      return;
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _coinX = _pendingAnswer! ? 120.w : -120.w;
      _coinY = 0.0;
    });

    _hapticService.success();
    _soundService.playCorrect();
    // Award bonus coins for finding evidence
    context.read<ReadingBloc>().add(const ReadingSpeakConfirmed(5)); 
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingAnswer = null;
              _coinX = 0.0;
              _coinY = 0.0;
              _coinRotation = 0.0;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('reading_games.fact_checker', fallback: 'FACT CHECKER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 16.h),
                                TrueFalseReadingInstruction(
                                  primaryColor: theme.primaryColor,
                                  instruction: quest.instruction,
                                ),
                                SizedBox(height: 24.h),
                                TrueFalseReadingPassage(
                                  passage: quest.passage ?? "",
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 32.h),
                                TrueFalseReadingStatement(
                                  statement: quest.question ?? "",
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(height: 40.h),
                                TrueFalseReadingCoinZone(
                                  coinX: _coinX,
                                  coinY: _coinY,
                                  coinRotation: _coinRotation,
                                  onFlick: _onFlick,
                                  isDark: isDark,
                                  themeColor: theme.primaryColor,
                                ),
                                if (_isAnswered) ...[
                                  SizedBox(height: 30.h),
                                  TrueFalseReadingResult(
                                    quest: quest,
                                    isCorrect: _isCorrect == true,
                                    isDark: isDark,
                                  ),
                                ],
                                SizedBox(height: 60.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pendingAnswer != null && !_isAnswered)
                      EvidenceHighlightWrapper(
                        passage: quest.passage ?? "",
                        evidenceWords: (quest.evidenceLine ?? quest.passage ?? "").split(RegExp(r'\s+')),
                        primaryColor: theme.primaryColor,
                        onCorrectHighlight: () => _submitFinalAnswer(true, quest),
                        instruction: 'Tap the words that prove your answer',
                      ),
                  ],
                ),
        );
      },
    );
  }
}
