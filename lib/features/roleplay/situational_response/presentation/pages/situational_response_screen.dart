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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SituationalResponseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SituationalResponseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationalResponse,
  });

  @override
  State<SituationalResponseScreen> createState() => _SituationalResponseScreenState();
}

class _SituationalResponseScreenState extends State<SituationalResponseScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onOrbTap(int index, int correctIndex) {
    if (_isAnswered) return;
    _stopTimer();
    setState(() {
      _isAnswered = true;
      _isCorrect = index == correctIndex;
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

  void _startTimer() {
    // Simulated timer for interaction logic
  }

  void _stopTimer() {
    // Stop timer logic
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
            });
            _startTimer();
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SOCIAL GENIUS!', enableDoubleUp: true);
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
              _buildSceneDisplay(quest.scene ?? "", theme.primaryColor, isDark),
              _buildTensionCore(theme.primaryColor),
              ...List.generate(options.length, (i) => _buildReactionOrb(i, options[i], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark)),
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
        child: Text("REPLICATE THE BEST REACTION BEFORE THE TENSION PEAKS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSceneDisplay(String scene, Color color, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Container(
        width: 0.85.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Text(scene, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87)),
      ),
    );
  }

  Widget _buildTensionCore(Color color) {
    return Container(
      width: 140.r, height: 140.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 4),
      ),
      child: Center(
        child: Icon(Icons.flash_on_rounded, color: color, size: 60.r)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 0.8.seconds),
      ),
    );
  }

  Widget _buildReactionOrb(int index, String text, int correctIndex, Color color, bool isDark) {
    double radius = 120.r;
    
    return Positioned(
      left: 1.sw / 2 + radius * 0.8 * (index == 0 ? -1 : (index == 1 ? 1 : 0)) - 60.r,
      top: 0.5.sh + radius * 0.8 * (index == 2 ? 1 : -0.5) - 60.r,
      child: ScaleButton(
        onTap: () => _onOrbTap(index, correctIndex),
        child: Container(
          width: 120.r, height: 120.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color)),
            ),
          ),
        ),
      ).animate(onPlay: (c) => c.repeat()).moveY(begin: -5, end: 5, duration: (1 + index * 0.5).seconds, curve: Curves.easeInOut),
    );
  }
}

