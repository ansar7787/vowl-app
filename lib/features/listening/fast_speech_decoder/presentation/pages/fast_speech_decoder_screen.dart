import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_instruction.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_gauges.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_core.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_steam_vents.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class FastSpeechDecoderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FastSpeechDecoderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fastSpeechDecoder,
  });

  @override
  State<FastSpeechDecoderScreen> createState() =>
      _FastSpeechDecoderScreenState();
}

class _FastSpeechDecoderScreenState extends State<FastSpeechDecoderScreen>
    with
        GameScreenMixin<FastSpeechDecoderScreen>,
        ListeningGameScreenMixin<FastSpeechDecoderScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _dialRotation = ValueNotifier(0.33);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pendingSelectedIndex.dispose();
    _dialRotation.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initListeningGame();
  }

  void _onRotate(double delta) {
    if (isAnsweredNotifier.value) return;
    double oldVal = _dialRotation.value;
    _dialRotation.value = (_dialRotation.value + delta / 300).clamp(0.0, 1.0);

    // Haptic tick for every 0.1x change
    if ((oldVal * 10).floor() != (_dialRotation.value * 10).floor()) {
      hapticService.light();
    }
  }

  void _submitFinalAnswer(GameQuest quest) {
    if (isAnsweredNotifier.value || _pendingSelectedIndex.value == null) return;
    timerKey?.currentState?.stop();

    final correct = quest.correctAnswerIndex ?? 0;
    bool isCorrect = _pendingSelectedIndex.value == correct;

    _selectedIndex.value = _pendingSelectedIndex.value;
    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      String uAns =
          quest.options != null &&
              _pendingSelectedIndex.value! < quest.options!.length
          ? quest.options![_pendingSelectedIndex.value!]
          : _pendingSelectedIndex.value.toString();

      submitWrongAnswer(quest: quest, userAnswer: uAns);
    }
  }

  void _submitWrongAnswer(dynamic quest) {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();
    if (quest is GameQuest) {
      submitWrongAnswer(quest: quest, userAnswer: '[Timeout]');
    }
  }

  void _playAudio(ListeningQuest quest, double speed) {
    final rawAudio = quest.textToSpeak ??
        quest.prompt ??
        quest.question ??
        quest.sentence ??
        quest.audioTranscript ??
        "";
    final text = rawAudio.trim();
    if (text.isEmpty) return;
    if (text.startsWith('http')) {
      soundService.playUrl(text);
    } else {
      soundService.playTts(text, speed: speed, pauseMarkers: quest.pauseMarkers);
    }
    hapticService.selection();
  }

  @override
  void onQuestionReset() {
    _dialRotation.value = 0.33;
    _selectedIndex.value = null;
    _pendingSelectedIndex.value = null;
    timerKey?.currentState?.start();
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
            _selectedIndex,
            _pendingSelectedIndex,
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 6.h),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: SpeedChallengeTimer(
                                          key: timerKey,
                                          durationSeconds: 30,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      FastSpeechDecoderInstruction(
                                        key: const Key(
                                          'fast_speech_decoder_instruction',
                                        ),
                                        color: theme.primaryColor,
                                        instruction: context.tr(
                                          'games.fastSpeechDecoder_instruction',
                                          fallback:
                                              quest.instruction.isNotEmpty
                                                  ? quest.instruction
                                                  : 'Listen to the fast speech and choose the correct sentence.',
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                      ValueListenableBuilder<double>(
                                        valueListenable: _dialRotation,
                                        builder: (context, rotation, child) {
                                          double speed = 0.3 + (rotation * 0.6);
                                          return Column(
                                            children: [
                                              FastSpeechDecoderGauges(
                                                key: const Key(
                                                  'fast_speech_decoder_gauges',
                                                ),
                                                speed: speed * 2,
                                                color: theme.primaryColor,
                                              ),
                                              SizedBox(height: 20.h),
                                              FastSpeechDecoderCore(
                                                key: const Key(
                                                  'fast_speech_decoder_core',
                                                ),
                                                textToSpeak:
                                                    quest.textToSpeak ?? "",
                                                speed: speed,
                                                color: theme.primaryColor,
                                                rotation: rotation,
                                                onRotate: _onRotate,
                                                onTapTts: () =>
                                                    _playAudio(quest, speed),
                                                emoji: quest.emoji,
                                                isCorrectState:
                                                    isCorrectNotifier.value,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FastSpeechDecoderSteamVents(
                                        key: const Key(
                                          'fast_speech_decoder_steam_vents',
                                        ),
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        isAnswered: isAnsweredNotifier.value,
                                        isCorrectState:
                                            isCorrectNotifier.value,
                                        selectedIndex:
                                            _selectedIndex.value,
                                        onSubmitAnswer: (index) {
                                          if (isAnsweredNotifier.value ||
                                              _pendingSelectedIndex.value !=
                                                  null) {
                                            return;
                                          }
                                          hapticService.selection();
                                          _pendingSelectedIndex.value = index;
                                          _submitFinalAnswer(quest);
                                        },
                                      ),
                                      SizedBox(
                                        height: isAnsweredNotifier.value
                                            ? 200.h
                                            : 60.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
