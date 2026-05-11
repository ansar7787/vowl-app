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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class TrueFalseReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TrueFalseReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.trueFalseReading,
  });

  @override
  State<TrueFalseReadingScreen> createState() => _TrueFalseReadingScreenState();
}

class _TrueFalseReadingScreenState extends State<TrueFalseReadingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _coinX = 0.0;
  double _coinY = 0.0;
  double _coinRotation = 0.0;
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

  void _onFlick(Offset delta) {
    if (_isAnswered) return;
    setState(() {
      _coinX += delta.dx;
      _coinY += delta.dy;
      _coinRotation += (delta.dx + delta.dy) / 100;
      _hapticService.selection();
    });
    
    if (_coinX.abs() > 100.w) {
      _submitAnswer(_coinX > 0, (context.read<ReadingBloc>().state as ReadingLoaded).currentQuest.correctAnswer ?? "");
    }
  }

  void _submitAnswer(bool val, String correct) {
    if (_isAnswered) return;
    bool isCorrect = (val ? "true" : "false") == correct.trim().toLowerCase();

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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _coinX = 0.0;
              _coinY = 0.0;
              _coinRotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'FACT CHECKER!', enableDoubleUp: true);
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
              SizedBox(height: 24.h),
              _buildPassageViewer(quest.passage ?? "", theme.primaryColor, isDark),
              SizedBox(height: 32.h),
              _buildStatementBanner(quest.question ?? "", theme.primaryColor),
              const Spacer(),
              _buildCoinFlipZone(theme.primaryColor, isDark),
              const Spacer(),
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
          Icon(Icons.published_with_changes_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("FLICK THE TRUTH COIN TO VALIDATE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPassageViewer(String passage, Color color, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(20.r),
      color: color.withValues(alpha: 0.05),
      child: Text(passage, style: GoogleFonts.fredoka(fontSize: 16.sp, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildStatementBanner(String statement, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15.r), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text('"$statement"', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: color, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildCoinFlipZone(Color color, bool isDark) {
    return SizedBox(
      height: 250.h, width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Slots
          Positioned(left: 20.w, child: _buildSlot("FALSE", Colors.redAccent, isDark)),
          Positioned(right: 20.w, child: _buildSlot("TRUE", Colors.greenAccent, isDark)),
          
          // The Coin
          Transform.translate(
            offset: Offset(_coinX, _coinY),
            child: Transform.rotate(
              angle: _coinRotation,
              child: GestureDetector(
                onPanUpdate: (details) => _onFlick(details.delta),
                child: Container(
                  width: 100.r, height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amberAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(child: Icon(Icons.stars_rounded, color: Colors.white, size: 48.r)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(String label, Color color, bool isDark) {
    bool isTargeted = (_coinX > 0 && label == "TRUE") || (_coinX < 0 && label == "FALSE");
    return Opacity(
      opacity: isTargeted ? 1.0 : 0.3,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(label, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        ),
      ),
    );
  }
}

