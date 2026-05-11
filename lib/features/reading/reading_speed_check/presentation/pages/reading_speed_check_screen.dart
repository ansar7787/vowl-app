import 'dart:async';
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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadingSpeedCheckScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingSpeedCheckScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingSpeedCheck,
  });

  @override
  State<ReadingSpeedCheckScreen> createState() => _ReadingSpeedCheckScreenState();
}

class _ReadingSpeedCheckScreenState extends State<ReadingSpeedCheckScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _pulseScale = 1.0;
  double _clarityRadius = 0.0;
  int _timerValue = 10;
  Timer? _timer;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPulseTap() {
    if (_isAnswered) return;
    setState(() {
      _pulseScale = 1.5;
      _clarityRadius = 1.0;
      _hapticService.selection();
    });
    
    Future.delayed(100.milliseconds, () => setState(() => _pulseScale = 1.0));
    Future.delayed(2.seconds, () => setState(() => _clarityRadius = 0.0));
  }

  void _startTimer(int initialValue) {
    _timer?.cancel();
    setState(() {
      _timerValue = initialValue;
      _isRevealed = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue > 0) {
        setState(() => _timerValue--);
      } else {
        setState(() => _isRevealed = true);
        timer.cancel();
      }
    });
  }

  void _onChoiceTap(int index, String selected, String correct) {
    if (_isAnswered || !_isRevealed) return;
    setState(() => _selectedIndex = index);

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
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              _selectedIndex = null;
            });
            _startTimer(state.currentQuest.timeLimit ?? 10);
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SPEED DEMON!', enableDoubleUp: true);
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
              SizedBox(height: 32.h),
              if (!_isRevealed) 
                _buildPulseZone(quest.passage ?? "", theme.primaryColor)
              else ...[
                _buildQuestionArea(quest.question ?? "", theme.primaryColor, isDark),
                SizedBox(height: 32.h),
                ...List.generate(quest.options?.length ?? 0, (index) => _buildOption(index, quest.options![index], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
              ],
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
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(_isRevealed ? "ANALYZE THE ECHO" : "TAP TO PULSE THE CORE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPulseZone(String passage, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // The Passage (Hidden)
            AnimatedOpacity(
              duration: 500.milliseconds,
              opacity: _clarityRadius,
              child: GlassTile(
                padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(30.r),
                color: color.withValues(alpha: 0.1),
                child: Text(passage, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ),
            
            // The Core
            if (_clarityRadius < 0.5)
              GestureDetector(
                onTap: _onPulseTap,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.0, end: _pulseScale),
                  duration: 100.milliseconds,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120.r, height: 120.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.2),
                          border: Border.all(color: color, width: 4),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 10)],
                        ),
                        child: Center(child: Text("${_timerValue}S", style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold))),
                      ),
                    );
                  },
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24),
              ),
          ],
        ),
        SizedBox(height: 24.h),
        Text("STABILIZE THE RHYTHM TO READ", style: GoogleFonts.outfit(fontSize: 12.sp, color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuestionArea(String question, Color color, bool isDark) {
    return Column(
      children: [
        Icon(Icons.query_stats_rounded, color: color, size: 48.r),
        SizedBox(height: 16.h),
        Text(question, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  Widget _buildOption(int index, String text, String correct, Color color, bool isDark) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = _isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    bool isWrong = _isAnswered && isSelected && !isCorrect;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: () => _onChoiceTap(index, text, correct),
        child: GlassTile(
          padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(20.r),
          color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.3) : (isWrong ? Colors.redAccent.withValues(alpha: 0.3) : (isSelected ? color.withValues(alpha: 0.2) : Colors.white10)),
          child: Center(child: Text(text, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
      ),
    );
  }
}

