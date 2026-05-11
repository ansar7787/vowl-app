import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class EmergencyHubScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmergencyHubScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emergencyHub,
  });

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> {
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

  void _onWheelUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _rotation = (_rotation + details.delta.dx / 100).clamp(0.0, 1.0);
    });
    _hapticService.selection();
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    
    bool isCorrect = index == correct;

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
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'HEROIC DISPATCH!', enableDoubleUp: true);
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
              _buildInstruction(),
              _buildControlPanel(quest.dispatcherQuestion ?? "Status report now!", isDark),
              _buildActionChambers(options, quest.correctAnswerIndex ?? 0),
              _buildPressureWheel(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction() {
    return Positioned(
      top: 10.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2))),
        child: Text("ROTATE THE VALVE TO THE CORRECT EMERGENCY RESPONSE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildControlPanel(String prompt, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Container(
        width: 0.85.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1))),
        child: Column(
          children: [
            Text("CRITICAL ALERT", style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: Colors.redAccent, letterSpacing: 4)).animate(onPlay: (c) => c.repeat()).shimmer(),
            SizedBox(height: 12.h),
            Text(prompt, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChambers(List<String> options, int correct) {
    return Stack(
      children: [
        for (int i = 0; i < options.length; i++)
          _buildChamber(i, options[i], correct),
      ],
    );
  }

  Widget _buildChamber(int index, String text, int correct) {
    double angle = (index * (3.14 * 2 / 3)) - (3.14 / 2);
    return Positioned(
      left: 0.5.sw + 130.w * cos(angle) - 50.w,
      top: 0.5.sh + 130.h * sin(angle) - 40.h,
      child: ScaleButton(
        onTap: () => _submitAnswer(index, correct),
        child: Container(
          width: 100.w, height: 80.h,
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildPressureWheel() {
    return Center(
      child: GestureDetector(
        onPanUpdate: _onWheelUpdate,
        child: Transform.rotate(
          angle: _rotation * 3.14 * 2,
          child: Container(
            width: 180.r, height: 180.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              border: Border.all(color: Colors.redAccent, width: 8),
              boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wheel Spokes
                for (int i = 0; i < 4; i++)
                  Transform.rotate(angle: i * 3.14 / 2, child: SizedBox(width: 4.w, height: 160.h, child: ColoredBox(color: Colors.redAccent.withValues(alpha: 0.3)))),
                // Center Knob
                Container(
                  width: 60.r, height: 60.r,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent, boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 20)]),
                  child: Icon(Icons.emergency_rounded, color: Colors.white, size: 30.r),
                ),
                // Indicator Needle
                Positioned(top: 10.r, child: Icon(Icons.arrow_drop_up_rounded, color: Colors.white, size: 40.r)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

