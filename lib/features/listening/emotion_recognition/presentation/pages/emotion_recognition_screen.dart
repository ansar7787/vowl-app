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
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_instruction.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_emitter.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_quadrant.dart';

/// Screen for the Emotion Recognition listening quest.
///
/// Prompts the user to listen to emotional tone and vocal cadence, then drag
/// the psychology core or tap one of four emotion quadrant reservoir cards.
class EmotionRecognitionScreen extends StatefulWidget {
  /// Progression level index.
  final int level;

  /// Specific game subtype variant.
  final GameSubtype gameType;

  /// Creates an [EmotionRecognitionScreen] instance.
  const EmotionRecognitionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emotionRecognition,
  });

  @override
  State<EmotionRecognitionScreen> createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen>
    with
        GameScreenMixin<EmotionRecognitionScreen>,
        ListeningGameScreenMixin<EmotionRecognitionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'Level Complete!';

  final ValueNotifier<Offset> _coreOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pendingSelectedIndex.dispose();
    _coreOffset.dispose();
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

  void _onCoreMove(Offset delta, BoxConstraints constraints) {
    if (isAnsweredNotifier.value) return;
    double nextX = (_coreOffset.value.dx + delta.dx).clamp(
      -constraints.maxWidth / 2 + 40.r,
      constraints.maxWidth / 2 - 40.r,
    );
    double nextY = (_coreOffset.value.dy + delta.dy).clamp(
      -constraints.maxHeight / 2 + 40.r,
      constraints.maxHeight / 2 - 40.r,
    );
    _coreOffset.value = Offset(nextX, nextY);
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

  void _playAudio(ListeningQuest quest) {
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
      soundService.playTts(text, pauseMarkers: quest.pauseMarkers);
    }
    hapticService.selection();
  }

  @override
  void onQuestionReset() {
    _coreOffset.value = Offset.zero;
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
                                      EmotionRecognitionInstruction(
                                        key: const Key(
                                          'emotion_recognition_instruction',
                                        ),
                                        isAnswered: isAnsweredNotifier.value,
                                        color: theme.primaryColor,
                                        instruction: context.tr(
                                          'games.emotionRecognition_instruction',
                                          fallback:
                                              quest.instruction.isNotEmpty
                                                  ? quest.instruction
                                                  : "How is the speaker feeling?",
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                      EmotionRecognitionEmitter(
                                        key: const Key(
                                          'emotion_recognition_emitter',
                                        ),
                                        onTap: () => _playAudio(quest),
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                        isCorrectState: isCorrectNotifier.value,
                                      ),
                                      SizedBox(height: 32.h),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: 350.h,
                                        child: EmotionRecognitionQuadrant(
                                          key: const Key(
                                            'emotion_recognition_quadrant',
                                          ),
                                          options: quest.options ?? [],
                                          optionEmojis:
                                              quest.optionEmojis ?? [],
                                          correctAnswerIndex:
                                              quest.correctAnswerIndex ?? 0,
                                          color: theme.primaryColor,
                                          isAnswered: isAnsweredNotifier.value,
                                          isCorrectState:
                                              isCorrectNotifier.value,
                                          selectedIndex: _selectedIndex.value,
                                          coreOffset: _coreOffset,
                                          onCoreMove: _onCoreMove,
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
