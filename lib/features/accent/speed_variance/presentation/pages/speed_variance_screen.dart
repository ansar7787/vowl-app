import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_instruction.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_prompt_card.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_pulse_speaker.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_tempo_dial.dart';

class SpeedVarianceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeedVarianceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speedVariance,
  });

  @override
  State<SpeedVarianceScreen> createState() => _SpeedVarianceScreenState();
}

class _SpeedVarianceScreenState extends State<SpeedVarianceScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _dialRotation = 0.0;
  bool _isDragging = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text, {double? speed}) {
    _hapticService.selection();
    _soundService.playTts(text, speed: speed ?? 0.4);
  }

  void _onDialRotate(DragUpdateDetails details, int correct) {
    if (_isAnswered) return;

    final double dx = details.delta.dx;
    final double dy = details.delta.dy;
    final double x = details.localPosition.dx;
    final double y = details.localPosition.dy;

    final bool isTopHalf = y < 50.r;
    final bool isLeftHalf = x < 50.r;

    final double hRot = isTopHalf ? dx : -dx;
    final double vRot = isLeftHalf ? -dy : dy;
    final double totalRot = (hRot + vRot) / 30.0;

    setState(() {
      _isDragging = true;
      _dialRotation = (_dialRotation + totalRot).clamp(-1.0, 1.0);
    });
    _hapticService.selection();

    // Auto-lock when reaching ends
    if (_dialRotation < -0.8) {
      _submitChoice(0, correct);
    } else if (_dialRotation > 0.8) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    if (_isAnswered || !_isDragging) return;
    setState(() {
      _isDragging = false;
      if (!_isAnswered) {
        _dialRotation = 0.0;
      }
    });
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _dialRotation = index == 0 ? -0.8 : 0.8;
      _isDragging = false;
    });

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      _scrollToBottom();
      context.read<AccentBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      _scrollToBottom();
      context.read<AccentBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final currentLives = state.livesRemaining;
          final livesRestored =
              _lastLives != null && currentLives > _lastLives!;
          if (state.currentIndex != _lastProcessedIndex ||
              livesRestored ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dialRotation = 0.0;
              _selectedIndex = null;
              _isDragging = false;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _playTts(quest.textToSpeak!, speed: quest.targetSpeed);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'TEMPO ACE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        if (state is! AccentLoaded) return const SizedBox();
        final quest = state.currentQuest;
        final options = quest.options ?? [];
        if (options.length < 2) return const SizedBox();

        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () =>
                context.read<AccentBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<AccentBloc>().add(const AccentHintUsed()),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                final double estimatedContentHeight =
                    24.h + 90.h + 80.h + 140.h + (_isAnswered ? 180.h : 0);
                final remainingHeight = maxHeight - estimatedContentHeight;

                final double gapUnit = remainingHeight > 0
                    ? remainingHeight / 8
                    : 0;
                final double gapTop = remainingHeight > 0
                    ? (gapUnit * 1).clamp(8.0, 24.0)
                    : 8.0;
                final double gapInstruction = remainingHeight > 0
                    ? (gapUnit * 1).clamp(8.0, 24.0)
                    : 8.0;
                final double gapPrompt = remainingHeight > 0
                    ? (gapUnit * 1.5).clamp(12.0, 32.0)
                    : 12.0;
                final double gapSpeaker = remainingHeight > 0
                    ? (gapUnit * 2).clamp(16.0, 48.0)
                    : 16.0;

                final double gapBottom = remainingHeight > 0
                    ? (gapUnit * 1).clamp(12.0, 40.0)
                    : 12.0;

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: gapTop),
                              SpeedVarianceInstruction(
                                color: theme.primaryColor,
                                instruction: context.tr(
                                  'games.speed_variance_instruction',
                                  fallback: quest.instruction,
                                ),
                              ),
                              SizedBox(height: gapInstruction),
                              SpeedVariancePromptCard(
                                word: quest.word ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                              ),
                              SizedBox(height: gapPrompt),
                              SpeedVariancePulseSpeaker(
                                text: quest.textToSpeak ?? "",
                                color: theme.primaryColor,
                                onPlayTts: (text) =>
                                    _playTts(text, speed: quest.targetSpeed),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: gapSpeaker),
                              SpeedVarianceTempoDial(
                                options: options,
                                correctIndex: quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                isDark: isDark,
                                isAnswered: _isAnswered,
                                isDragging: _isDragging,
                                dialRotation: _dialRotation,
                                selectedIndex: _selectedIndex,
                                onDialRotate: _onDialRotate,
                                onDialRelease: _onDialRelease,
                                onSubmitChoice: _submitChoice,
                              ),
                              SizedBox(
                                height: gapBottom + (_isAnswered ? 180.h : 0),
                              ),
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
