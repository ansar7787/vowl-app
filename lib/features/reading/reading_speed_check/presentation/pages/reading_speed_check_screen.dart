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
import 'package:vowl/features/reading/presentation/widgets/reading_self_evaluation_card.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_result.dart';

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

  double _pulseScale = 1.0;
  double _clarityRadius = 0.0;
  int _timerValue = 12;
  Timer? _timer;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onPulseTap() {
    if (_isAnswered || _isRevealed) return;
    setState(() {
      _pulseScale = 1.4;
      _clarityRadius = 1.0;
      _hapticService.selection();
    });

    Future.delayed(150.milliseconds, () {
      if (mounted) {
        setState(() => _pulseScale = 1.0);
      }
    });
    Future.delayed(2.seconds, () {
      if (mounted && !_isAnswered && !_isRevealed) {
        setState(() => _clarityRadius = 0.0);
      }
    });
  }

  void _startTimer(int initialValue) {
    _timer?.cancel();
    setState(() {
      _timerValue = initialValue;
      _isRevealed = false;
      _clarityRadius = 0.0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerValue > 0) {
        setState(() => _timerValue--);
      } else {
        setState(() {
          _isRevealed = true;
          _clarityRadius = 0.0;
        });
        timer.cancel();
      }
    });
  }

  void _submitSelfEvalAnswer(bool isCorrect, ReadingQuest quest) {
    if (_isAnswered || !_isRevealed) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isRevealed = false;
              _clarityRadius = 0.0;
            });
            _startTimer(state.currentQuest.timeLimit ?? 12);
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
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

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
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
                              isRevealed: _isRevealed,
                              instruction: quest.instruction,
                            ),
                            SizedBox(height: 32.h),
                            if (_isRevealed)
                              ReadingSpeedQuestionArea(
                                question: quest.question ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isRevealed)
                              ReadingSpeedPulseZone(
                                passage: quest.passage ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                                clarityRadius: _clarityRadius,
                                pulseScale: _pulseScale,
                                timerValue: _timerValue,
                                onTapPulse: _onPulseTap,
                              )
                            else ...[
                              SizedBox(height: 32.h),
                              ReadingSelfEvaluationCard(
                                correctAnswer: quest.correctAnswer ?? "",
                                explanation: quest.explanation,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onEvaluated: (isCorrect) => _submitSelfEvalAnswer(isCorrect, quest),
                              ),
                            ],
                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ReadingSpeedResult(
                                quest: quest,
                                isCorrect: _isCorrect == true,
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
  }
}
