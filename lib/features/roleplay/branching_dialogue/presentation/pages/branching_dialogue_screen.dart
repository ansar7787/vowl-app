import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_instruction.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_persona_console.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_explanation_card.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_path_painter.dart';

class BranchingDialogueScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const BranchingDialogueScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.branchingDialogue,
  });

  @override
  State<BranchingDialogueScreen> createState() => _BranchingDialogueScreenState();
}

class _BranchingDialogueScreenState extends State<BranchingDialogueScreen> with TickerProviderStateMixin {
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
        _probeOffset = Offset.lerp(_probeOffset, Offset.zero, _springController.value)!;
      });
    });

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
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

  void _onProbeDragUpdate(DragUpdateDetails details, Offset launchCenter, List<Offset> terminalCenters) {
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
          if (state.currentIndex != _lastProcessedIndex) {
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
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      BranchingDialogueInstruction(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),
                      BranchingDialoguePersonaConsole(
                        quest: quest,
                        color: theme.primaryColor,
                        isDark: isDark,
                        onListen: () => _triggerAutoPlay(quest),
                      ),
                      SizedBox(height: 20.h),
                      _buildConsoleBoard(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: BranchingDialogueExplanationCard(
                          quest: quest,
                          isDark: isDark,
                          isCorrect: _isCorrect,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h), // Safe spacing for base layouts
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildConsoleBoard(List<String> options, int correctIndex, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      height: 400.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Bottom launcher dock center
          final Offset launchCenter = Offset(width / 2, height - 70.h);

          // Calculate horizontal positioning of 3 terminal nodes evenly spaced along a curved arc
          final double leftPadding = 45.w;
          final List<Offset> terminalCenters = List.generate(options.length, (i) {
            double x = leftPadding + i * (width - 2 * leftPadding) / (options.length - 1);
            
            // Dip in vertical height at centers to create a beautiful sweeping arc curve
            double arcOffset = 25.h * math.sin((i / (options.length - 1)) * math.pi);
            double y = 80.h - arcOffset;
            return Offset(x, y);
          });

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Custom paint grid connector lanes
              Positioned.fill(
                child: CustomPaint(
                  painter: BranchingPathPainter(
                    probeOffset: _probeOffset,
                    launchCenter: launchCenter,
                    terminalCenters: terminalCenters,
                    hoveredIndex: _hoveredIndex,
                    themeColor: color,
                    isAnswered: _isAnswered,
                    selectedIndex: _selectedIndex,
                    correctIndex: correctIndex,
                  ),
                ),
              ),

              // Orbiting path nodes (Dialogue Terminal options)
              ...List.generate(options.length, (i) {
                final Offset termPos = terminalCenters[i];
                return _buildPathTerminalNode(i, options[i], termPos, correctIndex, color, isDark);
              }),

              // Launch pad base
              Positioned(
                left: launchCenter.dx - 45.r,
                top: launchCenter.dy - 45.r,
                child: Container(
                  width: 90.r,
                  height: 90.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                  ),
                ),
              ),

              // Interactive Decision Probe
              if (!_isAnswered)
                Positioned(
                  left: launchCenter.dx + _probeOffset.dx - 36.r,
                  top: launchCenter.dy + _probeOffset.dy - 36.r,
                  child: GestureDetector(
                    onPanStart: _onProbeDragStart,
                    onPanUpdate: (details) => _onProbeDragUpdate(details, launchCenter, terminalCenters),
                    onPanEnd: (_) => _onProbeDragEnd(correctIndex),
                    child: Container(
                      width: 72.r,
                      height: 72.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.white,
                        size: 32.r,
                      ),
                    ).animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    ).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPathTerminalNode(
    int index,
    String text,
    Offset position,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isHovered = _hoveredIndex == index;
    final bool isSelected = _selectedIndex == index;
    final bool hideOther = _isAnswered && !isSelected;

    Color termColor = color;
    if (_isAnswered && isSelected) {
      termColor = (index == correctIndex) ? Colors.greenAccent : Colors.redAccent;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      left: position.dx - 48.w,
      top: position.dy - 60.h,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hideOther ? 0.0 : 1.0,
        child: Column(
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered ? color : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
                border: Border.all(
                  color: isSelected ? termColor : color.withValues(alpha: 0.5),
                  width: isSelected || isHovered ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? termColor : color).withValues(alpha: isHovered || isSelected ? 0.35 : 0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _isAnswered && isSelected
                    ? (index == correctIndex ? Icons.verified_rounded : Icons.cancel_outlined)
                    : Icons.alt_route_rounded,
                color: isHovered || (_isAnswered && isSelected)
                    ? Colors.white
                    : color,
                size: 28.r,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 90.w,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isHovered
                      ? color
                      : (isDark ? Colors.white70 : Colors.black87),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
