import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_instruction.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_oscilloscope.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_jigsaw_wrapper.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';

class AudioSentenceOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioSentenceOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioSentenceOrder,
  });

  @override
  State<AudioSentenceOrderScreen> createState() =>
      _AudioSentenceOrderScreenState();
}

class _AudioSentenceOrderScreenState extends State<AudioSentenceOrderScreen>
    with ListeningGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
    'listening.games.audio_sentence_order_title',
    fallback: 'SEQUENCE MASTER!',
  );

  final ScrollController _scrollController = ScrollController();

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

    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initListeningGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded || current is ListeningGameOver,
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              onContinue: dispatchNextQuestion,
              onHint: dispatchHintUsed,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.only(
                              left: 24.w,
                              right: 24.w,
                              top: 16.h,
                              bottom:
                                  (isAnsweredNotifier.value ? 200.h : 40.h) +
                                  MediaQuery.of(context).viewInsets.bottom,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 6.h),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 16.h),
                                    child: SpeedChallengeTimer(
                                      key: timerKey!,
                                      durationSeconds: 15,
                                      primaryColor: theme.primaryColor,
                                      onTimeUp: () =>
                                          submitWrongAnswer(quest: quest),
                                    ),
                                  ),
                                  AudioSentenceOrderInstruction(
                                    color: theme.primaryColor,
                                    instruction: context.tr(
                                      'games.audioSentenceOrder_instruction',
                                      fallback: quest.instruction,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  AudioSentenceOrderOscilloscope(
                                    onTap: () {
                                      soundService.playTts(
                                        quest.textToSpeak ?? "",
                                        pauseMarkers: quest.pauseMarkers,
                                      );
                                      hapticService.selection();
                                    },
                                    color: theme.primaryColor,
                                    emoji: quest.emoji,
                                    isCorrectState: isCorrectNotifier.value,
                                  ),
                                  SizedBox(height: 32.h),
                                  DynamicJigsawWrapper(
                                    key: ValueKey(quest.id),
                                    expectedText: quest.textToSpeak ?? "",
                                    customShuffledWords:
                                        quest.shuffledSentences,
                                    customCorrectOrder: quest.correctOrder,
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    allowSkip:
                                        false, // Disables the bypass feature for this game
                                    onConfirmed: () => submitCorrectAnswer(),
                                    onBypassed: () => submitCorrectAnswer(),
                                    onSkipped: () =>
                                        submitWrongAnswer(quest: quest),
                                  ),
                                ],
                              ),
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
