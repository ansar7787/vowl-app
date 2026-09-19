import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_instruction.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_passage.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_statement.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_coin_zone.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_result.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';
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

class _TrueFalseReadingScreenState extends State<TrueFalseReadingScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _coinX = ValueNotifier(0.0);
  final ValueNotifier<double> _coinY = ValueNotifier(0.0);
  final ValueNotifier<double> _coinRotation = ValueNotifier(0.0);

  final ValueNotifier<bool?> _pendingAnswer = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _coinX.dispose();
    _coinY.dispose();
    _coinRotation.dispose();
    _pendingAnswer.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    initReadingGame();
  }

  void _onFlick(Offset delta) {
    if (isAnsweredNotifier.value || _pendingAnswer.value != null) return;
    _coinX.value += delta.dx;
    _coinY.value += delta.dy;
    _coinRotation.value += (delta.dx + delta.dy) / 100;
    hapticService.selection();

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
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
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

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    _coinX.value = _pendingAnswer.value! ? 120.w : -120.w;
    _coinY.value = 0.0;

    hapticService.success();
    soundService.playCorrect();
    // Award bonus coins for finding evidence
    context.read<ReadingBloc>().add(const ReadingSpeakConfirmed(5));
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  void onQuestionReset() {
    _coinX.value = 0.0;

    _coinY.value = 0.0;

    _coinRotation.value = 0.0;

    _pendingAnswer.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingAnswer,
            _coinX,
            _coinY,
            _coinRotation,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
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
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
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
                                      if (isAnsweredNotifier.value) ...[
                                        SizedBox(height: 30.h),
                                        TrueFalseReadingResult(
                                          quest: quest,
                                          isCorrect:
                                              isCorrectNotifier.value == true,
                                          isDark: isDark,
                                        ),
                                      ],
                                      SizedBox(
                                        height:
                                            (_pendingAnswer.value != null &&
                                                !isAnsweredNotifier.value)
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
                        if (_pendingAnswer.value != null &&
                            !isAnsweredNotifier.value)
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
