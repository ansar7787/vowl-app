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
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

class ClozeTestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ClozeTestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.clozeTest,
  });

  @override
  State<ClozeTestScreen> createState() => _ClozeTestScreenState();
}

class _ClozeTestScreenState extends State<ClozeTestScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _dockedOption;
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

  void _onDock(String option, String correct) {
    if (_isAnswered) return;
    setState(() => _dockedOption = option);
    _hapticService.success();
    _submitAnswer(option, correct);
  }

  void _submitAnswer(String selected, String correct) {
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _dockedOption = null;
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
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
              _dockedOption = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SEMANTIC MASTER!', enableDoubleUp: true);
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
                  SizedBox(height: 32.h),
                  
                  _buildPneumaticPort(quest.passage ?? "", quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 40.h),
                  
                  _buildFuelCells(quest.options ?? [], theme.primaryColor, isDark),
                  
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
          Icon(Icons.settings_input_component_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("INJECT FUEL CELLS TO POWER THE PASSAGE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPneumaticPort(String text, String correct, Color color, bool isDark) {
    final parts = text.split('____');
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
                children: [
                  TextSpan(text: parts[0]),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: DragTarget<String>(
                      onAcceptWithDetails: (details) => _onDock(details.data, correct),
                      builder: (context, candidateData, rejectedData) {
                        final bool correctDocked = _isAnswered && _dockedOption?.trim().toLowerCase() == correct.trim().toLowerCase();
                        final bool wrongDocked = _isAnswered && !correctDocked;

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: correctDocked 
                                ? Colors.greenAccent.withValues(alpha: 0.25)
                                : (wrongDocked 
                                    ? Colors.redAccent.withValues(alpha: 0.25)
                                    : (_dockedOption != null ? color.withValues(alpha: 0.2) : (isDark ? Colors.black45 : Colors.grey.shade200))),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: correctDocked 
                                  ? Colors.greenAccent 
                                  : (wrongDocked 
                                      ? Colors.redAccent 
                                      : (_dockedOption != null ? color : (isDark ? Colors.white24 : Colors.black12))), 
                              width: 2
                            ),
                            boxShadow: [
                              if (_dockedOption != null) 
                                BoxShadow(color: (correctDocked ? Colors.greenAccent : (wrongDocked ? Colors.redAccent : color)).withValues(alpha: 0.3), blurRadius: 15)
                            ],
                          ),
                          child: Text(
                            _dockedOption?.toUpperCase() ?? "DRAG HERE", 
                            style: GoogleFonts.shareTechMono(
                              fontSize: 12.sp, 
                              color: _dockedOption != null 
                                  ? (isDark ? Colors.white : Colors.black87) 
                                  : (isDark ? Colors.white30 : Colors.black38), 
                              fontWeight: FontWeight.w900
                            )
                          ),
                        ).animate(target: _dockedOption != null ? 1 : 0).shimmer(duration: 1.seconds);
                      },
                    ),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelCells(List<String> options, Color color, bool isDark) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        final bool isAlreadyDocked = _dockedOption == o;
        return Opacity(
          opacity: isAlreadyDocked ? 0.35 : 1.0,
          child: IgnorePointer(
            ignoring: isAlreadyDocked,
            child: Draggable<String>(
              data: o,
              feedback: Material(
                color: Colors.transparent,
                child: _buildCellWidget(o, color, isDark, true),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: _buildCellWidget(o, color, isDark, false)),
              child: _buildCellWidget(o, color, isDark, false),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCellWidget(String text, Color color, bool isDark, bool isFeedback) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: isDark ? 0.4 : 0.15), blurRadius: isFeedback ? 20 : 10),
          if (isFeedback) BoxShadow(color: Colors.white.withValues(alpha: 0.25), blurRadius: 40),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Text(
            text.toUpperCase(), 
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black87
            )
          ),
        ],
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
