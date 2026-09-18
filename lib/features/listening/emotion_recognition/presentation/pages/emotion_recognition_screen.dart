import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_instruction.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_emitter.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_quadrant.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class EmotionRecognitionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmotionRecognitionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emotionRecognition,
  });

  @override
  State<EmotionRecognitionScreen> createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> with ListeningGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

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
    _timerKey.currentState?.stop();

    final correct = quest.correctAnswerIndex ?? 0;
    bool isCorrect = _pendingSelectedIndex.value == correct;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      _selectedIndex.value = _pendingSelectedIndex.value;
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: quest.textToSpeak ?? 'Emotion Recognition',
          userAnswer:
              quest.options != null &&
                  _pendingSelectedIndex.value! < quest.options!.length
              ? quest.options![_pendingSelectedIndex.value!]
              : _pendingSelectedIndex.value.toString(),
          correctAnswer:
              quest.options != null && correct < quest.options!.length
              ? quest.options![correct]
              : correct.toString(),
          level: widget.level,
        );
      }

      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _selectedIndex.value = _pendingSelectedIndex.value;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitWrongAnswer(GameQuest quest) {
    if (isAnsweredNotifier.value) return;
    _timerKey.currentState?.stop();

    hapticService.error();
    soundService.playWrong();

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      int correctIndex = quest.correctAnswerIndex ?? 0;
      ErrorJournalCollector.record(
        userId: authState.user!.id,
        gameType: widget.gameType.name,
        question: quest.textToSpeak ?? 'Emotion Recognition',
        userAnswer: '[Timeout]',
        correctAnswer:
            quest.options != null && correctIndex < quest.options!.length
            ? quest.options![correctIndex]
            : correctIndex.toString(),
        level: widget.level,
      );
    }

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = false;
    context.read<ListeningBloc>().add(SubmitAnswer(false));
  }

  @override

  void onQuestionReset() {

    _coreOffset.value = Offset.zero;

    _selectedIndex.value = null;

    _pendingSelectedIndex.value = null;

  }

  @override

  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listenWhen: listeningListenWhen,
      listener: onListeningStateChanged,
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
              onContinue: () =>
                  context.read<ListeningBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<ListeningBloc>().add(ListeningHintUsed()),
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
                                          key: _timerKey,
                                          durationSeconds: 15,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      EmotionRecognitionInstruction(
                                        isAnswered: isAnsweredNotifier.value,
                                        color: theme.primaryColor,
                                        instruction: "DETECT EMOTION",
                                      ),
                                      SizedBox(height: 24.h),
                                      EmotionRecognitionEmitter(
                                        onTap: () {
                                          soundService.playTts(
                                            quest.textToSpeak ?? "",
                                          );
                                          hapticService.selection();
                                        },
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
                                          options: quest.options ?? [],
                                          optionEmojis:
                                              quest.optionEmojis ?? [],
                                          correctAnswerIndex:
                                              quest.correctAnswerIndex ?? 0,
                                          color: theme.primaryColor,
                                          isAnswered: isAnsweredNotifier.value,
                                          isCorrectState: isCorrectNotifier.value,
                                          selectedIndex: _selectedIndex.value,
                                          coreOffset: _coreOffset,
                                          onCoreMove: _onCoreMove,
                                          onSubmitAnswer: (index) {
                                            if (isAnsweredNotifier.value ||
                                                _pendingSelectedIndex.value !=
                                                    null) {
                                              return;
                                            }
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
