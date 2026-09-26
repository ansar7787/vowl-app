import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_instruction.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_scene_display.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_explanation_panel.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_reaction_zone.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_formality_gauge.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

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
    with
        TickerProviderStateMixin,
        GameScreenMixin<SituationalResponseScreen>,
        RoleplayGameScreenMixin<SituationalResponseScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _timerController;
  late AnimationController _pulseController;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int?> _selectedOrbIndex = ValueNotifier(null);

  // Shuffled state
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<int> _shuffledCorrectIndex = ValueNotifier(-1);

  // Real-time ticking sound throttling
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    isFirstStagePassedNotifier.addListener(() {
      if (isFirstStagePassedNotifier.value &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
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

    initRoleplayGame();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _selectedOrbIndex.dispose();
    _shuffledOptions.dispose();
    _shuffledCorrectIndex.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    soundService.playTts(quest.scene ?? "");
  }

  void _checkTickWarnings() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    // Warn when time is running out (less than 4 seconds remaining)
    final double elapsedRatio = _timerController.value;
    final int remainingSec = (12 * (1.0 - elapsedRatio)).ceil();

    if (remainingSec <= 4 &&
        remainingSec > 0 &&
        remainingSec != _lastTickSecond) {
      _lastTickSecond = remainingSec;
      hapticService.selection();
      soundService.playHint(); // Play warning beep
    }
  }

  void _stopTimer() {
    _timerController.stop();
  }

  void _triggerTimeoutFailure() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _stopTimer();
    hapticService.error();
    soundService.playWrong();

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = false;
    _selectedOrbIndex.value = null;

    context.read<RoleplayBloc>().add(SubmitAnswer(false));
  }

  void _onOrbTap(int index, int correctIndex) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _stopTimer();

    final isCorrect = index == correctIndex;
    _selectedOrbIndex.value = index;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _selectedOrbIndex.value = null;

    _shuffledOptions.value = [];

    _shuffledCorrectIndex.value = -1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedOrbIndex,
            isFirstStagePassedNotifier,
            _shuffledOptions,
            _shuffledCorrectIndex,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: true,
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
                                              vertical: isCompact ? 5.h : 10.h,
                                            ),
                                            child: Column(
                                              children: [
                                                SituationalResponseInstruction(
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  instruction:
                                                      InstructionHelper.getInstruction(
                                                        quest,
                                                      ),
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
                                                      _triggerAutoPlay(quest),
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 16.h
                                                      : 24.h,
                                                ),
                                                AnimatedBuilder(
                                                  animation: Listenable.merge([
                                                    _timerController,
                                                    _pulseController,
                                                  ]),
                                                  builder: (context, _) {
                                                    return SituationalResponseReactionZone(
                                                      options: _shuffledOptions
                                                          .value,
                                                      correctIndex:
                                                          _shuffledCorrectIndex
                                                              .value,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      timerValue:
                                                          _timerController
                                                              .value,
                                                      pulseValue:
                                                          _pulseController
                                                              .value,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value ||
                                                          isFirstStagePassedNotifier
                                                              .value,
                                                      isCorrect:
                                                          isCorrectNotifier
                                                              .value,
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
                                                  firstChild: const SizedBox(),
                                                  secondChild:
                                                      SituationalResponseExplanationPanel(
                                                        quest: quest,
                                                        isDark: isDark,
                                                        isCorrect:
                                                            isCorrectNotifier
                                                                .value,
                                                      ),
                                                  crossFadeState:
                                                      isAnsweredNotifier.value
                                                      ? CrossFadeState
                                                            .showSecond
                                                      : CrossFadeState
                                                            .showFirst,
                                                  duration: const Duration(
                                                    milliseconds: 450,
                                                  ),
                                                ),
                                                if (isAnsweredNotifier
                                                    .value) ...[
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

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value &&
                                  _selectedOrbIndex.value != null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                    ),
                                    child: SpeakToConfirmOverlay(
                                      expectedText: _shuffledOptions
                                          .value[_selectedOrbIndex.value!],
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      onConfirmed: () {
                                        context.read<RoleplayBloc>().add(
                                          const RoleplaySpeakConfirmed(5),
                                        );
                                        _submitVerbalEvaluation(true);
                                      },
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false),
                                    ),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
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
