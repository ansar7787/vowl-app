import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_header.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_scratch_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_usage_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_telemetry_card.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_scratcher_trigger.dart';

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
  final _speechService = di.sl<SpeechService>();

  double _scratchProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;
  int _attempts = 0;

  late AnimationController _glowController;
  Timer? _scratchTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
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
    _scratchTimer?.cancel();
    super.dispose();
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Initializing vocal frequency analyzer...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopSpeechListening() async {
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyExpressionSpoken();
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

  void _verifyExpressionSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Initializing")) {
      setState(() {
        _spokenText = "Vocal analysis timed out.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    final String cleanExpression = _targetExpression
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');

    final bool matchFound =
        cleanSpeech.contains(cleanExpression) ||
        cleanExpression.contains(cleanSpeech);

    setState(() {
      _attempts++;
      _isAnswered = true;
      _isCorrect = matchFound;
    });

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
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
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _isListening = false;
              _scratchProgress = 0.0;
              _spokenText = "";
            });
            // Removed Future.delayed auto-play to preserve scratch card mystery
          } else if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
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
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<SpeakingBloc>().add(const RestoreLife()),
            onTutorPass: _tutorPass,
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
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
            onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          (isCompact ? 80.h : 110.h) +
                          (isCompact ? 100.h : 140.h) +
                          (isCompact ? 60.h : 80.h);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(6.0, 16.0)
                          : 6.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 12.0)
                          : 8.0;
                      final double gapScratch = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapUsage = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapTelemetry = remainingHeight > 0
                          ? (gapUnit * 2).clamp(12.0, 30.0)
                          : 12.0;
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    isCompact
                                        ? SizedBox(
                                            height: 32.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: DailyExpressionHeader(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction: context.tr(
                                                  'games.daily_expression_instruction',
                                                  fallback: 'Speak the daily idiom',
                                                ),
                                              ),
                                            ),
                                          )
                                        : DailyExpressionHeader(
                                            primaryColor: theme.primaryColor,
                                            instruction: context.tr(
                                              'games.daily_expression_instruction',
                                              fallback: 'Speak the daily idiom',
                                            ),
                                          ),
                                    SizedBox(height: gapInstruction),

                                    if (hintUsed && quest.hint != null)
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                        margin: EdgeInsets.only(bottom: gapInstruction),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16.r),
                                          border: Border.all(
                                            color: theme.primaryColor.withValues(alpha: 0.3),
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
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

                                    isCompact
                                        ? SizedBox(
                                            height: 100.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child:
                                                    DailyExpressionScratchPanel(
                                                      quest: quest,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      scratchProgress:
                                                          _scratchProgress,
                                                      isListening: _isListening,
                                                      timeVal: _timeVal,
                                                      onPlayTts: () =>
                                                          _soundService.playTts(
                                                            quest.expression ??
                                                                "",
                                                          ),
                                                      onScratchUpdate: _handleScratchUpdate,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : DailyExpressionScratchPanel(
                                            quest: quest,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            scratchProgress: _scratchProgress,
                                            isListening: _isListening,
                                            timeVal: _timeVal,
                                            onPlayTts: () =>
                                                _soundService.playTts(
                                                  quest.expression ?? "",
                                                ),
                                            onScratchUpdate: _handleScratchUpdate,
                                          ),
                                    SizedBox(height: gapScratch),

                                    if (_scratchProgress > 0.3)
                                      isCompact
                                          ? SizedBox(
                                                  height: 80.h,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: SizedBox(
                                                      width:
                                                          constraints.maxWidth -
                                                          16.w,
                                                      child:
                                                          DailyExpressionUsagePanel(
                                                            quest: quest,
                                                            primaryColor: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                            isListening: _isListening,
                                                          ),
                                                    ),
                                                  ),
                                                )
                                                .animate()
                                                .fadeIn(duration: 300.ms)
                                                .slideY(begin: 0.1)
                                          : DailyExpressionUsagePanel(
                                                  quest: quest,
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  isDark: isDark,
                                                  isListening: _isListening,
                                                )
                                                .animate()
                                                .fadeIn(duration: 300.ms)
                                                .slideY(begin: 0.1),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapUsage),
                                    if (_spokenText.isNotEmpty)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: SizedBox(
                                                  width:
                                                      constraints.maxWidth -
                                                      16.w,
                                                  child:
                                                      DailyExpressionTelemetryCard(
                                                        spokenText: _spokenText,
                                                        isDark: isDark,
                                                        primaryColor: theme.primaryColor,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : DailyExpressionTelemetryCard(
                                              spokenText: _spokenText,
                                              isDark: isDark,
                                              primaryColor: theme.primaryColor,
                                            ),

                                    SizedBox(height: gapTelemetry),

                                    if (!_isAnswered && _scratchProgress >= 1.0)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child:
                                                    DailyExpressionScratcherTrigger(
                                                      isListening: _isListening,
                                                      timeVal: _timeVal,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      onLongPressStart:
                                                          _startSpeechListening,
                                                      onLongPressEnd:
                                                          _stopSpeechListening,
                                                      attempts: _attempts,
                                                      isAnswered: _isAnswered,
                                                      onTutorPass: _tutorPass,
                                                    ),
                                              ),
                                            )
                                          : DailyExpressionScratcherTrigger(
                                              isListening: _isListening,
                                              timeVal: _timeVal,
                                              primaryColor: theme.primaryColor,
                                              isDark: isDark,
                                              onLongPressStart:
                                                  _startSpeechListening,
                                              onLongPressEnd:
                                                  _stopSpeechListening,
                                              attempts: _attempts,
                                              isAnswered: _isAnswered,
                                              onTutorPass: _tutorPass,
                                            ),
                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
