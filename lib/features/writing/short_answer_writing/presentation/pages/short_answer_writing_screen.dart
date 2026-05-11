import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';

class ShortAnswerScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShortAnswerScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shortAnswerWriting,
  });

  @override
  State<ShortAnswerScreen> createState() => _ShortAnswerScreenState();
}

class _ShortAnswerScreenState extends State<ShortAnswerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _answerController = TextEditingController();
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int _attempts = 0;
  int? _lastLives;
  double _inkLevel = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
    _answerController.addListener(() {
      setState(() {
        _inkLevel = (_answerController.text.length / 50).clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (_isAnswered || _answerController.text.trim().isEmpty) return;
    
    final text = _answerController.text.trim();
    final isCorrect = text.length >= 15 && text.split(RegExp(r'\s+')).length >= 3;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _attempts++;
        if (_attempts >= 2) {
          _isAnswered = true; _isCorrect = false;
        }
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _answerController.clear();
              _attempts = 0;
              _inkLevel = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CREATIVE AUTHOR!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: _attempts >= 2,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () {},
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                _buildInstruction(theme.primaryColor),
                SizedBox(height: 32.h),
                _buildQuillPrompt(quest.prompt ?? "", theme.primaryColor, isDark),
                SizedBox(height: 40.h),
                _buildInkwell(theme.primaryColor, isDark),
                SizedBox(height: 48.h),
                if (!_isAnswered)
                  ScaleButton(
                    onTap: _submitAnswer,
                    child: Container(
                      width: double.infinity, height: 60.h,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: _inkLevel > 0.3 ? theme.primaryColor : Colors.grey, boxShadow: [if (_inkLevel > 0.3) BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)]),
                      child: Center(child: Text("SEAL WITH WAX", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                    ),
                  ),
                SizedBox(height: 20.h),
              ],
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
          Icon(Icons.history_edu_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("DRIP YOUR THOUGHTS INTO THE WELL", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildQuillPrompt(String prompt, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(28.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        image: DecorationImage(image: const NetworkImage('https://www.transparenttextures.com/patterns/pinstriped-suit.png'), opacity: 0.1, repeat: ImageRepeat.repeat),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_rounded, color: color, size: 32.r).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5),
          SizedBox(height: 16.h),
          Text(prompt, style: GoogleFonts.spectral(fontSize: 18.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87, height: 1.6), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInkwell(Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -10)],
      ),
      child: Column(
        children: [
          TextField(
            controller: _answerController,
            maxLines: 5,
            enabled: !_isAnswered,
            style: GoogleFonts.spectral(fontSize: 18.sp, color: color, height: 1.5),
            decoration: InputDecoration(
              hintText: "Let the ink flow...",
              hintStyle: GoogleFonts.spectral(color: color.withValues(alpha: 0.2)),
              border: InputBorder.none,
            ),
          ),
          SizedBox(height: 20.h),
          Stack(
            children: [
              Container(width: double.infinity, height: 8.h, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4.r))),
              AnimatedContainer(
                duration: 500.milliseconds,
                width: MediaQuery.of(context).size.width * _inkLevel,
                height: 8.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(target: _inkLevel).shimmer(duration: 2.seconds);
  }
}

