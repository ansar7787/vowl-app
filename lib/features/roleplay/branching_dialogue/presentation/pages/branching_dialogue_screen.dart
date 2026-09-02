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
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_instruction.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_persona_console.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_console_board.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_relationship_meter.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _springController;

  int _lastProcessedIndex = -1;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);

  // Drag and drop mechanics relative points
  final ValueNotifier<Offset> _probeOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<int?> _hoveredIndex = ValueNotifier(null);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

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

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _probeOffset.dispose();
    _hoveredIndex.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.scene ?? "");
  }

  void _onProbeDragStart(DragStartDetails details) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _springController.stop();
  }

  void _onProbeDragUpdate(
    DragUpdateDetails details,
    Offset launchCenter,
    List<Offset> terminalCenters,
  ) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

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
        _hapticService.selection();
        _soundService.playHint(); // Play Lock-on alert bleep
      }
    }
  }

  void _onProbeDragEnd(int correctIndex) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    if (_hoveredIndex.value != null) {
      _submitChoice(_hoveredIndex.value!, correctIndex);
    } else {
      _springController.forward(from: 0.0);
      _hapticService.selection();
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    final isCorrect = index == correct;
    _selectedIndex.value = index;
    _hoveredIndex.value = null;

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
          if (state.currentIndex != _lastProcessedIndex ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _probeOffset.value = Offset.zero;
            _hoveredIndex.value = null;
            _selectedIndex.value = null;
            _isFirstStagePassed.value = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALOGUE DIRECTOR!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _probeOffset, _hoveredIndex, _selectedIndex, _isFirstStagePassed]),
            builder: (context, _) {
              return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
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
                                controller: ScrollController(),
                                thumbColor: theme.primaryColor.withValues(alpha: 0.5),
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
                                                final isCompact = constraints.maxHeight < 580;
                                                return Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                    vertical: isCompact ? 5.h : 10.h,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      BranchingDialogueInstruction(
                                                        primaryColor: theme.primaryColor,
                                                        instruction: quest.instruction,
                                                      ),
                                                      SizedBox(height: isCompact ? 10.h : 16.h),
                                                      if (_isAnswered.value && _selectedIndex.value != null && quest.consequenceScores != null)
                                                        Padding(
                                                          padding: EdgeInsets.only(bottom: isCompact ? 10.h : 16.h),
                                                          child: BranchingDialogueRelationshipMeter(
                                                            consequenceScore: quest.consequenceScores![_selectedIndex.value!],
                                                            primaryColor: theme.primaryColor,
                                                            isDark: isDark,
                                                          ),
                                                        ),
                                                      BranchingDialoguePersonaConsole(
                                                        quest: quest,
                                                        color: theme.primaryColor,
                                                        isDark: isDark,
                                                        onListen: () => _triggerAutoPlay(quest),
                                                      ),
                                                      SizedBox(height: isCompact ? 12.h : 20.h),
                                                      BranchingDialogueConsoleBoard(
                                                        options: options,
                                                        consequencePreviews: quest.consequencePreviews ?? [],
                                                        correctIndex: quest.correctAnswerIndex ?? 0,
                                                        color: theme.primaryColor,
                                                        isDark: isDark,
                                                        probeOffset: _probeOffset.value,
                                                        hoveredIndex: _hoveredIndex.value,
                                                        selectedIndex: _selectedIndex.value,
                                                        isAnswered:
                                                            _isAnswered.value || _isFirstStagePassed.value,
                                                        onProbeDragStart: _onProbeDragStart,
                                                        onProbeDragUpdate: _onProbeDragUpdate,
                                                        onProbeDragEnd: _onProbeDragEnd,
                                                        onOptionTapped: (index) => _submitChoice(
                                                          index,
                                                          quest.correctAnswerIndex ?? 0,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: isCompact ? 20.h : 40.h,
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
                                        height: (_isFirstStagePassed.value && !_isAnswered.value) ? 380.h : 60.h,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isFirstStagePassed.value && !_isAnswered.value && _selectedIndex.value != null)
                                SpeakToConfirmOverlay(
                                  expectedText: options[_selectedIndex.value!],
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
