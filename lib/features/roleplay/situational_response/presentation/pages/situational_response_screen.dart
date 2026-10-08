import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_options_panel.dart';
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

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int?> _selectedOrbIndex = ValueNotifier(null);

  // Shuffled state
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<int> _shuffledCorrectIndex = ValueNotifier(-1);

  @override
  void onRoleplayStateChanged(BuildContext context, RoleplayState state) {
    super.onRoleplayStateChanged(context, state);
    if (state is RoleplayLoaded) {
      final quest = state.currentQuest;
      if (_shuffledOptions.value.isEmpty &&
          quest.options != null &&
          quest.options!.isNotEmpty) {
        final List<String> originalOptions = quest.options!;
        final originalCorrect = quest.correctAnswerIndex ?? 0;

        final List<int> indices = List.generate(
          originalOptions.length,
          (i) => i,
        )..shuffle();

        _shuffledOptions.value = indices
            .map((i) => originalOptions[i])
            .toList();
        _shuffledCorrectIndex.value = indices.indexOf(originalCorrect);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    isFirstStagePassedNotifier.addListener(() {
      if (isFirstStagePassedNotifier.value &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
    initRoleplayGame();
  }

  @override
  void dispose() {
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onOptionTap(int index, int correctIndex, GameQuest quest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final isCorrect = index == correctIndex;
    _selectedOrbIndex.value = index;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2 Speak To Confirm
    } else {
      _scrollToBottom();
      final userAnswer = index < _shuffledOptions.value.length
          ? _shuffledOptions.value[index]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      final userAnswer =
          (_selectedOrbIndex.value != null &&
              _selectedOrbIndex.value! < _shuffledOptions.value.length)
          ? _shuffledOptions.value[_selectedOrbIndex.value!]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
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
              fullScreenContent: true,
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
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                              SliverToBoxAdapter(
                                child: IgnorePointer(
                                  ignoring:
                                      isFirstStagePassedNotifier.value ||
                                      isAnsweredNotifier.value,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Column(
                                      children: [
                                        LayoutBuilder(
                                          builder: (context, innerConstraints) {
                                            final isCompact =
                                                innerConstraints.maxHeight <
                                                580;
                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
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
                                                  SituationalResponseOptionsPanel(
                                                    options:
                                                        _shuffledOptions.value,
                                                    correctIndex:
                                                        _shuffledCorrectIndex
                                                            .value,
                                                    color: theme.primaryColor,
                                                    isDark: isDark,
                                                    isAnswered:
                                                        isAnsweredNotifier
                                                            .value ||
                                                        isFirstStagePassedNotifier
                                                            .value,
                                                    isCorrect:
                                                        isCorrectNotifier.value,
                                                    selectedIndex:
                                                        _selectedOrbIndex.value,
                                                    onOptionTap: (idx, corr) =>
                                                        _onOptionTap(
                                                          idx,
                                                          corr,
                                                          quest,
                                                        ),
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
                                                  if (isFirstStagePassedNotifier
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      (isAnsweredNotifier.value ||
                                          isFirstStagePassedNotifier.value)
                                      ? 180.h
                                      : 60.h,
                                ),
                              ),

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value &&
                                  _selectedOrbIndex.value != null)
                                SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            final expectedText =
                                                _shuffledOptions
                                                    .value[_selectedOrbIndex
                                                    .value!];
                                            return SpeakToConfirmOverlay(
                                              expectedText: expectedText,
                                              displayText: expectedText,
                                              title: 'SPEAK TO RESPOND',
                                              subtitle:
                                                  'Say your response aloud',
                                              displayFontSize: 16.sp,
                                              displayFontWeight:
                                                  FontWeight.w500,
                                              displayTextAlign:
                                                  TextAlign.center,
                                              primaryColor: theme.primaryColor,
                                              isPositioned: false,
                                              onConfirmed: () {
                                                context.read<RoleplayBloc>().add(
                                                  const RoleplaySpeakConfirmed(
                                                    5,
                                                  ),
                                                );
                                                _submitVerbalEvaluation(
                                                  true,
                                                  quest,
                                                );
                                              },
                                              onSkipped: () =>
                                                  _submitVerbalEvaluation(
                                                    false,
                                                    quest,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
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
        );
      },
    );
  }
}
