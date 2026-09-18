import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_instruction.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_pulse_zone.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_question_area.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/reading_self_evaluation_card.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_result.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class ReadingSpeedCheckScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingSpeedCheckScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingSpeedCheck,
  });

  @override
  State<ReadingSpeedCheckScreen> createState() =>
      _ReadingSpeedCheckScreenState();
}

class _ReadingSpeedCheckScreenState extends State<ReadingSpeedCheckScreen> with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  
  final ValueNotifier<double> _pulseScale = ValueNotifier(1.0);
  final ValueNotifier<double> _clarityRadius = ValueNotifier(0.0);
  final ValueNotifier<int> _timerValue = ValueNotifier(12);
  final ValueNotifier<int> _timeLimit = ValueNotifier(12);
            final ValueNotifier<bool> _isRevealed = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _pulseScale.dispose();
    _clarityRadius.dispose();
    _timerValue.dispose();
    _timeLimit.dispose();
                _isRevealed.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    disposeReadingGame();
    disposeReadingGame();
    super.dispose();
  }

  final _timerKey = GlobalKey<SpeedChallengeTimerState>();

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

    initReadingGame();
  }

  void _onPulseTap() {
    if (isAnsweredNotifier.value || _isRevealed.value) return;
    _pulseScale.value = 1.4;
    _clarityRadius.value = 1.0;
    hapticService.selection();

    Future.delayed(150.milliseconds, () {
      if (mounted) {
        _pulseScale.value = 1.0;
      }
    });
    Future.delayed(2.seconds, () {
      if (mounted && !isAnsweredNotifier.value && !_isRevealed.value) {
        _clarityRadius.value = 0.0;
      }
    });
  }

  void _onTimeUp() {
    if (!mounted) return;
    _isRevealed.value = true;
    _clarityRadius.value = 0.0;
  }

  void _onTimerTick(int remaining) {
    if (!mounted) return;
    _timerValue.value = remaining;
  }

  void _submitSelfEvalAnswer(bool isCorrect, ReadingQuest quest) {
    if (isAnsweredNotifier.value || !_isRevealed.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = isCorrect;

    if (isCorrect) {
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _isRevealed,
            _pulseScale,
            _clarityRadius,
            _timerValue,
            _timeLimit,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
              onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
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
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  ReadingSpeedInstruction(
                                    primaryColor: theme.primaryColor,
                                    isRevealed: _isRevealed.value,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 32.h),
                                  if (!_isRevealed.value)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 24.h),
                                      child: SpeedChallengeTimer(
                                        key: _timerKey,
                                        durationSeconds: _timeLimit.value,
                                        primaryColor: theme.primaryColor,
                                        onTimeUp: _onTimeUp,
                                        onTick: _onTimerTick,
                                        autoStart: true,
                                      ),
                                    ),
                                  if (_isRevealed.value)
                                    ReadingSpeedQuestionArea(
                                      question: quest.question ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!_isRevealed.value)
                                    ReadingSpeedPulseZone(
                                      passage: quest.passage ?? "",
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      clarityRadius: _clarityRadius.value,
                                      pulseScale: _pulseScale.value,
                                      timerValue: _timerValue.value,
                                      timeLimit: _timeLimit.value,
                                      wordCount:
                                          quest.passageWordCount ??
                                          quest.passage
                                              ?.split(RegExp(r'\s+'))
                                              .length ??
                                          0,
                                      wpmTarget: quest.wpmTarget ?? 0,
                                      onTapPulse: _onPulseTap,
                                    )
                                  else ...[
                                    SizedBox(height: 32.h),
                                    ReadingSelfEvaluationCard(
                                      correctAnswer: quest.correctAnswer ?? "",
                                      explanation: quest.explanation,
                                      primaryColor: theme.primaryColor,
                                      onEvaluated: (isCorrect) =>
                                          _submitSelfEvalAnswer(
                                            isCorrect,
                                            quest,
                                          ),
                                    ),
                                  ],
                                  if (isAnsweredNotifier.value) ...[
                                    SizedBox(height: 30.h),
                                    ReadingSpeedResult(
                                      quest: quest,
                                      isCorrect: isCorrectNotifier.value == true,
                                      isDark: isDark,
                                    ),
                                  ],
                                  SizedBox(height: 60.h),
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
