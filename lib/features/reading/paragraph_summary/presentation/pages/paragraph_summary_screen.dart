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
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

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
  bool _isDistilled = false;
  String? _selectedOption;
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
    if (_isAnswered || _isDistilled) return;
    setState(() {
      _pinchWidth = scale.clamp(0.4, 1.0);
      if (_pinchWidth < 0.6) {
        _hapticService.selection();
      }
    });
  }

  void _onPinchEnd() {
    if (_isAnswered || _isDistilled) return;
    if (_pinchWidth < 0.55) {
      _hapticService.heavy();
      setState(() {
        _isDistilled = true;
        _pinchWidth = 0.45;
      });
    } else {
      setState(() => _pinchWidth = 1.0);
    }
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    final isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
              _isDistilled = false;
              _pinchWidth = 1.0;
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
        final ReadingQuest? quest = (state is ReadingLoaded) ? state.currentQuest as ReadingQuest? : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  // Distillation Squeeze Tube
                  GestureDetector(
                    onScaleUpdate: (details) => _onPinchUpdate(details.scale),
                    onScaleEnd: (details) => _onPinchEnd(),
                    child: _buildDistillationTube(quest.passage ?? "", quest.keywords ?? [], theme.primaryColor, isDark),
                  ),
                  
                  SizedBox(height: 16.h),
                  Text(
                    _isDistilled 
                        ? "DISTILLATION COMPLETE! SELECT THE CORE SUMMARY:" 
                        : "PINCH/SQUEEZE THE TUBE TO DISTILL CORE CONCEPTS", 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      color: _isDistilled ? Colors.greenAccent : theme.primaryColor.withValues(alpha: 0.6), 
                      fontSize: 11.sp, 
                      letterSpacing: 2
                    )
                  ),
                  
                  if (_isDistilled) ...[
                    SizedBox(height: 24.h),
                    _buildOptionRack(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  ],
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    _buildCorrectResult(quest, theme.primaryColor, isDark),
                  ],
                  SizedBox(height: 60.h),
                ],
              ),
            ),
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
          Text("SQUEEZE TUBE TO DISTILL & SUMMARIZE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDistillationTube(String passage, List<String> keywords, Color color, bool isDark) {
    return AnimatedContainer(
      duration: 200.milliseconds,
      width: 320.w * _pinchWidth,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r * _pinchWidth),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 2),
        ],
      ),
      child: AnimatedSwitcher(
        duration: 400.milliseconds,
        child: !_isDistilled
            ? Text(
                passage, 
                key: const ValueKey("passage"),
                textAlign: TextAlign.center, 
                style: GoogleFonts.fredoka(
                  fontSize: 15.sp, 
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87
                )
              )
            : Wrap(
                key: const ValueKey("keywords"),
                spacing: 10.w, runSpacing: 10.h,
                alignment: WrapAlignment.center,
                children: keywords.map((k) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), 
                    borderRadius: BorderRadius.circular(20.r), 
                    border: Border.all(color: color, width: 2)
                  ),
                  child: Text(
                    k.toUpperCase(), 
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : color
                    )
                  ),
                ).animate().scale(duration: 300.milliseconds)).toList(),
              ),
      ),
    );
  }

  Widget _buildOptionRack(List<String> options, String correct, Color color, bool isDark) {
    return Column(
      children: options.map((opt) {
        final bool isSelected = _selectedOption == opt;
        
        Color cardColor = isDark ? Colors.grey.shade900 : Colors.white;
        Color borderColor = isDark ? Colors.white10 : Colors.grey.shade300;
        
        if (_isAnswered) {
          if (opt.trim().toLowerCase() == correct.trim().toLowerCase()) {
            cardColor = Colors.greenAccent.withValues(alpha: 0.15);
            borderColor = Colors.greenAccent;
          } else if (isSelected) {
            cardColor = Colors.redAccent.withValues(alpha: 0.15);
            borderColor = Colors.redAccent;
          }
        } else if (isSelected) {
          borderColor = color;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTap: () => _submitAnswer(opt, correct),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.black12, 
                    blurRadius: 6, 
                    offset: const Offset(0, 2)
                  )
                ],
              ),
              child: Text(
                opt, 
                style: GoogleFonts.outfit(
                  fontSize: 13.sp, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white70 : Colors.black87
                )
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCorrectResult(ReadingQuest quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT!" : "INCORRECT",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
