import 'dart:ui';
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

class FindWordMeaningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FindWordMeaningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.findWordMeaning,
  });

  @override
  State<FindWordMeaningScreen> createState() => _FindWordMeaningScreenState();
}

class _FindWordMeaningScreenState extends State<FindWordMeaningScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _lensPos = const Offset(200, 300);
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

  void _onLensMove(Offset position) {
    if (_isAnswered) return;
    setState(() {
      _lensPos = position;
      _hapticService.selection();
    });
  }

  void _onWordTap(String word, String correct) {
    if (_isAnswered) return;

    bool isCorrect = word.trim().toLowerCase() == correct.trim().toLowerCase();

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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _lensPos = const Offset(200, 300);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LEXICAL MASTER!', enableDoubleUp: true);
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
              _buildQuestionHeader(quest.question ?? "", theme.primaryColor, isDark),
              SizedBox(height: 32.h),
              _buildMagnifierField(quest.passage ?? "", quest.targetWord ?? "", theme.primaryColor, isDark),
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
          Icon(Icons.zoom_in_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SCAN THE MANUSCRIPT WITH THE LEXICAL LENS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(String text, Color color, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(20.r),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: color, size: 24.r),
          SizedBox(width: 16.w),
          Expanded(child: Text("LOCATE THE WORD MEANING: $text", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildMagnifierField(String passage, String correct, Color color, bool isDark) {
    final words = passage.split(' ');
    return SizedBox(
      height: 420.h, width: double.infinity,
      child: Stack(
        children: [
          // The Blurred Manuscript
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(24.r)),
            child: Wrap(
              spacing: 6.w, runSpacing: 8.h,
              children: words.map((w) {
                final cleanWord = w.replaceAll(RegExp(r'[.!?]'), '').trim();
                double x = (words.indexOf(w) % 5) * 60.w;
                double y = (words.indexOf(w) ~/ 5) * 30.h;
                double dist = (_lensPos - Offset(x + 100.w, y + 100.h)).distance;
                bool isFocused = dist < 80.r;
                
                return GestureDetector(
                  onTap: () => _onWordTap(cleanWord, correct),
                  child: Opacity(
                    opacity: isFocused || _isAnswered ? 1.0 : 0.3,
                    child: Text(w, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isFocused ? Colors.white : (isDark ? Colors.white54 : Colors.black54), fontWeight: isFocused ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // The Magnifying Lens
          Positioned(
            left: _lensPos.dx - 60.r,
            top: _lensPos.dy - 60.r,
            child: GestureDetector(
              onPanUpdate: (details) => _onLensMove(_lensPos + details.delta),
              child: Container(
                width: 120.r, height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      child: Center(child: Icon(Icons.center_focus_strong_rounded, color: color.withValues(alpha: 0.4), size: 32.r)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

