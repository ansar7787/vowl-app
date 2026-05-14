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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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

  void _submitAnswer(GameQuest? quest) {
    if (_isAnswered || quest == null) return;
    
    final selectedVoice = _isPassive ? "Passive" : "Active";
    // Check if the correct answer matches the selected voice category
    bool isCorrect = selectedVoice.toLowerCase() == (quest.correctAnswerCategory?.toLowerCase() ?? quest.correctAnswer?.toLowerCase());

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
          
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
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
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: Concise Context Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Text(
                    quest.sentence ?? "",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 20.sp,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              SizedBox(height: 60.h),
              
              // The Transmuter (Kinetic Energy)
              _buildVoiceToggleSwitch(theme.primaryColor, isDark),
              
              const Spacer(),
              
              if (!_isAnswered)
                ScaleButton(
                  onTap: () => _submitAnswer(quest),
                  child: Container(
                    width: double.infinity, height: 65.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r), 
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)]
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.4), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ]
                    ),
                    child: Center(
                      child: Text(
                        "ENGAGE TRANSMUTER", 
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white, 
                          letterSpacing: 3
                        )
                      )
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
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
                _soundService.playClick(); 
              },
              child: Container(
                width: 130.w, height: 65.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(35.r),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 2),
                ),
                child: Stack(
                  children: [
                    // Energy Pulse Track
                    Center(
                      child: Container(
                        width: 100.w, height: 4.h,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      left: _isPassive ? 66.w : 4.w,
                      top: 4.h,
                      child: Container(
                        width: 58.w, height: 53.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4), 
                              blurRadius: 15, 
                              offset: const Offset(0, 5)
                            )
                          ],
                        ),
                        child: Icon(
                          _isPassive ? Icons.waves_rounded : Icons.bolt_rounded, 
                          color: Colors.white, 
                          size: 26.r
                        ),
                      ).animate(key: ValueKey(_isPassive)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
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
        Text(
          "MODE: ${(_isPassive ? "PASSIVE" : "ACTIVE")}",
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: primaryColor.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ).animate(key: ValueKey(_isPassive)).fadeIn().scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }

  Widget _buildToggleLabel(String label, bool isActive, Color primaryColor, bool isDark) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: GoogleFonts.outfit(
        fontSize: 14.sp,
        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
        color: isActive ? primaryColor : (isDark ? Colors.white24 : Colors.black26),
        letterSpacing: 2,
      ),
      child: Text(label),
    );
  }
}

