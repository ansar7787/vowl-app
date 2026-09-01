import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_instruction.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_pulse_zone.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_question_area.dart';
import 'package:vowl/core/presentation/game_mechanics/reading_self_evaluation_card.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_result.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';

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

class _ReadingSpeedCheckScreenState extends State<ReadingSpeedCheckScreen> {
  final _hapticService = di.sl<HapticService>();

  final ValueNotifier<double> _pulseScale = ValueNotifier(1.0);
  final ValueNotifier<double> _clarityRadius = ValueNotifier(0.0);
  final ValueNotifier<int> _timerValue = ValueNotifier(12);
  final ValueNotifier<int> _timeLimit = ValueNotifier(12);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _isRevealed = ValueNotifier(false);

  @override
  void dispose() {
    _pulseScale.dispose();
    _clarityRadius.dispose();
    _timerValue.dispose();
    _timeLimit.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isRevealed.dispose();
    super.dispose();
  }
  
  final _timerKey = GlobalKey<SpeedChallengeTimerState>();

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onPulseTap() {
    if (_isAnswered.value || _isRevealed.value) return;
    _pulseScale.value = 1.4;
    _clarityRadius.value = 1.0;
    _hapticService.selection();

    Future.delayed(150.milliseconds, () {
      if (mounted) {
        _pulseScale.value = 1.0;
      }
    });
    Future.delayed(2.seconds, () {
      if (mounted && !_isAnswered.value && !_isRevealed.value) {
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
    if (_isAnswered.value || !_isRevealed.value) return;

    _isAnswered.value = true;
    _isCorrect.value = isCorrect;

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
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isRevealed.value = false;
            _clarityRadius.value = 0.0;
            _timeLimit.value = state.currentQuest.timeLimit ?? 12;
            _timerValue.value = _timeLimit.value;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _timerKey.currentState?.start();
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('reading_games.speed_demon', fallback: 'SPEED DEMON!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isRevealed, _pulseScale, _clarityRadius, _timerValue, _timeLimit]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
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
                              instruction: quest.instruction,
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
                                wordCount: quest.passageWordCount ?? quest.passage?.split(RegExp(r'\s+')).length ?? 0,
                                wpmTarget: quest.wpmTarget ?? 0,
                                onTapPulse: _onPulseTap,
                              )
                            else ...[
                              SizedBox(height: 32.h),
                              ReadingSelfEvaluationCard(
                                correctAnswer: quest.correctAnswer ?? "",
                                explanation: quest.explanation,
                                primaryColor: theme.primaryColor,
                                onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                              ),
                            ],
                            if (_isAnswered.value) ...[
                              SizedBox(height: 30.h),
                              ReadingSpeedResult(
                                quest: quest,
                                isCorrect: _isCorrect.value == true,
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
            );
          },
        );
      },
    );
  }
}
