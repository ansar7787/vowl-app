import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_instruction.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_question.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_spinner.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

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

class _AudioMultipleChoiceScreenState extends State<AudioMultipleChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(
    false,
  ); // Overall Completion
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _selectedIndex.dispose();
    _rotation.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(int index, int correct, GameQuest quest) {
    if (_isAnswered.value) return;
    _timerKey.currentState?.stop();

    _selectedIndex.value = index;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isCorrect.value = true;
      _isAnswered.value = true;
      context.read<ListeningBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: quest.textToSpeak ?? 'Audio Multiple Choice',
          userAnswer: index.toString(),
          correctAnswer: correct.toString(),
          level: widget.level,
        );
      }

      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
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

  
  void _submitWrongAnswer(dynamic quest) {
    if (_isAnswered.value) return;
    _timerKey.currentState?.stop();

    _hapticService.error();
    _soundService.playWrong();

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      ErrorJournalCollector.record(
        userId: authState.user!.id,
        gameType: widget.gameType.name,
        question: quest.textToSpeak ?? 'Timeout',
        userAnswer: '[Timeout]',
        correctAnswer: '',
        level: widget.level,
      );
    }
    _isAnswered.value = true;
    _isCorrect.value = false;
    context.read<ListeningBloc>().add(SubmitAnswer(false));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

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
            _isFirstStagePassed.value = false;
            _selectedIndex.value = null;
            _rotation.value = 0.0;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
            if (_isCorrect.value == true) {
              _isFirstStagePassed.value = true;
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SONIC RADAR!',
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
            _isFirstStagePassed,
            _selectedIndex,
            _rotation,
          ]),
          builder: (context, _) {
            final correctWord =
                quest?.correctAnswer ??
                (quest?.options != null && quest!.options!.isNotEmpty
                    ? quest.options![quest.correctAnswerIndex ?? 0]
                    : '');

            final displayQuestion = _isCorrect.value == true
                ? (quest?.question?.replaceAll('_____', correctWord) ?? "")
                : (quest?.question ?? "");

            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<ListeningBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<ListeningBloc>().add(ListeningHintUsed()),
              useScrolling: false,
              disablePadding: true,
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
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [                                      SizedBox(height: 6.h),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: SpeedChallengeTimer(
                                          key: _timerKey,
                                          durationSeconds: 15,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () => _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      AudioMultipleChoiceInstruction(
                                        instruction: quest.instruction,
                                        color: theme.primaryColor,
                                      ),
                                      SizedBox(height: 24.h),
                                      AudioMultipleChoiceQuestion(
                                        text: displayQuestion,
                                        isDark: isDark,
                                      ),
                                      if (_isAnswered.value &&
                                          _isCorrect.value == false &&
                                          quest.explanation != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: 16.h),
                                          child: Container(
                                            padding: EdgeInsets.all(16.r),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              border: Border.all(
                                                color: Colors.amber.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  color: Colors.amber,
                                                  size: 24.r,
                                                ),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child: Text(
                                                    quest.explanation!,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 14.sp,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                                    height: 320.h,
                                    child: AudioMultipleChoiceSpinner(
                                      options: quest.options ?? [],
                                      correct: quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      emoji: quest.emoji,
                                      rotation: _rotation.value,
                                      selectedIndex: _selectedIndex.value,
                                      isAnswered: _isAnswered.value,
                                      isCorrectState: _isCorrect.value,
                                      onSpin: (delta) {
                                        if (!_isAnswered.value) {
                                          _rotation.value += delta * 0.01;
                                        }
                                      },
                                      onSelectSatellite: (index) {
                                        _submitFinalAnswer(
                                          index,
                                          quest.correctAnswerIndex ?? 0,
                                          quest,
                                        );
                                      },
                                      onTapCore: () {
                                        _soundService.playTts(
                                          quest.textToSpeak ?? "",
                                        );
                                        _hapticService.selection();
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
