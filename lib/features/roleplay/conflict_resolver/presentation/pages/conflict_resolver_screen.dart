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

class ConflictResolverScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConflictResolverScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conflictResolver,
  });

  @override
  State<ConflictResolverScreen> createState() => _ConflictResolverScreenState();
}

class _ConflictResolverScreenState extends State<ConflictResolverScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  double _rotation = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onDialUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _rotation = (_rotation + details.delta.dx / 100).clamp(0.0, 1.0);
    });
    _hapticService.selection();
  }

  void _submitAnswer(double target) {
    if (_isAnswered) return;
    
    bool isCorrect = (_rotation - target).abs() < 0.15;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
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
              _rotation = 0.0;
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'PEACEKEEPER!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildConflictCloud(theme.primaryColor),
              _buildDialogueFrame(quest.scene ?? "", theme.primaryColor, isDark),
              _buildPrecisionDial(theme.primaryColor),
              if (!_isAnswered) _buildResolveButton(theme.primaryColor, quest.empathyScore ?? 0.75),
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
        child: Text("ROTATE THE DIAL TO COOL THE CONFLICT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildConflictCloud(Color color) {
    Color cloudColor = Color.lerp(Colors.redAccent, Colors.cyanAccent, _rotation) ?? color;
    return Center(
      child: Container(
        width: 300.r, height: 300.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [cloudColor.withValues(alpha: 0.4), Colors.transparent]),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds).blur(begin: const Offset(10, 10), end: const Offset(30, 30)),
    );
  }

  Widget _buildDialogueFrame(String scene, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Container(
        width: 0.85.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Text(scene, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildPrecisionDial(Color color) {
    return Positioned(
      bottom: 120.h,
      child: GestureDetector(
        onPanUpdate: _onDialUpdate,
        child: Transform.rotate(
          angle: _rotation * 3.14 * 2,
          child: Container(
            width: 140.r, height: 140.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey[400]!]),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(5, 5))],
              border: Border.all(color: color.withValues(alpha: 0.3), width: 4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(top: 10.r, child: Container(width: 8.r, height: 20.r, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.r)))),
                Icon(Icons.tune_rounded, color: color.withValues(alpha: 0.5), size: 40.r),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResolveButton(Color color, double target) {
    return Positioned(
      bottom: 40.h,
      child: ScaleButton(
        onTap: () => _submitAnswer(target),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.r), gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)])),
          child: Text("LOCK TONE", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        ),
      ),
    );
  }
}

