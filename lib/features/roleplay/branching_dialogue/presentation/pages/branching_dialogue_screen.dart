import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class _BranchingDialogueScreenState extends State<BranchingDialogueScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Offset _probePosition = Offset.zero;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onProbeUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _probePosition += details.delta;
    });
    _checkHover();
    _hapticService.selection();
  }

  void _checkHover() {
    // Basic proximity detection for terminals
    
    _hoveredIndex = null;
    if (_probePosition.dy < -100.h) {
      if (_probePosition.dx < -50.w) {
        _hoveredIndex = 0;
      } else if (_probePosition.dx > 50.w) {
        _hoveredIndex = 1;
      } else if (_probePosition.dx.abs() < 50.w) {
        _hoveredIndex = 2;
      }
    }
  }

  void _onProbeEnd(int correctIndex) {
    if (_isAnswered) return;
    if (_hoveredIndex != null) {
      _submitChoice(_hoveredIndex!, correctIndex);
    } else {
      setState(() => _probePosition = Offset.zero);
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _isCorrect = index == correct;
      _probePosition = Offset.zero;
      _hoveredIndex = null;
    });

    if (_isCorrect!) {
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
              _probePosition = Offset.zero;
              _hoveredIndex = null;
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'DIALOGUE DIRECTOR!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildHologramHeader(quest, theme.primaryColor, isDark),
              _buildPathGrid(options, theme.primaryColor, isDark),
              if (!_isAnswered) _buildDecisionProbe(theme.primaryColor, quest.correctAnswerIndex ?? 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 10.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("FLICK THE PROBE TO NAVIGATE THE BRANCH", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildHologramHeader(RoleplayQuest quest, Color color, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Column(
        children: [
          Container(
            width: 100.r, height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)],
            ),
            child: Icon(Icons.person_outline_rounded, color: color, size: 50.r),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
          SizedBox(height: 12.h),
          Text(quest.roleName?.toUpperCase() ?? "AGENT", style: GoogleFonts.shareTechMono(fontSize: 14.sp, color: color, letterSpacing: 2)),
          SizedBox(height: 16.h),
          Container(
            width: 0.8.sw,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: color.withValues(alpha: 0.1))),
            child: Text(quest.scene ?? "", textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildPathGrid(List<String> options, Color color, bool isDark) {
    return Center(
      child: Container(
        width: 1.sw, height: 0.4.sh,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(options.length, (index) => _buildTerminal(index, options[index], color, isDark)),
        ),
      ),
    );
  }

  Widget _buildTerminal(int index, String text, Color color, bool isDark) {
    bool isHovered = _hoveredIndex == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80.r, height: 80.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHovered ? color : color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            boxShadow: isHovered ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)] : [],
          ),
          child: Icon(Icons.hub_rounded, color: isHovered ? Colors.white : color, size: 32.r),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: 100.w,
          child: Text(text, textAlign: TextAlign.center, maxLines: 3, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isHovered ? color : color.withValues(alpha: 0.6))),
        ),
      ],
    );
  }

  Widget _buildDecisionProbe(Color color, int correctIndex) {
    return Positioned(
      bottom: 60.h,
      child: GestureDetector(
        onPanUpdate: _onProbeUpdate,
        onPanEnd: (_) => _onProbeEnd(correctIndex),
        child: Transform.translate(
          offset: _probePosition,
          child: Container(
            width: 80.r, height: 80.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)],
            ),
            child: Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 40.r),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
        ),
      ),
    );
  }
}

