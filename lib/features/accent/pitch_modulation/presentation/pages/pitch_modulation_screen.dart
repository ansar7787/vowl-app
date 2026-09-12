import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_instruction.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_prompt_card.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_pulse_speaker.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_dial_control.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class PitchModulationState {
  final bool isAnswered;
  final bool? isCorrect;
  final bool showConfetti;
  final double dialRotation;
  final bool isDragging;
  final int? selectedIndex;
  final bool isFirstStagePassed;
  final int spokenMeaningsCount;

  const PitchModulationState({
    this.isAnswered = false,
    this.isCorrect,
    this.showConfetti = false,
    this.dialRotation = 0.0,
    this.isDragging = false,
    this.selectedIndex,
    this.isFirstStagePassed = false,
    this.spokenMeaningsCount = 0,
  });

  PitchModulationState copyWith({
    bool? isAnswered,
    bool? isCorrect,
    bool? showConfetti,
    double? dialRotation,
    bool? isDragging,
    int? selectedIndex,
    bool? isFirstStagePassed,
    int? spokenMeaningsCount,
    bool clearCorrect = false,
    bool clearSelectedIndex = false,
  }) {
    return PitchModulationState(
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: clearCorrect ? null : (isCorrect ?? this.isCorrect),
      showConfetti: showConfetti ?? this.showConfetti,
      dialRotation: dialRotation ?? this.dialRotation,
      isDragging: isDragging ?? this.isDragging,
      selectedIndex: clearSelectedIndex
          ? null
          : (selectedIndex ?? this.selectedIndex),
      isFirstStagePassed: isFirstStagePassed ?? this.isFirstStagePassed,
      spokenMeaningsCount: spokenMeaningsCount ?? this.spokenMeaningsCount,
    );
  }
}

class PitchModulationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PitchModulationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pitchModulation,
  });

  @override
  State<PitchModulationScreen> createState() => _PitchModulationScreenState();
}

class _PitchModulationScreenState extends State<PitchModulationScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = 3;
  AccentQuest? _lastQuest;

  final ValueNotifier<PitchModulationState> _state = ValueNotifier(
    const PitchModulationState(),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onDialRotate(DragUpdateDetails details, int correct) {
    final state = _state.value;
    if (state.isAnswered || state.isFirstStagePassed) return;

    // Increased sensitivity so it tracks 1:1 with the physical track height
    double newRotation = (state.dialRotation - details.delta.dy / 75.0).clamp(
      -1.0,
      1.0,
    );

    _state.value = state.copyWith(isDragging: true, dialRotation: newRotation);

    // Auto-lock when reaching ends
    if (newRotation < -0.8) {
      _submitChoice(0, correct);
    } else if (newRotation > 0.8) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    final state = _state.value;
    if (state.isAnswered || state.isFirstStagePassed || !state.isDragging) {
      return;
    }

    _state.value = state.copyWith(
      isDragging: false,
      dialRotation: !state.isAnswered ? 0.0 : state.dialRotation,
    );
  }

  void _submitChoice(int index, int correct) {
    final state = _state.value;
    if (state.isAnswered || state.isFirstStagePassed) return;

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _state.value = state.copyWith(
        selectedIndex: index,
        dialRotation: index == 0 ? -0.8 : 0.8,
        isDragging: false,
        isFirstStagePassed: true,
      );
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _state.value = state.copyWith(
        selectedIndex: index,
        dialRotation: index == 0 ? -0.8 : 0.8,
        isDragging: false,
        isAnswered: true,
        isCorrect: false,
      );
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    final state = _state.value;
    if (state.isAnswered) return;

    _state.value = state.copyWith(isAnswered: true, isCorrect: nailedIt);

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _state.value.isAnswered)) {
            _lastProcessedIndex = state.currentIndex;
            _state.value = const PitchModulationState(); // Reset state entirely

            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null) {
              _lastQuest = quest;
            }
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          _state.value = _state.value.copyWith(showConfetti: true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'TONAL EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
        final options = quest?.options ?? ["A", "B"];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ValueListenableBuilder<PitchModulationState>(
            valueListenable: _state,
            builder: (context, uiState, _) {
              return AccentBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: uiState.isAnswered,
                isCorrect: uiState.isCorrect,
                showConfetti: uiState.showConfetti,
                onContinue: () =>
                    context.read<AccentBloc>().add(NextQuestion()),
                onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxHeight = constraints.maxHeight;

                          final double estimatedContentHeight =
                              24.h + 90.h + 80.h + 140.h;
                          final remainingHeight =
                              maxHeight - estimatedContentHeight;

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
                            thumbColor: theme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: (!uiState.isFirstStagePassed)
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: IgnorePointer(
                                    ignoring: uiState.isFirstStagePassed,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    PitchModulationInstruction(
                                                      color: theme.primaryColor,
                                                      instruction:
                                                          uiState
                                                              .isFirstStagePassed
                                                          ? "Great job! Now practice saying it with both meanings."
                                                          : quest.instruction,
                                                    ),
                                                    SizedBox(
                                                      height: gapInstruction,
                                                    ),

                                                    PitchModulationPromptCard(
                                                      word: quest.word ?? "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(height: gapPrompt),

                                                    PitchModulationPulseSpeaker(
                                                      text:
                                                          quest.textToSpeak ??
                                                          "",
                                                      color: theme.primaryColor,
                                                      onPlayTts: _playTts,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: gapSpeaker,
                                                    ),
                                                    // Dial Control is now fully driven by uiState
                                                    PitchModulationDialControl(
                                                      options: options,
                                                      correctIndex:
                                                          quest
                                                              .correctAnswerIndex ??
                                                          0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          uiState.isAnswered ||
                                                          uiState
                                                              .isFirstStagePassed,
                                                      isDragging:
                                                          uiState.isDragging,
                                                      dialRotation:
                                                          uiState.dialRotation,
                                                      selectedIndex:
                                                          uiState.selectedIndex,
                                                      onDialRotate:
                                                          _onDialRotate,
                                                      onDialRelease:
                                                          _onDialRelease,
                                                      onSubmitChoice:
                                                          _submitChoice,
                                                    ),
                                                    SizedBox(height: gapBottom),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                (uiState.isFirstStagePassed &&
                                                    !uiState.isAnswered)
                                                ? 40.h
                                                : 160.h,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                if (uiState.isFirstStagePassed &&
                                    !uiState.isAnswered)
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        if (uiState.isFirstStagePassed &&
                                            !uiState.isAnswered) ...[
                                          Builder(
                                            builder: (context) {
                                              String currentOption =
                                                  options[uiState
                                                      .spokenMeaningsCount];
                                              String currentMeaning =
                                                  currentOption;
                                              if (currentOption.contains(
                                                    " (",
                                                  ) &&
                                                  currentOption.endsWith(")")) {
                                                currentMeaning = currentOption
                                                    .split(" (")[1];
                                                currentMeaning = currentMeaning
                                                    .substring(
                                                      0,
                                                      currentMeaning.length - 1,
                                                    );
                                              }

                                              return SpeakToConfirmOverlay(
                                                expectedText:
                                                    quest.textToSpeak ?? "",
                                                displayText:
                                                    '${quest.textToSpeak ?? ""}\n\n(Meaning: $currentMeaning)',
                                                primaryColor:
                                                    theme.primaryColor,
                                                isPositioned: false,
                                                onConfirmed: () {
                                                  if (uiState
                                                          .spokenMeaningsCount ==
                                                      0) {
                                                    _state.value = _state.value
                                                        .copyWith(
                                                          spokenMeaningsCount:
                                                              1,
                                                        );
                                                    _soundService.playCorrect();
                                                  } else {
                                                    context.read<AccentBloc>().add(
                                                      const AccentSpeakConfirmed(
                                                        10,
                                                      ),
                                                    );
                                                    _submitVerbalEvaluation(
                                                      true,
                                                    );
                                                  }
                                                },
                                                onSkipped: () =>
                                                    _submitVerbalEvaluation(
                                                      false,
                                                    ),
                                              );
                                            },
                                          ),
                                        ],

                                        SizedBox(height: 60.h),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
