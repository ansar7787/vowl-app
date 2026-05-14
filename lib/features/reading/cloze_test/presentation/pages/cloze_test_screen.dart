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
      Future.delayed(1.seconds, () => setState(() => _dockedOption = null));
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
              _buildPneumaticPort(quest.passage ?? "", quest.correctAnswer ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildFuelCells(quest.options ?? [], theme.primaryColor, isDark),
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
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.1),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.fredoka(fontSize: 20.sp, color: Colors.white70),
                children: [
                  TextSpan(text: parts[0]),
                  WidgetSpan(
                    child: DragTarget<String>(
                      onAcceptWithDetails: (details) => _onDock(details.data, correct),
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          width: 120.w, height: 40.h,
                          decoration: BoxDecoration(
                            color: _dockedOption != null ? color.withValues(alpha: 0.3) : Colors.black45,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: _dockedOption != null ? color : Colors.white24, width: 2),
                            boxShadow: [if (_dockedOption != null) BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15)],
                          ),
                          child: Center(
                            child: Text(_dockedOption?.toUpperCase() ?? "VACUUM", style: GoogleFonts.shareTechMono(fontSize: 14.sp, color: _dockedOption != null ? Colors.white : Colors.white24, fontWeight: FontWeight.w900)),
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
      spacing: 16.w, runSpacing: 16.h,
      alignment: WrapAlignment.center,
      children: options.map((o) => Draggable<String>(
        data: o,
        feedback: Material(
          color: Colors.transparent,
          child: _buildCellWidget(o, color, true),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildCellWidget(o, color, false)),
        child: _buildCellWidget(o, color, false),
      )).toList(),
    );
  }

  Widget _buildCellWidget(String text, Color color, bool isFeedback) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: isFeedback ? 20 : 10),
          if (isFeedback) BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 40),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

