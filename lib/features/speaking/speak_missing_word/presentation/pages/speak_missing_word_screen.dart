import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SpeakMissingWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakMissingWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakMissingWord,
  });

  @override
  State<SpeakMissingWordScreen> createState() => _SpeakMissingWordScreenState();
}

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _selectedWord;
  double _pullForce = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPullStart(String word) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedWord = word;
      _isListening = true;
    });
  }

  void _onPullEnd() {
    if (_isAnswered) return;
    setState(() {
      _isListening = false;
    });
    if (_pullForce >= 1.0) {
      _submitAnswer(_selectedWord ?? "");
    } else {
      setState(() {
        _pullForce = 0.0;
        _selectedWord = null;
      });
    }
  }

  void _submitAnswer(String word) {
    // Usually state has the correct word, for now we simulate success
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<SpeakingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    if (_isListening && _pullForce < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _pullForce += 0.02;
            _hapticService.selection();
          });
        }
      });
    }

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _pullForce = 0.0;
              _selectedWord = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'GAP VERBALIZER!', enableDoubleUp: true);
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["WORD A", "WORD B", "WORD C"];
        
        return SpeakingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 48.h),
              _buildVortexSentence(quest.textToSpeak ?? "The ... is bright.", theme.primaryColor, isDark),
              Expanded(
                child: _buildMagnetArena(options, theme.primaryColor, isDark),
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
          Icon(Icons.auto_awesome_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("PULL THE CORRECT WORD INTO THE VORTEX", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildVortexSentence(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h), borderRadius: BorderRadius.circular(24.r),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, color: isDark ? Colors.white70 : Colors.black87)),
          if (_isAnswered && _isCorrect == true)
            Center(child: Text(_selectedWord?.toUpperCase() ?? "", style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.greenAccent))),
        ],
      ),
    );
  }

  Widget _buildMagnetArena(List<String> options, Color primaryColor, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Vortex
          Container(
            width: 120.r, height: 120.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
          
          // Floating Words
          ...options.asMap().entries.map((e) {
            final index = e.key;
            final word = e.value;
            final angle = (index * (3.14 * 2) / options.length);
            final isBeingPulled = _selectedWord == word;
            
            return _buildFloatingWord(word, angle, isBeingPulled, primaryColor, isDark);
          }),
        ],
      );
    });
  }

  Widget _buildFloatingWord(String word, double angle, bool isBeingPulled, Color primaryColor, bool isDark) {
    final offsetProgress = isBeingPulled ? (1.0 - _pullForce) : 1.0;
    final dist = 120.w * offsetProgress;
    
    return Transform.translate(
      offset: Offset(cos(angle) * dist, sin(angle) * dist),
      child: GestureDetector(
        onLongPressStart: (_) => _onPullStart(word),
        onLongPressEnd: (_) => _onPullEnd(),
        child: ScaleButton(
          onTap: () {},
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            borderRadius: BorderRadius.circular(12.r),
            color: isBeingPulled ? primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            borderColor: isBeingPulled ? primaryColor : Colors.white10,
            child: Text(word.toUpperCase(), style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds);
  }
}
