import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_question.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_spinner.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AudioMultipleChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioMultipleChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioMultipleChoice,
  });

  @override
  State<AudioMultipleChoiceScreen> createState() =>
      _AudioMultipleChoiceScreenState();
}

class _AudioMultipleChoiceScreenState extends State<AudioMultipleChoiceScreen>
    with ListeningGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;
  @override
  int get level => widget.level;
  @override
  String getCompletionTitle(BuildContext context) => context.tr(
    'listening.games.audio_multiple_choice_title',
    fallback: 'SONIC RADAR!',
  );

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();

  String? _currentQuestId;
  List<String> _shuffledOptions = [];
  int _shuffledCorrectIndex = 0;

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
    _selectedIndex.dispose();
    _rotation.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    isFirstStagePassedNotifier.value = false;
    _selectedIndex.value = null;
    _rotation.value = 0.0;
  }

  void _submitAnswer(int index, int correct, GameQuest quest) {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    _selectedIndex.value = index;
    bool isCorrect = index == correct;

    if (isCorrect) {
      submitCorrectAnswer();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    } else {
      String userAnswerStr = _shuffledOptions.isNotEmpty
          ? _shuffledOptions[index]
          : index.toString();
      submitWrongAnswer(quest: quest, userAnswer: userAnswerStr);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _submitWrongAnswer(GameQuest quest) {
    submitWrongAnswer(quest: quest, userAnswer: '[Timeout]');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded || current is ListeningGameOver,
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        if (quest != null && quest.id != _currentQuestId) {
          _currentQuestId = quest.id;
          if (quest.options != null && quest.options!.isNotEmpty) {
            final List<String> opts = List.from(quest.options!);
            final originalCorrectWord = opts[quest.correctAnswerIndex ?? 0];
            opts.shuffle();
            _shuffledOptions = opts;
            _shuffledCorrectIndex = opts.indexOf(originalCorrectWord);
          } else {
            _shuffledOptions = [];
            _shuffledCorrectIndex = 0;
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            final correctWord =
                quest?.correctAnswer ??
                (quest?.options != null && quest!.options!.isNotEmpty
                    ? quest.options![quest.correctAnswerIndex ?? 0]
                    : '');

            final displayQuestion = isCorrectNotifier.value == true
                ? (quest?.question?.replaceAll('_____', correctWord) ?? "")
                : (quest?.question ?? "");

            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => dispatchNextQuestion(),
              onHint: () => dispatchHintUsed(),
              useScrolling: false,
              disablePadding: true,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 6.h),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: SpeedChallengeTimer(
                                          key: timerKey,
                                          durationSeconds: 15,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      Text(
                                        quest.instruction,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                      AudioMultipleChoiceQuestion(
                                        text: displayQuestion,
                                        isDark: isDark,
                                      ),
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
                                  child: SizedBox(
                                    height: 340.r,
                                    child: ListenableBuilder(
                                      listenable: Listenable.merge([
                                        _rotation,
                                        _selectedIndex,
                                      ]),
                                      builder: (context, _) {
                                        return AudioMultipleChoiceSpinner(
                                          options: _shuffledOptions,
                                          correct: _shuffledCorrectIndex,
                                          color: theme.primaryColor,
                                          emoji: quest.emoji,
                                          rotation: _rotation.value,
                                          selectedIndex: _selectedIndex.value,
                                          isAnswered: isAnsweredNotifier.value,
                                          isCorrectState:
                                              isCorrectNotifier.value,
                                          onSpin: (delta) {
                                            if (!isAnsweredNotifier.value) {
                                              _rotation.value += delta * 0.01;
                                            }
                                          },
                                          onSelectSatellite: (index) {
                                            _submitAnswer(
                                              index,
                                              _shuffledCorrectIndex,
                                              quest,
                                            );
                                          },
                                          onTapCore: () {
                                            soundService.playTts(
                                              quest.textToSpeak ?? "",
                                            );
                                            hapticService.selection();
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(height: 100.h),
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
