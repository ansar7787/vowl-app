import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DirectIndirectSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DirectIndirectSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.directIndirectSpeech,
  });

  @override
  State<DirectIndirectSpeechScreen> createState() => _DirectIndirectSpeechScreenState();
}

class _DirectIndirectSpeechScreenState extends State<DirectIndirectSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _rotation = 0.0;
  int _selectedReflection = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onReflectionSelect(int index, int correctIndex) {
    if (_isAnswered) return;
    setState(() => _selectedReflection = index);
    
    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _rotation = 3.14; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _rotation = 0.0;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedReflection = -1;
              _rotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SHADOW MASTER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["REF A", "REF B", "REF C"];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 48.h),
              _build3DMirror(quest.sentence ?? "DIRECT SPEECH", quest.correctAnswer ?? "INDIRECT SPEECH", theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              Text("SELECT THE CORRECT REFLECTION", style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)),
              SizedBox(height: 24.h),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.w,
                runSpacing: 16.h,
                children: List.generate(options.length, (i) => _buildReflectionChip(options[i], i, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark)),
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
          Icon(Icons.flip_to_back_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CHOOSE REFLECTION AND FLIP MIRROR", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _build3DMirror(String direct, String indirect, Color primaryColor, bool isDark) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: _rotation),
      duration: 800.ms,
      builder: (context, double value, child) {
        final isFront = value < 1.57;
        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(value),
          alignment: Alignment.center,
          child: GlassTile(
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(24.r),
            color: (isFront ? primaryColor : Colors.greenAccent).withValues(alpha: 0.1),
            child: Transform(
              transform: Matrix4.identity()..rotateY(isFront ? 0 : 3.14),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(isFront ? "DIRECT" : "REFLECTED", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: isFront ? primaryColor : Colors.greenAccent)),
                  SizedBox(height: 12.h),
                  Text(isFront ? direct : indirect, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReflectionChip(String text, int index, int correctIndex, Color primaryColor, bool isDark) {
    final isSelected = _selectedReflection == index;
    final isCorrect = _isAnswered && index == correctIndex;
    final isWrong = _isAnswered && isSelected && index != correctIndex;

    return ScaleButton(
      onTap: () => _onReflectionSelect(index, correctIndex),
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        borderRadius: BorderRadius.circular(16.r),
        color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.4) : (isWrong ? Colors.redAccent.withValues(alpha: 0.4) : (isSelected ? primaryColor.withValues(alpha: 0.2) : null)),
        child: Text(text, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: (isSelected || isCorrect || isWrong) ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
      ),
    );
  }
}

