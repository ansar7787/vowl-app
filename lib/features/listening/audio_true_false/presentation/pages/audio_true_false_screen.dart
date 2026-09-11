import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_instruction.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_tuner.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_screen_display.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_verdict_buttons.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
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

class _AudioTrueFalseScreenState extends State<AudioTrueFalseScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool?> _selectedVerdict = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  late AnimationController _audioController;

  @override
  void dispose() {
    _audioController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedVerdict.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _audioController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
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
    if (_isAnswered.value || _selectedVerdict.value == null) return;
    _timerKey.currentState?.stop();

    final correct = quest.correctAnswer ?? "";
    bool isCorrect =
        _selectedVerdict.value.toString().toLowerCase() ==
        correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

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

      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitWrongAnswer(ListeningQuest quest) {
    if (_isAnswered.value) return;
    _timerKey.currentState?.stop();

    _hapticService.error();
    _soundService.playWrong();

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
    _isAnswered.value = true;
    _isCorrect.value = false;
    context.read<ListeningBloc>().add(SubmitAnswer(false));
  }

  void _playAudio(String? textToSpeak) {
    final text = textToSpeak?.trim();
    if (text == null || text.isEmpty) return;
    if (text.startsWith('http')) {
      _soundService.playUrl(text);
    } else {
      _soundService.playTts(text);
    }
    _audioController.forward(from: 0);
    _hapticService.selection();
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
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _timerKey.currentState?.start();
            _isCorrect.value = null;
            _selectedVerdict.value = null;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FACT VERDICTOR!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _selectedVerdict,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              useScrolling: false,
              disablePadding: true,
              onContinue: () =>
                  context.read<ListeningBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<ListeningBloc>().add(ListeningHintUsed()),
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
                                        emoji: quest.emoji,
                                      ),
                                      SizedBox(height: 24.h),
                                      AudioTrueFalseTuner(
                                        onTap: () =>
                                            _playAudio(quest.textToSpeak),
                                        color: theme.primaryColor,
                                        audioController: _audioController,
                                      ),
                                      SizedBox(height: 32.h),
                                      AudioTrueFalseScreenDisplay(
                                        statement: quest.statement ?? "",
                                        color: theme.primaryColor,
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
                                    isAnswered: _isAnswered.value,
                                    isCorrectState: _isCorrect.value,
                                    onVerdictSelected: (v) {
                                      if (_isAnswered.value ||
                                          _selectedVerdict.value != null) {
                                        return;
                                      }
                                      _hapticService.selection();
                                      _selectedVerdict.value = v;
                                      _submitFinalAnswer(quest);
                                      _scrollToBottom();
                                    },
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: _isAnswered.value ? 200.h : 60.h,
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
