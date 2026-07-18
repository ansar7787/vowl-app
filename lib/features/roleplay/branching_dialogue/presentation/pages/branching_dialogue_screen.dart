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
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  // Drag and drop mechanics relative points
  Offset _probeOffset = Offset.zero;
  int? _hoveredIndex;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _springController.addListener(() {
      setState(() {
        _probeOffset = Offset.lerp(
          _probeOffset,
          Offset.zero,
          _springController.value,
        )!;
      });
    });

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.scene ?? "");
  }

  void _onProbeDragStart(DragStartDetails details) {
    if (_isAnswered) return;
    _springController.stop();
  }

  void _onProbeDragUpdate(
    DragUpdateDetails details,
    Offset launchCenter,
    List<Offset> terminalCenters,
  ) {
    if (_isAnswered) return;

    setState(() {
      _probeOffset += details.delta;

      // Clamp boundaries inside bounds
      final double distance = _probeOffset.distance;
      if (distance > 240.h) {
        _probeOffset = Offset.fromDirection(_probeOffset.direction, 240.h);
      }
    });

    _checkTerminalHover(launchCenter, terminalCenters);
  }

  void _checkTerminalHover(Offset launchCenter, List<Offset> terminalCenters) {
    final Offset currentProbePos = launchCenter + _probeOffset;
    int? activeHoverIndex;

    for (int i = 0; i < terminalCenters.length; i++) {
      final double dist = (currentProbePos - terminalCenters[i]).distance;
      if (dist < 48.r) {
        activeHoverIndex = i;
        break;
      }
    }

    if (activeHoverIndex != _hoveredIndex) {
      setState(() {
        _hoveredIndex = activeHoverIndex;
      });
      if (activeHoverIndex != null) {
        _hapticService.selection();
        _soundService.playHint(); // Play Lock-on alert bleep
      }
    }
  }

  void _onProbeDragEnd(int correctIndex) {
    if (_isAnswered) return;

    if (_hoveredIndex != null) {
      _submitChoice(_hoveredIndex!, correctIndex);
    } else {
      _springController.forward(from: 0.0);
      _hapticService.selection();
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;

    final isCorrect = index == correct;
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _selectedIndex = index;
      _hoveredIndex = null;
    });

    if (isCorrect) {
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
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _probeOffset = Offset.zero;
              _hoveredIndex = null;
              _selectedIndex = null;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALOGUE DIRECTOR!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxHeight < 580;
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
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
                            BranchingDialoguePersonaConsole(
                              quest: quest,
                              color: theme.primaryColor,
                              isDark: isDark,
                              onListen: () => _triggerAutoPlay(quest),
                            ),
                            SizedBox(height: isCompact ? 12.h : 20.h),
                            BranchingDialogueConsoleBoard(
                              options: options,
                              correctIndex: quest.correctAnswerIndex ?? 0,
                              color: theme.primaryColor,
                              isDark: isDark,
                              probeOffset: _probeOffset,
                              hoveredIndex: _hoveredIndex,
                              selectedIndex: _selectedIndex,
                              isAnswered: _isAnswered,
                              onProbeDragStart: _onProbeDragStart,
                              onProbeDragUpdate: _onProbeDragUpdate,
                              onProbeDragEnd: _onProbeDragEnd,
                              onOptionTapped: (index) => _submitChoice(
                                index,
                                quest.correctAnswerIndex ?? 0,
                              ),
                            ),
                            SizedBox(
                              height: isCompact ? 40.h : 80.h,
                            ), // Safe spacing for base layouts
                          ],
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
