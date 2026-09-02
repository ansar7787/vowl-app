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
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_speed_toggle.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<double> _dialRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  final ValueNotifier<bool> _isNaturalSpeed = ValueNotifier(true);
  final GlobalKey<SpeedChallengeTimerState> _timerKey = GlobalKey<SpeedChallengeTimerState>();

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
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _dialRotation.dispose();
    _isDragging.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    _isNaturalSpeed.dispose();
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
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    final double dx = details.delta.dx;
    final double dy = details.delta.dy;
    final double x = details.localPosition.dx;
    final double y = details.localPosition.dy;

    final bool isTopHalf = y < 50.r;
    final bool isLeftHalf = x < 50.r;

    final double hRot = isTopHalf ? dx : -dx;
    final double vRot = isLeftHalf ? -dy : dy;
    final double totalRot = (hRot + vRot) / 30.0;

    _isDragging.value = true;
    _dialRotation.value = (_dialRotation.value + totalRot).clamp(-1.0, 1.0);
    _hapticService.selection();

    // Auto-lock when reaching ends
    if (_dialRotation.value < -0.8) {
      _submitChoice(0, correct);
    } else if (_dialRotation.value > 0.8) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    if (_isAnswered.value || _isFirstStagePassed.value || !_isDragging.value) return;
    _isDragging.value = false;
    if (!_isAnswered.value) {
      _dialRotation.value = 0.0;
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;
    _dialRotation.value = index == 0 ? -0.8 : 0.8;
    _isDragging.value = false;

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _timerKey.currentState?.stop();
    _scrollToBottom();
    context.read<AccentBloc>().add(const SubmitAnswer(false));
  }
}

void _handleTimeExpired() {
  if (_isAnswered.value || _isFirstStagePassed.value) return;
  _isAnswered.value = true;
  _isCorrect.value = false;
  _soundService.playWrong();
  _scrollToBottom();
  context.read<AccentBloc>().add(const SubmitAnswer(false));
}

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      _scrollToBottom();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      context.read<AccentBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _dialRotation.value = 0.0;
            _selectedIndex.value = null;
            _isDragging.value = false;
            _isFirstStagePassed.value = false;
            _isNaturalSpeed.value = true;
            if (!_isAnswered.value) _timerKey.currentState?.start();
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
          _showConfetti.value = true;
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
            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,
            onContinue: () =>
                context.read<AccentBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<AccentBloc>().add(const AccentHintUsed()),
            useScrolling: false,
            child: ListenableBuilder(
              listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dialRotation, _isDragging, _selectedIndex, _isFirstStagePassed, _isNaturalSpeed]),
              builder: (context, _) {
                return Stack(
                  children: [
                    LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final double estimatedContentHeight =
                        24.h + 90.h + 80.h + 140.h;
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

                    return RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              children: [
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: gapTop),
                                      if (!_isFirstStagePassed.value && !_isAnswered.value)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 16.h),
                                          child: SpeedChallengeTimer(
                                            key: _timerKey,
                                            durationSeconds: 15,
                                            primaryColor: theme.primaryColor,
                                            onTimeUp: _handleTimeExpired,
                                          ),
                                        ),
                                      SpeedVarianceInstruction(
                                        color: theme.primaryColor,
                                        instruction: _isFirstStagePassed.value
                                            ? "Great job! Now record yourself saying the word."
                                            : context.tr(
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
                                        if (_isFirstStagePassed.value && !_isAnswered.value)
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 16.h),
                                            child: SpeedVarianceSpeedToggle(
                                              isNatural: _isNaturalSpeed.value,
                                              onChanged: (val) {
                                                _isNaturalSpeed.value = val;
                                                _playTts(
                                                  quest.textToSpeak ?? "",
                                                  speed: val ? (quest.naturalSpeed ?? 1.0) : (quest.clearSpeed ?? 0.75),
                                                );
                                              },
                                              primaryColor: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                        SpeedVariancePulseSpeaker(
                                          text: quest.textToSpeak ?? "",
                                          color: theme.primaryColor,
                                          onPlayTts: (text) => _playTts(
                                            text,
                                            speed: _isFirstStagePassed.value
                                                ? (_isNaturalSpeed.value ? (quest.naturalSpeed ?? 1.0) : (quest.clearSpeed ?? 0.75))
                                                : quest.targetSpeed,
                                          ),
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
                                        isAnswered:
                                            _isAnswered.value || _isFirstStagePassed.value,
                                        isDragging: _isDragging.value,
                                        dialRotation: _dialRotation.value,
                                        selectedIndex: _selectedIndex.value,
                                        onDialRotate: _onDialRotate,
                                        onDialRelease: _onDialRelease,
                                        onSubmitChoice: _submitChoice,
                                      ),
                                      SizedBox(height: gapBottom),
                                    ],
                                ),
                              ),
                              SizedBox(height: (_isFirstStagePassed.value && !_isAnswered.value) ? 380.h : 160.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                    );
                  },
                  ),
                    if (_isFirstStagePassed.value && !_isAnswered.value)
                      SpeakToConfirmOverlay(
                        expectedText: quest.textToSpeak ?? quest.word ?? "",
                        primaryColor: theme.primaryColor,
                        isPositioned: true,
                        onConfirmed: () => _submitVerbalEvaluation(true),
                        onSkipped: () => _submitVerbalEvaluation(false),
                      ),
                  ],
                );
            },
          ),
          ),
        );
      },
    );
  }
}
