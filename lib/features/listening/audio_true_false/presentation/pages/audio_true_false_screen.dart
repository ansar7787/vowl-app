import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_instruction.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_tuner.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_screen_display.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_verdict_buttons.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

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

class _AudioTrueFalseScreenState extends State<AudioTrueFalseScreen>with SingleTickerProviderStateMixin, ListeningGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

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

    _audioController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    initListeningGame();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitFinalAnswer(ListeningQuest quest) {
    if (isAnsweredNotifier.value || _selectedVerdict.value == null) return;
    _timerKey.currentState?.stop();

    final correct = quest.correctAnswer ?? "";
    bool isCorrect =
        _selectedVerdict.value.toString().toLowerCase() ==
        correct.trim().toLowerCase();

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
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
          question:
              'Audio: ${quest.audioTranscript}\nStatement: ${quest.statement}',
          userAnswer: _selectedVerdict.value.toString(),
          correctAnswer: correct,
          level: widget.level,
        );
      }

      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitWrongAnswer(ListeningQuest quest) {
    if (isAnsweredNotifier.value) return;
    _timerKey.currentState?.stop();

    hapticService.error();
    soundService.playWrong();

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      ErrorJournalCollector.record(
        userId: authState.user!.id,
        gameType: widget.gameType.name,
        question:
            'Audio: ${quest.audioTranscript}\nStatement: ${quest.statement}',
        userAnswer: '[Timeout]',
        correctAnswer: '',
        level: widget.level,
      );
    }
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = false;
    context.read<ListeningBloc>().add(SubmitAnswer(false));
  }

  void _playAudio(String? textToSpeak) {
    final text = textToSpeak?.trim();
    if (text == null || text.isEmpty) return;
    if (text.startsWith('http')) {
      soundService.playUrl(text);
    } else {
      soundService.playTts(text);
    }
    _audioController.forward(from: 0);
    hapticService.selection();
  }

  @override

  void onQuestionReset() {

    _selectedVerdict.value = null;

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
                                          key: _timerKey,
                                          durationSeconds: 15,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      AudioTrueFalseInstruction(
                                        color: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 32.h),
                                      AudioTrueFalseTuner(
                                        onTap: () =>
                                            _playAudio(quest.textToSpeak),
                                        color: theme.primaryColor,
                                        audioController: _audioController,
                                      ),
                                      SizedBox(height: 32.h),
                                      AudioTrueFalseScreenDisplay(
                                        statement: quest.statement ?? '',
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
                                  height: isAnsweredNotifier.value ? 200.h : 60.h,
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
