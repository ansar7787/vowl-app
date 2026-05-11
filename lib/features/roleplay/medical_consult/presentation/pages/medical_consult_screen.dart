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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MedicalConsultScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MedicalConsultScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.medicalConsult,
  });

  @override
  State<MedicalConsultScreen> createState() => _MedicalConsultScreenState();
}

class _MedicalConsultScreenState extends State<MedicalConsultScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  final List<String> _selectedSymptoms = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Offset _scanPosition = Offset.zero;
  bool _isAcheFound = false;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onScanUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _scanPosition += details.delta;
      // Check for ache zone proximity
      if (_scanPosition.dx.abs() < 40.w && _scanPosition.dy.abs() < 40.h) {
        _isAcheFound = true;
        _hapticService.selection();
      } else {
        _isAcheFound = false;
      }
    });
  }

  void _onSymptomSelect(String symptom, String correctAnswer) {
    if (_isAnswered || !_isAcheFound) return;
    _submitAnswer(symptom, correctAnswer);
  }

  void _submitAnswer(String symptom, String correctAnswer) {
    bool isCorrect = symptom.toLowerCase() == correctAnswer.toLowerCase();

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
              _selectedSymptoms.clear();
              _scanPosition = Offset.zero;
              _isAcheFound = false;
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TOP SURGEON!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final symptoms = quest?.symptoms ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildSymptomDisplay(quest.prompt ?? "", theme.primaryColor, isDark),
              _buildBiometricScanner(theme.primaryColor),
              _buildTerminologyOrbit(symptoms, quest.correctAnswer ?? "", theme.primaryColor, isDark),
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
        child: Text("SCAN THE BIOMETRIC SILHOUETTE TO LOCATE THE SYMPTOM", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSymptomDisplay(String prompt, Color color, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Container(
        width: 0.85.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Text(prompt, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87)),
      ),
    );
  }

  Widget _buildBiometricScanner(Color color) {
    return GestureDetector(
      onPanUpdate: _onScanUpdate,
      child: Container(
        width: 1.sw, height: 0.4.sh,
        color: Colors.transparent,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Silhouette Wireframe
              Icon(Icons.accessibility_new_rounded, size: 240.r, color: color.withValues(alpha: 0.1))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2.seconds, color: color.withValues(alpha: 0.3)),
              // Ache Zone
              if (!_isAnswered) Positioned(
                child: Container(
                  width: 60.r, height: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.5, 1.5)).fadeOut(),
              ),
              // Scan Beam
              Transform.translate(
                offset: _scanPosition,
                child: Container(
                  width: 100.r, height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _isAcheFound ? Colors.greenAccent : color, width: 2),
                    boxShadow: [BoxShadow(color: (_isAcheFound ? Colors.greenAccent : color).withValues(alpha: 0.3), blurRadius: 15)],
                  ),
                  child: Icon(Icons.center_focus_strong_rounded, color: _isAcheFound ? Colors.greenAccent : color, size: 40.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminologyOrbit(List<String> symptoms, String correct, Color color, bool isDark) {
    return Positioned(
      bottom: 40.h,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.w,
        runSpacing: 12.h,
        children: symptoms.map((s) => ScaleButton(
          onTap: () => _onSymptomSelect(s, correct),
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            borderRadius: BorderRadius.circular(15.r),
            color: _isAcheFound ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.05),
            borderColor: _isAcheFound ? color : color.withValues(alpha: 0.1),
            child: Text(s.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: _isAcheFound ? color : (isDark ? Colors.white30 : Colors.black12))),
          ),
        )).toList(),
      ),
    );
  }
}

