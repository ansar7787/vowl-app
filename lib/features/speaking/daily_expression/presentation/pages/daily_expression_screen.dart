import 'dart:async';
import 'dart:math' as math;
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
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_header.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_scratch_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_usage_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_telemetry_card.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_explanation_card.dart';
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

class _DailyExpressionScreenState extends State<DailyExpressionScreen> with SingleTickerProviderStateMixin {
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

  late AnimationController _glowController;
  Timer? _scratchTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  String _targetExpression = "";

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
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

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.expression != null) {
      _soundService.playTts(quest.expression!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _scratchProgress = 0.05;
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

    _scratchTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_scratchProgress < 0.90) {
          _scratchProgress += 0.012 + (math.Random().nextDouble() * 0.008);
        } else {
          _scratchProgress = 0.90 + (math.Random().nextDouble() * 0.02);
        }
      });
    });
  }

  void _stopSpeechListening() async {
    _scratchTimer?.cancel();
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyExpressionSpoken();
  }

  void _verifyExpressionSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Initializing")) {
      setState(() {
        _spokenText = "Vocal analysis timed out.";
        _scratchProgress = 0.0;
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpression = _targetExpression.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    final bool matchFound = cleanSpeech.contains(cleanExpression) || cleanExpression.contains(cleanSpeech);

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
      _scratchProgress = matchFound ? 1.0 : 0.0;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _scratchProgress = 0.0;
              _spokenText = "";
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
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
            onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _targetExpression = quest.expression ?? "Idiom";
        }

        return SpeakingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      DailyExpressionHeader(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),

                      DailyExpressionScratchPanel(
                        quest: quest,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                        scratchProgress: _scratchProgress,
                        isListening: _isListening,
                        timeVal: _timeVal,
                        onPlayTts: () => _soundService.playTts(quest.expression ?? ""),
                      ),
                      SizedBox(height: 20.h),

                      if (_scratchProgress > 0.3)
                        DailyExpressionUsagePanel(
                          quest: quest,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                      SizedBox(height: 20.h),

                      if (_spokenText.isNotEmpty) ...[
                        DailyExpressionTelemetryCard(
                          spokenText: _spokenText,
                          isDark: isDark,
                        ),
                        SizedBox(height: 20.h),
                      ],

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: DailyExpressionExplanationCard(
                          quest: quest,
                          isCorrect: _isCorrect ?? false,
                          isDark: isDark,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      if (!_isAnswered)
                        DailyExpressionScratcherTrigger(
                          isListening: _isListening,
                          timeVal: _timeVal,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          onLongPressStart: _startSpeechListening,
                          onLongPressEnd: _stopSpeechListening,
                        ),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
