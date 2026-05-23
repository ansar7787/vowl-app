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
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

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
  int _timerValue = 12;
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
    if (_isAnswered || _isRevealed) return;
    setState(() {
      _pulseScale = 1.4;
      _clarityRadius = 1.0;
      _hapticService.selection();
    });
    
    Future.delayed(150.milliseconds, () {
      if (mounted) {
        setState(() => _pulseScale = 1.0);
      }
    });
    Future.delayed(2.seconds, () {
      if (mounted && !_isAnswered && !_isRevealed) {
        setState(() => _clarityRadius = 0.0);
      }
    });
  }

  void _startTimer(int initialValue) {
    _timer?.cancel();
    setState(() {
      _timerValue = initialValue;
      _isRevealed = false;
      _clarityRadius = 0.0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerValue > 0) {
        setState(() => _timerValue--);
      } else {
        setState(() {
          _isRevealed = true;
          _clarityRadius = 0.0;
        });
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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _isRevealed = false;
              _clarityRadius = 0.0;
            });
            _startTimer(state.currentQuest.timeLimit ?? 12);
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
                  
                  if (!_isRevealed) 
                    _buildPulseZone(quest.passage ?? "", theme.primaryColor, isDark)
                  else ...[
                    _buildQuestionArea(quest.question ?? "", theme.primaryColor, isDark),
                    SizedBox(height: 32.h),
                    ...List.generate(quest.options?.length ?? 0, (index) => _buildOption(index, quest.options![index], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
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
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(_isRevealed ? "ANALYZE THE COMPREHENSION QUEST" : "TAP THE GLOWING SONIC CORE TO BRIEFLY UNBLUR TEXT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPulseZone(String passage, Color color, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // The Passage (Hidden unless pulsed)
            AnimatedOpacity(
              duration: 400.milliseconds,
              opacity: _clarityRadius,
              child: GlassTile(
                padding: EdgeInsets.all(28.r), borderRadius: BorderRadius.circular(24.r),
                color: color.withValues(alpha: isDark ? 0.05 : 0.08),
                child: Text(
                  passage, 
                  textAlign: TextAlign.center, 
                  style: GoogleFonts.fredoka(
                    fontSize: 16.sp, 
                    height: 1.4,
                    color: isDark ? Colors.white : Colors.black87, 
                    fontWeight: FontWeight.w500
                  )
                ),
              ),
            ),
            
            // The Core Button
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
                        width: 130.r, height: 130.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                          border: Border.all(color: color, width: 4),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10)
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "${_timerValue}S", 
                            style: GoogleFonts.shareTechMono(
                              color: isDark ? Colors.white : color, 
                              fontSize: 26.sp, 
                              fontWeight: FontWeight.bold
                            )
                          )
                        ),
                      ),
                    );
                  },
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24),
              ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          "STABILIZE THE RHYTHM TO SPEED READ", 
          style: GoogleFonts.outfit(
            fontSize: 12.sp, 
            color: color.withValues(alpha: 0.6), 
            fontWeight: FontWeight.w600,
            letterSpacing: 1
          )
        ),
      ],
    );
  }

  Widget _buildQuestionArea(String question, Color color, bool isDark) {
    return Column(
      children: [
        Icon(Icons.query_stats_rounded, color: color, size: 48.r),
        SizedBox(height: 16.h),
        Text(
          question, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.outfit(
            fontSize: 22.sp, 
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white : Colors.black87
          )
        ),
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
          color: isCorrect 
              ? Colors.greenAccent.withValues(alpha: 0.25) 
              : (isWrong 
                  ? Colors.redAccent.withValues(alpha: 0.25) 
                  : (isSelected ? color.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)))),
          child: Center(
            child: Text(
              text, 
              style: GoogleFonts.outfit(
                fontSize: 15.sp, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : Colors.black87
              )
            )
          ),
        ),
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
