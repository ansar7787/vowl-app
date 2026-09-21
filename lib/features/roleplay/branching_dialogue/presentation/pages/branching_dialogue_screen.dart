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
    with TickerProviderStateMixin, RoleplayGameScreenMixin {
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

    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

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
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    soundService.playTts(quest.scene ?? "");
  }

  void _onProbeDragStart(DragStartDetails details) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
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
    if (distance > 240.h) {
      newOffset = Offset.fromDirection(newOffset.direction, 240.h);
    }
    _probeOffset.value = newOffset;

    _checkTerminalHover(launchCenter, terminalCenters);
  }

  void _checkTerminalHover(Offset launchCenter, List<Offset> terminalCenters) {
    final Offset currentProbePos = launchCenter + _probeOffset.value;
    int? activeHoverIndex;

    for (int i = 0; i < terminalCenters.length; i++) {
      final double dist = (currentProbePos - terminalCenters[i]).distance;
      if (dist < 48.r) {
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

  void _onProbeDragEnd(int correctIndex) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    if (_hoveredIndex.value != null) {
      _submitChoice(_hoveredIndex.value!, correctIndex);
    } else {
      _springController.forward(from: 0.0);
      hapticService.selection();
    }
  }

  void _submitChoice(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final isCorrect = index == correct;
    _selectedIndex.value = index;
    _hoveredIndex.value = null;

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
    _probeOffset.value = Offset.zero;

    _hoveredIndex.value = null;

    _selectedIndex.value = null;
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
        final options = quest?.options ?? [];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _probeOffset,
            _hoveredIndex,
            _selectedIndex,
            isFirstStagePassedNotifier,
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
                                                BranchingDialogueInstruction(
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  instruction:
                                                      InstructionHelper.getInstruction(
                                                        quest,
                                                      ),
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 10.h
                                                      : 16.h,
                                                ),
                                                if (isAnsweredNotifier.value &&
                                                    _selectedIndex.value !=
                                                        null &&
                                                    quest.consequenceScores !=
                                                        null)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),
                                                    child: BranchingDialogueRelationshipMeter(
                                                      consequenceScore:
                                                          quest
                                                              .consequenceScores![_selectedIndex
                                                              .value!],
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                  ),
                                                BranchingDialoguePersonaConsole(
                                                  quest: quest,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  onListen: () =>
                                                      _triggerAutoPlay(quest),
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 12.h
                                                      : 20.h,
                                                ),
                                                BranchingDialogueConsoleBoard(
                                                  options: options,
                                                  consequencePreviews:
                                                      quest
                                                          .consequencePreviews ??
                                                      [],
                                                  correctIndex:
                                                      quest
                                                          .correctAnswerIndex ??
                                                      0,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  probeOffset:
                                                      _probeOffset.value,
                                                  hoveredIndex:
                                                      _hoveredIndex.value,
                                                  selectedIndex:
                                                      _selectedIndex.value,
                                                  isAnswered:
                                                      isAnsweredNotifier
                                                          .value ||
                                                      isFirstStagePassedNotifier
                                                          .value,
                                                  onProbeDragStart:
                                                      _onProbeDragStart,
                                                  onProbeDragUpdate:
                                                      _onProbeDragUpdate,
                                                  onProbeDragEnd:
                                                      _onProbeDragEnd,
                                                  onOptionTapped: (index) =>
                                                      _submitChoice(
                                                        index,
                                                        quest.correctAnswerIndex ??
                                                            0,
                                                      ),
                                                ),
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
                                  _selectedIndex.value != null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                    ),
                                    child: SpeakToConfirmOverlay(
                                      expectedText:
                                          options[_selectedIndex.value!],
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
