import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_instruction.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_scene_display.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_explanation_panel.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_reaction_zone.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_formality_gauge.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class SituationalResponseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SituationalResponseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationalResponse,
  });

  @override
  State<SituationalResponseScreen> createState() =>
      _SituationalResponseScreenState();
}

class _SituationalResponseScreenState extends State<SituationalResponseScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _timerController;
  late AnimationController _pulseController;

  int _lastProcessedIndex = -1;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<int?> _selectedOrbIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  // Shuffled state
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<int> _shuffledCorrectIndex = ValueNotifier(-1);

  // Real-time ticking sound throttling
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timerController.addListener(() {
      _checkTickWarnings();
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerTimeoutFailure();
      }
    });

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedOrbIndex.dispose();
    _isFirstStagePassed.dispose();
    _shuffledOptions.dispose();
    _shuffledCorrectIndex.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.scene ?? "");
  }

  void _checkTickWarnings() {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    // Warn when time is running out (less than 4 seconds remaining)
    final double elapsedRatio = _timerController.value;
    final int remainingSec = (12 * (1.0 - elapsedRatio)).ceil();

    if (remainingSec <= 4 &&
        remainingSec > 0 &&
        remainingSec != _lastTickSecond) {
      _lastTickSecond = remainingSec;
      _hapticService.selection();
      _soundService.playHint(); // Play warning beep
    }
  }

  void _startTimer() {
    _timerController.forward(from: 0.0);
    _lastTickSecond = -1;
  }

  void _stopTimer() {
    _timerController.stop();
  }

  void _triggerTimeoutFailure() {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _stopTimer();
    _hapticService.error();
    _soundService.playWrong();

    _isAnswered.value = true;
    _isCorrect.value = false;
    _selectedOrbIndex.value = null;

    context.read<RoleplayBloc>().add(SubmitAnswer(false));
  }

  void _onOrbTap(int index, int correctIndex) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _stopTimer();

    final isCorrect = index == correctIndex;
    _selectedOrbIndex.value = index;

    if (isCorrect) {
      _hapticService.selection();
      _isFirstStagePassed.value = true;
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedOrbIndex.value = null;
            _isFirstStagePassed.value = false;

            if (state.currentQuest.options != null) {
              final options = List<String>.from(state.currentQuest.options!);
              final correctOption =
                  options[state.currentQuest.correctAnswerIndex ?? 0];
              options.shuffle();
              _shuffledOptions.value = options;
              _shuffledCorrectIndex.value = options.indexOf(correctOption);
            }
            _startTimer();
            // Auto play dialogue context
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _stopTimer();
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SOCIAL GENIUS!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          _stopTimer();
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _selectedOrbIndex,
            _isFirstStagePassed,
            _shuffledOptions,
            _shuffledCorrectIndex,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  _isAnswered.value &&
                  (_isCorrect.value != null || !_isFirstStagePassed.value),
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxHeight < 580;
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: isCompact
                                                      ? 5.h
                                                      : 10.h,
                                                ),
                                                child: Column(
                                                  children: [
                                                    SituationalResponseInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          quest.instruction,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),
                                                    SituationalResponseSceneDisplay(
                                                      quest: quest,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      onListen: () =>
                                                          _triggerAutoPlay(
                                                            quest,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),
                                                    AnimatedBuilder(
                                                      animation:
                                                          Listenable.merge([
                                                            _timerController,
                                                            _pulseController,
                                                          ]),
                                                      builder: (context, _) {
                                                        return SituationalResponseReactionZone(
                                                          options:
                                                              _shuffledOptions
                                                                  .value,
                                                          correctIndex:
                                                              _shuffledCorrectIndex
                                                                  .value,
                                                          color: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                          timerValue:
                                                              _timerController
                                                                  .value,
                                                          pulseValue:
                                                              _pulseController
                                                                  .value,
                                                          isAnswered:
                                                              _isAnswered
                                                                  .value ||
                                                              _isFirstStagePassed
                                                                  .value,
                                                          isCorrect:
                                                              _isCorrect.value,
                                                          selectedOrbIndex:
                                                              _selectedOrbIndex
                                                                  .value,
                                                          onOrbTap: _onOrbTap,
                                                        );
                                                      },
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 12.h
                                                          : 20.h,
                                                    ),

                                                    // Explanations Card when answered
                                                    AnimatedCrossFade(
                                                      firstChild:
                                                          const SizedBox(),
                                                      secondChild:
                                                          SituationalResponseExplanationPanel(
                                                            quest: quest,
                                                            isDark: isDark,
                                                            isCorrect:
                                                                _isCorrect
                                                                    .value,
                                                          ),
                                                      crossFadeState:
                                                          _isAnswered.value
                                                          ? CrossFadeState
                                                                .showSecond
                                                          : CrossFadeState
                                                                .showFirst,
                                                      duration: const Duration(
                                                        milliseconds: 450,
                                                      ),
                                                    ),
                                                    if (_isAnswered.value) ...[
                                                      SizedBox(
                                                        height: isCompact
                                                            ? 12.h
                                                            : 20.h,
                                                      ),
                                                      SituationalResponseFormalityGauge(
                                                        quest: quest,
                                                        primaryColor:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                      ),
                                                    ],
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (_isFirstStagePassed.value &&
                                              !_isAnswered.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isFirstStagePassed.value &&
                                !_isAnswered.value &&
                                _selectedOrbIndex.value != null)
                              SpeakToConfirmOverlay(
                                expectedText: _shuffledOptions
                                    .value[_selectedOrbIndex.value!],
                                primaryColor: theme.primaryColor,
                                isPositioned: true,
                                onConfirmed: () {
                                  context.read<RoleplayBloc>().add(
                                    const RoleplaySpeakConfirmed(5),
                                  );
                                  _submitVerbalEvaluation(true);
                                },
                                onSkipped: () => _submitVerbalEvaluation(false),
                              ),
                          ],
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
