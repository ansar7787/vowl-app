import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
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
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_target_badge.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_terminal.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class SkimmingScanningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SkimmingScanningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.skimmingScanning,
  });

  @override
  State<SkimmingScanningScreen> createState() => _SkimmingScanningScreenState();
}

class _SkimmingScanningScreenState extends State<SkimmingScanningScreen>
    with
        GameScreenMixin<SkimmingScanningScreen>,
        ReadingGameScreenMixin<SkimmingScanningScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late ScrollController _scrollController;
  late ScrollController _mainScrollController;
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mainScrollController = ScrollController();
    initReadingGame();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || isAnsweredNotifier.value) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 28),
          curve: Curves.linear,
        );
      }
    });
  }

  void _submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    _timerKey.currentState?.stop();
    context.read<ReadingBloc>().add(SubmitAnswer(true));
  }

  void _submitIncorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    hapticService.error();
    soundService.playWrong();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = false;
    _timerKey.currentState?.stop();
    context.read<ReadingBloc>().add(SubmitAnswer(false));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainScrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

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
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
              onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _mainScrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _mainScrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  SkimmingScanningTargetBadge(
                                    item:
                                        quest.targetInfo ??
                                        quest.targetItem ??
                                        "",
                                    color: theme.primaryColor,
                                  ),
                                  SizedBox(height: 16.h),

                                  if (!isAnsweredNotifier.value)
                                    SpeedChallengeTimer(
                                      key: _timerKey,
                                      durationSeconds: 30,
                                      primaryColor: theme.primaryColor,
                                      onTimeUp: _submitIncorrectAnswer,
                                      showBonusLabel: false,
                                    ),

                                  SizedBox(height: 16.h),

                                  // Scanning Terminal Box
                                  SizedBox(
                                    height: 260.h,
                                    width: double.infinity,
                                    child: SkimmingScanningTerminal(
                                      text: quest.passage ?? "",
                                      correct: quest.correctAnswer ?? "",
                                      color: theme.primaryColor,
                                      scrollController: _scrollController,
                                      isAnswered: isAnsweredNotifier.value,
                                      onTapWord: (clean) {
                                        if (clean.toLowerCase() ==
                                            (quest.correctAnswer ?? "")
                                                .toLowerCase()) {
                                          _submitCorrectAnswer();
                                        } else {
                                          _submitIncorrectAnswer();
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Text(
                                    isAnsweredNotifier.value
                                        ? "TARGET ACQUIRED!"
                                        : (InstructionHelper.getInstruction(
                                            quest,
                                          ).toUpperCase()),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: isAnsweredNotifier.value
                                          ? tokens.gameCorrect
                                          : theme.primaryColor,
                                      fontSize: 12.sp,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [SizedBox(height: 50.h)],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
                                        40.h
                                  : 120.h,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
