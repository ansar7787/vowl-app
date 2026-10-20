import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
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
    with
        GameScreenMixin<AudioSentenceOrderScreen>,
        ListeningGameScreenMixin<AudioSentenceOrderScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
    'listening.games.audio_sentence_order_title',
    fallback: 'Sentence Order',
  );

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
  void onQuestionReset() {
    super.onQuestionReset();
    timerKey?.currentState?.start();
  }

  void _submitWrongAnswer(GameQuest quest) {
    timerKey?.currentState?.stop();
    submitWrongAnswer(quest: quest);
  }

  void _submitCorrectAnswer() {
    timerKey?.currentState?.stop();
    submitCorrectAnswer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listenWhen: listeningListenWhen,
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded ||
          current is ListeningGameOver ||
          current is ListeningGameComplete,
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
              onHint: () => hapticService.selection(),
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
                                          _submitWrongAnswer(quest),
                                    ),
                                  ),
                                  AudioSentenceOrderInstruction(
                                    key: const Key(
                                      'audio_sentence_order_instruction',
                                    ),
                                    color: theme.primaryColor,
                                    instruction: context.tr(
                                      'games.audioSentenceOrder_instruction',
                                      fallback:
                                          quest.instruction.isNotEmpty
                                              ? quest.instruction
                                              : 'Listen and arrange the words in order.',
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  AudioSentenceOrderOscilloscope(
                                    key: const Key(
                                      'audio_sentence_order_oscilloscope',
                                    ),
                                    onTap: () {
                                      final audioToPlay = quest.textToSpeak ??
                                          quest.prompt ??
                                          quest.question ??
                                          quest.sentence ??
                                          quest.audioTranscript ??
                                          "";
                                      soundService.playTts(
                                        audioToPlay,
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
                                    onConfirmed: () => _submitCorrectAnswer(),
                                    onBypassed: () => _submitCorrectAnswer(),
                                    onSkipped: () =>
                                        _submitWrongAnswer(quest),
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
