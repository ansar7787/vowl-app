import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/speaking_self_evaluation_controls.dart';

import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_header.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_scratch_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_usage_panel.dart';

class DailyExpressionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const DailyExpressionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dailyExpression,
  });

  @override
  State<DailyExpressionScreen> createState() => _DailyExpressionScreenState();
}

class _DailyExpressionScreenState extends State<DailyExpressionScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _scratchProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _glowController;
  double _timeVal = 0.0;
  String _targetExpression = "";

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            setState(() {
              _timeVal = _glowController.value;
            });
          });
    _glowController.repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleScratchUpdate(double delta) {
    if (_scratchProgress >= 1.0) return;
    setState(() {
      _scratchProgress += delta;
      if (_scratchProgress >= 0.85) {
        _scratchProgress = 1.0;
        _hapticService.selection();
        _soundService.playTts(_targetExpression);
      }
    });
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered || _scratchProgress < 1.0) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _scratchProgress = 1.0;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _scratchProgress = 0.0;
            });
            // Removed Future.delayed auto-play to preserve scratch card mystery
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            setState(() {
              _isCorrect = false;
              _isAnswered = true;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'EXPRESSION MASTERED!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final hintUsed = (state is SpeakingLoaded) && state.hintUsed;

        if (quest != null) {
          _targetExpression = quest.expression ?? "Idiom";
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : CustomScrollView(
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
                              DailyExpressionHeader(
                                primaryColor: theme.primaryColor,
                                instruction: context.tr(
                                  'games.daily_expression_instruction',
                                  fallback: 'Speak the daily idiom',
                                ),
                              ),
                              SizedBox(height: 24.h),
                              if (hintUsed && quest.hint != null)
                                Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 12.h,
                                      ),
                                      margin: EdgeInsets.only(bottom: 24.h),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline_rounded,
                                            color: theme.primaryColor,
                                            size: 18.r,
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              quest.hint!,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 14.sp,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: -0.1),
                              DailyExpressionScratchPanel(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                scratchProgress: _scratchProgress,
                                isListening: false,
                                timeVal: _timeVal,
                                onPlayTts: () => _soundService.playTts(
                                  quest.expression ?? "",
                                ),
                                onScratchUpdate: _handleScratchUpdate,
                              ),
                              SizedBox(height: 32.h),
                              if (_scratchProgress > 0.3)
                                DailyExpressionUsagePanel(
                                        quest: quest,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        isListening: false,
                                      )
                                      .animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideY(begin: 0.1),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered && _scratchProgress >= 1.0)
                                SpeakingSelfEvaluationControls(
                                  expectedText: _targetExpression,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
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
  }
}
