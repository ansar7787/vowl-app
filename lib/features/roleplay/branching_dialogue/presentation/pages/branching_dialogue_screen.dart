import 'dart:math' as math;
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
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_instruction.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_persona_console.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_console_board.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_relationship_meter.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class BranchingDialogueScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const BranchingDialogueScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.branchingDialogue,
  });

  @override
  State<BranchingDialogueScreen> createState() =>
      _BranchingDialogueScreenState();
}

class _BranchingDialogueScreenState extends State<BranchingDialogueScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<BranchingDialogueScreen>,
        RoleplayGameScreenMixin<BranchingDialogueScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _springController;

  final ScrollController _scrollController = ScrollController();

  // Drag and drop mechanics relative points
  final ValueNotifier<Offset> _probeOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<int?> _hoveredIndex = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isDraggingProbe = ValueNotifier(false);

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

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _springController.addListener(() {
      _probeOffset.value = Offset.lerp(
        _probeOffset.value,
        Offset.zero,
        _springController.value,
      )!;
    });

    initRoleplayGame();
  }

  @override
  void dispose() {
    _springController.dispose();
    _probeOffset.dispose();
    _hoveredIndex.dispose();
    _selectedIndex.dispose();
    _isDraggingProbe.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    hapticService.selection();
    final rawText = quest.textToSpeak ?? quest.scene ?? quest.prompt ?? '';
    if (rawText.startsWith('http://') || rawText.startsWith('https://')) {
      soundService.playUrl(rawText);
      return;
    }
    final text = rawText.replaceAll(RegExp(r'\[pause:\d+\]'), ' ');
    if (text.isNotEmpty) {
      soundService.playTts(text);
    }
  }

  void _onProbeDragStart(DragStartDetails details) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _isDraggingProbe.value = true;
    _springController.stop();
  }

  void _onProbeDragUpdate(
    DragUpdateDetails details,
    Offset launchCenter,
    List<Offset> terminalCenters,
  ) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    Offset newOffset = _probeOffset.value + details.delta;
    final double distance = newOffset.distance;
    if (distance > 380.h) {
      newOffset = Offset.fromDirection(newOffset.direction, 380.h);
    }
    _probeOffset.value = newOffset;

    _checkTerminalHover(launchCenter, terminalCenters);
  }

  void _checkTerminalHover(Offset launchCenter, List<Offset> terminalCenters) {
    final Offset currentProbePos = launchCenter + _probeOffset.value;
    int? activeHoverIndex;

    for (int i = 0; i < terminalCenters.length; i++) {
      final Offset nodeCenter = terminalCenters[i] - Offset(0, 24.h);
      final double distToAnchor =
          (currentProbePos - terminalCenters[i]).distance;
      final double distToNode = (currentProbePos - nodeCenter).distance;
      final double dist = math.min(distToAnchor, distToNode);

      if (dist < 64.r) {
        activeHoverIndex = i;
        break;
      }
    }

    if (activeHoverIndex != _hoveredIndex.value) {
      _hoveredIndex.value = activeHoverIndex;
      if (activeHoverIndex != null) {
        hapticService.selection();
        soundService.playHint(); // Play Lock-on alert bleep
      }
    }
  }

  void _onProbeDragEnd(int correctIndex, RoleplayQuest quest) {
    _isDraggingProbe.value = false;
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    if (_hoveredIndex.value != null) {
      _submitChoice(_hoveredIndex.value!, correctIndex, quest);
    } else {
      _springController.forward(from: 0.0);
      hapticService.selection();
    }
  }

  void _submitChoice(int index, int correct, RoleplayQuest quest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final isCorrect = index == correct;
    _selectedIndex.value = index;
    _hoveredIndex.value = null;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      final userAnswer = quest.options != null && index < quest.options!.length
          ? quest.options![index]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, RoleplayQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      final userAnswer =
          (_selectedIndex.value != null &&
              quest.options != null &&
              _selectedIndex.value! < quest.options!.length)
          ? quest.options![_selectedIndex.value!]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  @override
  void onQuestionReset() {
    _isDraggingProbe.value = false;
    _probeOffset.value = Offset.zero;
    _hoveredIndex.value = null;
    _selectedIndex.value = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      buildWhen: (previous, current) =>
          current is RoleplayInitial ||
          current is RoleplayLoading ||
          current is RoleplayLoaded ||
          current is RoleplayGameOver ||
          current is RoleplayGameComplete,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedIndex,
            isFirstStagePassedNotifier,
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
              onHint: () {
                hapticService.selection();
              },
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final double availableHeight = constraints.maxHeight;
                        // Estimate top content height (padding + instruction + persona) ~320.h
                        final double boardHeight = math.max(
                          340.h,
                          availableHeight - 320.h,
                        );

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: ListenableBuilder(
                            listenable: Listenable.merge([
                              _isDraggingProbe,
                              isFirstStagePassedNotifier,
                              isAnsweredNotifier,
                            ]),
                            builder: (context, _) {
                              return CustomScrollView(
                                controller: _scrollController,
                                physics:
                                    (!isFirstStagePassedNotifier.value &&
                                            !isAnsweredNotifier.value)
                                        ? const NeverScrollableScrollPhysics()
                                        : const BouncingScrollPhysics(),
                                slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Column(
                                    children: [
                                      BranchingDialogueInstruction(
                                        key: const Key(
                                          'branching_dialogue_instruction',
                                        ),
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 12.h),
                                      if (isAnsweredNotifier.value &&
                                          _selectedIndex.value != null &&
                                          quest.consequenceScores != null &&
                                          _selectedIndex.value! <
                                              quest.consequenceScores!.length)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 12.h,
                                          ),
                                          child: BranchingDialogueRelationshipMeter(
                                            key: const Key(
                                              'branching_dialogue_relationship_meter',
                                            ),
                                            consequenceScore:
                                                quest
                                                    .consequenceScores![_selectedIndex
                                                    .value!],
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                        ),
                                      BranchingDialoguePersonaConsole(
                                        key: const Key(
                                          'branching_dialogue_persona_console',
                                        ),
                                        quest: quest,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        onListen: () => _triggerAutoPlay(quest),
                                      ),
                                      SizedBox(height: 16.h),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: boardHeight,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                    child: ListenableBuilder(
                                      listenable: Listenable.merge([
                                        _probeOffset,
                                        _hoveredIndex,
                                      ]),
                                      builder: (context, _) {
                                        return BranchingDialogueConsoleBoard(
                                          key: const Key(
                                            'branching_dialogue_console_board',
                                          ),
                                          options: options,
                                          consequencePreviews:
                                              quest.consequencePreviews ?? [],
                                          correctIndex:
                                              quest.correctAnswerIndex ?? 0,
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          probeOffset: _probeOffset.value,
                                          hoveredIndex: _hoveredIndex.value,
                                          selectedIndex: _selectedIndex.value,
                                          isAnswered:
                                              isAnsweredNotifier.value ||
                                              isFirstStagePassedNotifier.value,
                                          onProbeDragStart: _onProbeDragStart,
                                          onProbeDragUpdate: _onProbeDragUpdate,
                                          onProbeDragEnd: (idx) =>
                                              _onProbeDragEnd(idx, quest),
                                          onOptionTapped: (index) =>
                                              _submitChoice(
                                                index,
                                                quest.correctAnswerIndex ?? 0,
                                                quest,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value &&
                                  _selectedIndex.value != null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 16.h,
                                    ),
                                    child: SpeakToConfirmOverlay(
                                      key: const Key(
                                        'branching_dialogue_speak_overlay',
                                      ),
                                      expectedText:
                                          options[_selectedIndex.value!],
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      onConfirmed: () {
                                        context.read<RoleplayBloc>().add(
                                          const RoleplaySpeakConfirmed(5),
                                        );
                                        _submitVerbalEvaluation(true, quest);
                                      },
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false, quest),
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
                                      : 80.h,
                                ),
                              ),
                            ],
                          );
                        },
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
