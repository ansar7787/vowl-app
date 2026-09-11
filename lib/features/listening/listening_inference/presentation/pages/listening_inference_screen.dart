import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_instruction.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_radar_core.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_grid.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_explanation.dart';

class ListeningInferenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ListeningInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.listeningInference,
  });

  @override
  State<ListeningInferenceScreen> createState() =>
      _ListeningInferenceScreenState();
}

class _ListeningInferenceScreenState extends State<ListeningInferenceScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  late AnimationController _pulseController;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedIndex.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(int index, int correct, dynamic quest) {
    if (_isAnswered.value) return;
    _timerKey.currentState?.stop();
    _pulseController.stop();

    _selectedIndex.value = index;
    bool isCorrect = index == correct;

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
          question: quest.textToSpeak ?? 'Listening Inference',
          userAnswer: (quest.options != null && quest.options.length > index)
              ? quest.options[index]
              : index.toString(),
          correctAnswer:
              (quest.options != null && quest.options.length > correct)
              ? quest.options[correct]
              : correct.toString(),
          level: widget.level,
        );
      }

      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitWrongAnswer(dynamic quest) {
    if (_isAnswered.value) return;
    _timerKey.currentState?.stop();
    _pulseController.stop();

    _hapticService.error();
    _soundService.playWrong();

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
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

  void _showTranscriptBottomSheet(
    BuildContext context,
    String text,
    dynamic theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.closed_caption_rounded,
                      color: theme.primaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "AUDIO TRANSCRIPT",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    elevation: 0,
                  ),
                  child: Text(
                    "CLOSE",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _selectedIndex.value = null;
            _pulseController.repeat();
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
            _pulseController.stop();
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'INFERENCE MASTER!',
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
            _selectedIndex,
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
                                      ListeningInferenceInstruction(
                                        color: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      ListeningInferenceRadarCore(
                                        onTap: () {
                                          _soundService.playTts(
                                            quest.textToSpeak ?? "",
                                          );
                                          _hapticService.selection();
                                        },
                                        pulseController: _pulseController,
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                        isCorrectState: _isCorrect.value,
                                      ),
                                      SizedBox(height: 16.h),
                                      GestureDetector(
                                        onTap: () {
                                          _hapticService.selection();
                                          _showTranscriptBottomSheet(
                                            context,
                                            quest.textToSpeak ?? '',
                                            theme,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              30.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.closed_caption_rounded,
                                                size: 16.r,
                                                color: theme.primaryColor,
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                'SHOW TEXT',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme.primaryColor,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Text(
                                          quest.question?.toUpperCase() ??
                                              "INFER THE MEANING",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: theme.primaryColor,
                                            letterSpacing: 1.2,
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ListeningInferenceGrid(
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        isAnswered: _isAnswered.value,
                                        isCorrectState: _isCorrect.value,
                                        selectedIndex: _selectedIndex.value,
                                        onSubmitAnswer: (index) {
                                          _submitFinalAnswer(
                                            index,
                                            quest.correctAnswerIndex ?? 0,
                                            quest,
                                          );
                                        },
                                      ),
                                      if (_isAnswered.value &&
                                          quest.explanation != null)
                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeOutBack,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                            ),
                                            child:
                                                ListeningInferenceExplanation(
                                                  explanation:
                                                      quest.explanation!,
                                                  color: theme.primaryColor,
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
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
