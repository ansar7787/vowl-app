import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_instruction.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_passage.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_result.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class ReadingConclusionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingConclusionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingConclusion,
  });

  @override
  State<ReadingConclusionScreen> createState() =>
      _ReadingConclusionScreenState();
}

class _ReadingConclusionScreenState extends State<ReadingConclusionScreen> {
  final _hapticService = di.sl<HapticService>();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(bool isCorrect, ReadingQuest quest) {
    _isAnswered.value = true;
    _isCorrect.value = isCorrect;

    if (isCorrect) {
      _hapticService.success();
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
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
              'reading_games.final_verdict_delivered',
              fallback: 'FINAL VERDICT DELIVERED!',
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
                                      ReadingConclusionInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction: quest.instruction,
                                      ),
                                      SizedBox(height: 32.h),

                                      ReadingConclusionPassage(
                                        passage: quest.passage ?? "",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 32.h),

                                      Text(
                                        quest.question?.toUpperCase() ??
                                            "WHAT IS THE LOGICAL CONCLUSION?",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          color: theme.primaryColor,
                                          letterSpacing: 1.5,
                                        ),
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
                                      if (_isAnswered.value) ...[
                                        SizedBox(height: 30.h),
                                        ReadingConclusionResult(
                                          quest: quest,
                                          isCorrect: _isCorrect.value == true,
                                          isDark: isDark,
                                        ),
                                      ],
                                      SizedBox(
                                        height: (!_isAnswered.value)
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
                        if (!_isAnswered.value)
                          TypeToConfirmOverlay(
                            expectedText: quest.correctAnswer ?? "",
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true, quest),
                            onSkipped: () => _submitFinalAnswer(false, quest),
                            allowSkip: true,
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
