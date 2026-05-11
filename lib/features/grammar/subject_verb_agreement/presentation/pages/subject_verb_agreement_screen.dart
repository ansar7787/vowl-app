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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
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
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 48.h),
              _buildSubjectCore(quest.subject ?? "THE SUBJECT", theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Verb Options
                    _buildVerbOption(0, options[0], theme.primaryColor, Alignment.centerLeft, quest.correctAnswerIndex ?? 0),
                    _buildVerbOption(1, options[1], theme.primaryColor, Alignment.centerRight, quest.correctAnswerIndex ?? 0),
                    
                    // The Marriage Ring
                    if (!_isAnswered)
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() => _ringOffset += details.delta);
                          _checkConnection(quest.correctAnswerIndex ?? 0);
                        },
                        onPanEnd: (details) {
                          setState(() => _ringOffset = Offset.zero);
                        },
                        child: Transform.translate(
                          offset: _ringOffset,
                          child: _buildRing(theme.primaryColor),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }

  void _checkConnection(int correctIndex) {
    final threshold = 100.w;
    if (_ringOffset.dx < -threshold) {
      _onConnect(0, correctIndex);
    } else if (_ringOffset.dx > threshold) {
      _onConnect(1, correctIndex);
    }
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("UNITE SUBJECT AND VERB", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSubjectCore(String subject, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      borderRadius: BorderRadius.circular(50.r),
      child: Column(
        children: [
          Text("THE SUBJECT", style: GoogleFonts.outfit(fontSize: 9.sp, fontWeight: FontWeight.w900, color: primaryColor.withValues(alpha: 0.6), letterSpacing: 2)),
          SizedBox(height: 8.h),
          Text(subject, style: GoogleFonts.fredoka(fontSize: 24.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white24);
  }

  Widget _buildVerbOption(int index, String verb, Color primaryColor, Alignment alignment, int correctIndex) {
    final isCorrect = _isAnswered && _isCorrect == true && index == correctIndex;
    return Align(
      alignment: alignment,
      child: Container(
        width: 120.r, height: 120.r,
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: isCorrect ? Colors.greenAccent : primaryColor.withValues(alpha: 0.2), width: 2.r),
        ),
        child: Center(
          child: Text(verb, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: isCorrect ? Colors.greenAccent : primaryColor)),
        ),
      ),
    );
  }

  Widget _buildRing(Color primaryColor) {
    return Container(
      width: 70.r, height: 70.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber, width: 6.r),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Center(
        child: Container(
          width: 20.r, height: 20.r,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
      ),
    );
  }
}

