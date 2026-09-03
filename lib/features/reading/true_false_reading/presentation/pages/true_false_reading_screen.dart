import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/core/services/error_journal_collector.dart';

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

  final ValueNotifier<double> _coinX = ValueNotifier(0.0);
  final ValueNotifier<double> _coinY = ValueNotifier(0.0);
  final ValueNotifier<double> _coinRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  final ValueNotifier<bool?> _pendingAnswer = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _coinX.dispose();
    _coinY.dispose();
    _coinRotation.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingAnswer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onFlick(Offset delta) {
    if (_isAnswered.value || _pendingAnswer.value != null) return;
    _coinX.value += delta.dx;
    _coinY.value += delta.dy;
    _coinRotation.value += (delta.dx + delta.dy) / 100;
    _hapticService.selection();

    if (_coinX.value.abs() > 100.w) {
      final bool pending = _coinX.value > 0;

      final String correct =
          (context.read<ReadingBloc>().state as ReadingLoaded)
              .currentQuest
              .correctAnswer ??
          "";
      final bool isCorrect =
          (pending ? "true" : "false") == correct.trim().toLowerCase();

      if (!isCorrect) {
        _pendingAnswer.value = pending;
        _submitFinalAnswer(
          false,
          (context.read<ReadingBloc>().state as ReadingLoaded).currentQuest,
          true,
        );
      } else {
        _pendingAnswer.value = pending;
      }
    }
  }

  void _submitFinalAnswer(
    bool nailedEvidence,
    ReadingQuest quest, [
    bool failedCoin = false,
  ]) {
    if (_pendingAnswer.value == null) return;

    if (!nailedEvidence || failedCoin) {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _coinX.value = _pendingAnswer.value! ? 120.w : -120.w;
      _coinY.value = 0.0;
      ErrorJournalCollector.record(
        userId: 'local',
        gameType: widget.gameType.name,
        question: quest.question ?? InstructionHelper.getInstruction(quest),
        userAnswer: failedCoin
            ? (_pendingAnswer.value! ? "True" : "False")
            : 'Failed to find evidence',
        correctAnswer: failedCoin
            ? (quest.correctAnswer ?? '')
            : (quest.evidenceLine ?? ''),
        level: widget.level,
      );
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      return;
    }

    _isAnswered.value = true;
    _isCorrect.value = true;
    _coinX.value = _pendingAnswer.value! ? 120.w : -120.w;
    _coinY.value = 0.0;

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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingAnswer.value = null;
            _coinX.value = 0.0;
            _coinY.value = 0.0;
            _coinRotation.value = 0.0;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'reading_games.fact_checker',
              fallback: 'FACT CHECKER!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _pendingAnswer,
            _coinX,
            _coinY,
            _coinRotation,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
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
                                        instruction: InstructionHelper.getInstruction(quest),
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
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(height: 40.h),
                                      TrueFalseReadingCoinZone(
                                        coinX: _coinX.value,
                                        coinY: _coinY.value,
                                        coinRotation: _coinRotation.value,
                                        onFlick: _onFlick,
                                        isDark: isDark,
                                        themeColor: theme.primaryColor,
                                      ),
                                      if (_isAnswered.value) ...[
                                        SizedBox(height: 30.h),
                                        TrueFalseReadingResult(
                                          quest: quest,
                                          isCorrect: _isCorrect.value == true,
                                          isDark: isDark,
                                        ),
                                      ],
                                      SizedBox(
                                        height:
                                            (_pendingAnswer.value != null &&
                                                !_isAnswered.value)
                                            ? 380.h
                                            : 60.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_pendingAnswer.value != null && !_isAnswered.value)
                          EvidenceHighlightWrapper(
                            passage: quest.passage ?? "",
                            evidenceWords:
                                (quest.evidenceLine ?? quest.passage ?? "")
                                    .split(RegExp(r'\s+')),
                            primaryColor: theme.primaryColor,
                            onCorrectHighlight: () =>
                                _submitFinalAnswer(true, quest),
                            instruction: 'Tap the words that prove your answer',
                            isPositioned: true,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
