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

class GuessTitleScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GuessTitleScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.guessTitle,
  });

  @override
  State<GuessTitleScreen> createState() => _GuessTitleScreenState();
}

class _GuessTitleScreenState extends State<GuessTitleScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _selectedTitle;
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

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _selectedTitle = selected;
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
              _selectedTitle = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TITLE EXPERT!', enableDoubleUp: true);
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
                  _buildCargoCrate(quest.passage ?? "", quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  _buildLabelRack(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor, isDark),
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
          Icon(Icons.inventory_2_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SNAP THE TITLE LABEL ONTO THE CRATE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCargoCrate(String passage, String correct, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            passage, 
            style: GoogleFonts.fredoka(
              fontSize: 16.sp, 
              height: 1.5, 
              color: isDark ? Colors.white70 : Colors.black87
            )
          ),
          SizedBox(height: 32.h),
          DragTarget<String>(
            onWillAcceptWithDetails: (details) => !_isAnswered,
            onAcceptWithDetails: (details) {
              _submitAnswer(details.data, correct);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              final Color borderClr = _isAnswered 
                  ? (_isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
                  : (isHovered ? color : color.withValues(alpha: 0.4));
              
              return Container(
                height: 70.h, width: double.infinity,
                decoration: BoxDecoration(
                  color: borderClr.withValues(alpha: isHovered ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderClr, width: 2, style: BorderStyle.solid),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: _selectedTitle != null
                        ? Text(
                            _selectedTitle!.toUpperCase(), 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp, 
                              fontWeight: FontWeight.w900, 
                              color: _isCorrect == true ? Colors.greenAccent : Colors.redAccent
                            )
                          )
                        : Text(
                            "DRAG & DROP TITLE HERE", 
                            style: GoogleFonts.shareTechMono(
                              color: color.withValues(alpha: isHovered ? 0.8 : 0.4), 
                              fontSize: 13.sp,
                              letterSpacing: 1.5
                            )
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabelRack(List<String> labels, String correct, Color color, bool isDark) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: List.generate(labels.length, (index) {
        final label = labels[index];
        final isSelected = _selectedTitle == label;
        
        if (_isAnswered && !isSelected) {
          return Opacity(
            opacity: 0.2,
            child: _buildLabelCard(label, color, isDark, enabled: false),
          );
        }
        
        return Draggable<String>(
          data: label,
          maxSimultaneousDrags: _isAnswered ? 0 : 1,
          feedback: Material(
            color: Colors.transparent,
            child: _buildLabelCard(label, color, isDark, isFeedback: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _buildLabelCard(label, color, isDark),
          ),
          child: _buildLabelCard(label, color, isDark),
        );
      }),
    );
  }

  Widget _buildLabelCard(String label, Color color, bool isDark, {bool isFeedback = false, bool enabled = true}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12, 
            blurRadius: isFeedback ? 15 : 6, 
            offset: Offset(0, isFeedback ? 8 : 2)
          )
        ],
        border: Border.all(
          color: isFeedback ? color : (isDark ? Colors.white10 : Colors.grey.shade300),
          width: 2
        ),
      ),
      child: Text(
        label.toUpperCase(), 
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 12.sp, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white70 : Colors.black87
        )
      ),
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
