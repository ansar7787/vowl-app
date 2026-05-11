import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceSwapScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VoiceSwapScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.voiceSwap,
  });

  @override
  State<VoiceSwapScreen> createState() => _VoiceSwapScreenState();
}

class _VoiceSwapScreenState extends State<VoiceSwapScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isPassive = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _isFinalFailure = false;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer(String correctAnswer) {
    if (_isAnswered) return;
    
    final selectedVoice = _isPassive ? "Passive" : "Active";
    bool isCorrect = selectedVoice.toLowerCase() == correctAnswer.toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFinalFailure = state.isFinalFailure;
              _isPassive = false;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'VOICE CRYSTALLIZED!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: _isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildSentenceDisplay(quest.sentence ?? "", theme.primaryColor, isDark),
              SizedBox(height: 80.h),
              _buildVoiceToggleSwitch(theme.primaryColor, isDark),
              SizedBox(height: 48.h),
              _buildCurrentModeDisplay(theme.primaryColor),
              const Spacer(),
              if (!_isAnswered)
                ScaleButton(
                  onTap: () => _submitAnswer(quest.correctAnswer ?? "Passive"),
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r), 
                      gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)]),
                      boxShadow: [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
                    ),
                    child: Center(child: Text("ENGAGE TRANSMUTER", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
                ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_input_component_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "FLIP THE VOICE TRANSMUTER", 
            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceDisplay(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(28.r),
      child: Column(
        children: [
          Text("VOICE FREQUENCY", style: GoogleFonts.outfit(fontSize: 9.sp, fontWeight: FontWeight.w900, color: primaryColor.withValues(alpha: 0.6), letterSpacing: 2)),
          SizedBox(height: 12.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, color: isDark ? Colors.white : Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildVoiceToggleSwitch(Color primaryColor, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggleLabel("ACTIVE", !_isPassive, primaryColor, isDark),
            SizedBox(width: 20.w),
            GestureDetector(
              onTap: () {
                if (_isAnswered) return;
                setState(() => _isPassive = !_isPassive);
                _hapticService.heavy();
                _soundService.playCorrect(); 
              },
              child: Container(
                width: 120.w, height: 60.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      left: _isPassive ? 60.w : 4.w,
                      top: 4.h,
                      child: Container(
                        width: 52.w, height: 48.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 24.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20.w),
            _buildToggleLabel("PASSIVE", _isPassive, primaryColor, isDark),
          ],
        ),
        SizedBox(height: 32.h),
        Container(
          width: 140.w, height: 10.h,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleLabel(String label, bool isActive, Color primaryColor, bool isDark) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: GoogleFonts.outfit(
        fontSize: 12.sp,
        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
        color: isActive ? primaryColor : (isDark ? Colors.white38 : Colors.black26),
        letterSpacing: 2,
      ),
      child: Text(label),
    );
  }

  Widget _buildCurrentModeDisplay(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("CURRENT STATE:", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w700, color: primaryColor.withValues(alpha: 0.6), letterSpacing: 1)),
          SizedBox(width: 12.w),
          Text(
            (_isPassive ? "PASSIVE" : "ACTIVE"), 
            style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 2)
          ).animate(key: ValueKey(_isPassive)).fadeIn().scale(),
        ],
      ),
    );
  }
}

