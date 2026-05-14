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

class SubjectVerbAgreementScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SubjectVerbAgreementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.subjectVerbAgreement,
  });

  @override
  State<SubjectVerbAgreementScreen> createState() => _SubjectVerbAgreementScreenState();
}

class _SubjectVerbAgreementScreenState extends State<SubjectVerbAgreementScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  Offset _ringOffset = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onConnect(int targetIndex, int correctIndex) {
    if (_isAnswered) return;

    bool isCorrect = targetIndex == correctIndex;

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
        _ringOffset = Offset.zero;
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
              _ringOffset = Offset.zero;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'AGREEMENT MASTER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["Is", "Are"];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 24.h),
              
              // Optimized: Atmospheric Harmony Hub (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: theme.primaryColor.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 5)
                    ],
                  ),
                  child: Text(
                    quest.question ?? "Complete the agreement...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 22.sp,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Tuner Rails
                      Container(
                        height: 4.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withValues(alpha: 0.0),
                              theme.primaryColor.withValues(alpha: 0.4),
                              theme.primaryColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),

                      // Verb Terminals
                      _buildVerbTerminal(0, options[0], theme.primaryColor, Alignment.centerLeft, quest.correctAnswerIndex ?? 0),
                      _buildVerbTerminal(1, options[1], theme.primaryColor, Alignment.centerRight, quest.correctAnswerIndex ?? 0),
                      
                      // The Quantum Core (Harmony Slider)
                      if (!_isAnswered)
                        GestureDetector(
                          onPanUpdate: (details) {
                            setState(() => _ringOffset += details.delta);
                            _checkHarmony(quest.correctAnswerIndex ?? 0);
                          },
                          onPanEnd: (details) {
                            setState(() => _ringOffset = Offset.zero);
                          },
                          child: Transform.translate(
                            offset: _ringOffset,
                            child: _buildQuantumCore(theme.primaryColor),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }

  void _checkHarmony(int correctIndex) {
    final double threshold = 110.w;
    if (_ringOffset.dx < -threshold) {
      _onConnect(0, correctIndex);
    } else if (_ringOffset.dx > threshold) {
      _onConnect(1, correctIndex);
    }
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
          Icon(Icons.waves_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "TUNE THE LINGUISTIC HARMONY",
            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVerbTerminal(int index, String verb, Color primaryColor, Alignment alignment, int correctIndex) {
    final isCorrect = _isAnswered && _isCorrect == true && index == correctIndex;
    final isWrong = _isAnswered && _isCorrect == false && index != correctIndex;

    return Align(
      alignment: alignment,
      child: Container(
        width: 110.r, height: 110.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCorrect 
              ? Colors.greenAccent.withValues(alpha: 0.1) 
              : (isWrong ? Colors.redAccent.withValues(alpha: 0.1) : Colors.transparent),
          border: Border.all(
            color: isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : primaryColor.withValues(alpha: 0.2)),
            width: 2.5.r,
          ),
        ),
        child: Center(
          child: Text(
            verb.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : primaryColor),
            ),
          ),
        ),
      ).animate(target: isCorrect ? 1 : 0).shimmer(duration: 1.seconds).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
    );
  }

  Widget _buildQuantumCore(Color primaryColor) {
    return Container(
      width: 70.r, height: 70.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor,
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Center(
        child: Container(
          width: 20.r, height: 20.r,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
      ),
    );
  }
}

