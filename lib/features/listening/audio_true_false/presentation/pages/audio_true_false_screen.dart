import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_instruction.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_tuner.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_screen_display.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_verdict_buttons.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class AudioTrueFalseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioTrueFalseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioTrueFalse,
  });

  @override
  State<AudioTrueFalseScreen> createState() => _AudioTrueFalseScreenState();
}

class _AudioTrueFalseScreenState extends State<AudioTrueFalseScreen>
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<AudioTrueFalseScreen>,
        ListeningGameScreenMixin<AudioTrueFalseScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool?> _selectedVerdict = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  late AnimationController _audioController;

  @override
  void dispose() {
    _audioController.dispose();
    _selectedVerdict.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    _audioController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    initListeningGame();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final reduceMotion = VowlMotion.shouldReduceMotion(context);
        if (reduceMotion) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _submitFinalAnswer(ListeningQuest quest) {
    if (isAnsweredNotifier.value || _selectedVerdict.value == null) return;
    timerKey?.currentState?.stop();

    final correct = (quest.correctAnswer ?? "").trim().toLowerCase();
    bool isCorrect = false;
    if (_selectedVerdict.value == true) {
      isCorrect = correct == "true" || correct == "1" || correct == "yes";
    } else if (_selectedVerdict.value == false) {
      isCorrect = correct == "false" || correct == "0" || correct == "no";
    }

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(
        quest: quest,
        userAnswer: _selectedVerdict.value.toString(),
      );
    }
  }

  void _submitWrongAnswer(ListeningQuest quest) {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();
    submitWrongAnswer(quest: quest, userAnswer: '[Timeout]');
  }

  void _playAudio(ListeningQuest quest) {
    final rawAudio = quest.textToSpeak ??
        quest.prompt ??
        quest.question ??
        quest.sentence ??
        quest.audioTranscript ??
        quest.statement ??
        "";
    final text = rawAudio.trim();
    if (text.isEmpty) return;
    if (text.startsWith('http')) {
      soundService.playUrl(text);
    } else {
      soundService.playTts(text, pauseMarkers: quest.pauseMarkers);
    }
    _audioController.forward(from: 0);
    hapticService.selection();
  }

  @override
  void onQuestionReset() {
    _selectedVerdict.value = null;
    timerKey?.currentState?.start();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'listening',
      level: widget.level,
      isDark: isDark,
    );

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
            _selectedVerdict,
          ]),
          builder: (context, _) {
            final statementText = quest != null
                ? (quest.statement ?? quest.question ?? quest.prompt ?? '')
                : '';

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
                                  horizontal: 24.w,
                                  vertical: 24.h,
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
                                          durationSeconds: 15,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      AudioTrueFalseInstruction(
                                        key: const Key(
                                          'audio_true_false_instruction',
                                        ),
                                        color: theme.primaryColor,
                                        instruction: context.tr(
                                          'games.audioTrueFalse_instruction',
                                          fallback:
                                              quest.instruction.isNotEmpty
                                                  ? quest.instruction
                                                  : 'IS THIS STATEMENT TRUE OR FALSE? LISTEN CAREFULLY.',
                                        ),
                                      ),
                                      SizedBox(height: 32.h),
                                      AudioTrueFalseTuner(
                                        key: const Key('audio_true_false_tuner'),
                                        onTap: () => _playAudio(quest),
                                        color: theme.primaryColor,
                                        audioController: _audioController,
                                      ),
                                      SizedBox(height: 32.h),
                                      AudioTrueFalseScreenDisplay(
                                        key: const Key(
                                          'audio_true_false_screen_display',
                                        ),
                                        statement: statementText,
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                    vertical: 16.h,
                                  ),
                                  child: AudioTrueFalseVerdictButtons(
                                    key: const Key(
                                      'audio_true_false_verdict_buttons',
                                    ),
                                    selectedVerdict: _selectedVerdict.value,
                                    isAnswered: isAnsweredNotifier.value,
                                    isCorrectState: isCorrectNotifier.value,
                                    onVerdictSelected: (v) {
                                      if (isAnsweredNotifier.value ||
                                          _selectedVerdict.value != null) {
                                        return;
                                      }
                                      hapticService.selection();
                                      _selectedVerdict.value = v;
                                      _submitFinalAnswer(quest);
                                      _scrollToBottom();
                                    },
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: isAnsweredNotifier.value
                                      ? 200.h
                                      : 60.h,
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
