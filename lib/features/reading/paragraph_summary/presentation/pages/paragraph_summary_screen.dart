import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParagraphSummaryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ParagraphSummaryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.paragraphSummary,
  });

  @override
  State<ParagraphSummaryScreen> createState() => _ParagraphSummaryScreenState();
}

class _ParagraphSummaryScreenState extends State<ParagraphSummaryScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _pinchWidth = 1.0;
  bool _isDistilling = false;
  final Set<String> _selectedKeywords = {};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPinchUpdate(double scale) {
    if (_isAnswered || _isDistilling) return;
    setState(() {
      _pinchWidth = scale.clamp(0.4, 1.0);
      if (_pinchWidth < 0.6) {
        _hapticService.selection();
      }
    });
  }

  void _onPinchEnd(List<String> correct) {
    if (_isAnswered || _isDistilling) return;
    if (_pinchWidth < 0.5) {
      _startDistillation(correct);
    } else {
      setState(() => _pinchWidth = 1.0);
    }
  }

  void _startDistillation(List<String> correct) {
    setState(() => _isDistilling = true);
    _hapticService.heavy();
    
    // Simulate "Distillation" process
    Future.delayed(1.seconds, () {
      if (mounted) {
        _submitAnswer(correct);
      }
    });
  }

  void _submitAnswer(List<String> correctKeywords) {
    // In this mode, we automatically select the most relevant keywords based on "distillation"
    // The user's goal is to reach the distillation threshold. 
    // If they have selected keywords manually before (or we can just make it a threshold-based win)
    
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { 
      _isAnswered = true; 
      _isCorrect = true; 
      _isDistilling = false;
      _pinchWidth = 0.4;
    });
    context.read<ReadingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedKeywords.clear();
              _pinchWidth = 1.0;
              _isDistilling = false;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTHESIS EXPERT!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 48.h),
              Expanded(
                child: Center(
                  child: _buildDistillationTube(quest.passage ?? "", quest.keywords ?? [], theme.primaryColor, isDark),
                ),
              ),
              if (!_isAnswered)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Text("PINCH TO DISTILL CORE CONCEPTS", style: GoogleFonts.shareTechMono(color: theme.primaryColor.withValues(alpha: 0.6), fontSize: 12.sp, letterSpacing: 2)),
                ),
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
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SQUEEZE TO SYMBOLIZE LOGIC", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDistillationTube(String passage, List<String> keywords, Color color, bool isDark) {
    return GestureDetector(
      onScaleUpdate: (details) => _onPinchUpdate(details.scale),
      onScaleEnd: (details) => _onPinchEnd(keywords),
      child: AnimatedContainer(
        duration: 200.milliseconds,
        width: 300.w * _pinchWidth,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r * _pinchWidth),
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 10),
            if (_isDistilling) BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 50, spreadRadius: 20),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              if (!_isAnswered && !_isDistilling)
                Text(passage, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 14.sp * (1 / _pinchWidth).clamp(1.0, 2.0), color: Colors.white70))
              else if (_isDistilling)
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 2).animate().scale(duration: 1.seconds)
              else
                Wrap(
                  spacing: 12.w, runSpacing: 12.h,
                  alignment: WrapAlignment.center,
                  children: keywords.map((k) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15.r), border: Border.all(color: color)),
                    child: Text(k.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                  ).animate().fadeIn(delay: 200.milliseconds).slideY(begin: 0.5)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

