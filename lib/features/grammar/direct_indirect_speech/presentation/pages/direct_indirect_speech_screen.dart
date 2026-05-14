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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
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
        final rawQuestion = quest?.question ?? "DIRECT SPEECH";
        // Extract speech if it follows "Convert to reported speech: ..." or "Fix: ..."
        String displayDirect = quest?.sentence ?? "";
        if (displayDirect.isEmpty) {
          if (rawQuestion.contains(':')) {
            displayDirect = rawQuestion.split(':').last.replaceAll('"', '').trim();
          } else {
            displayDirect = rawQuestion;
          }
        }
        
        String displayIndirect = quest?.correctAnswer ?? "";
        if (displayIndirect.isEmpty && quest != null && quest.options != null && (quest.correctAnswerIndex ?? 0) < quest.options!.length) {
          displayIndirect = quest.options![quest.correctAnswerIndex!];
        }
        if (displayIndirect.isEmpty) displayIndirect = "INDIRECT SPEECH";

        final options = quest?.options ?? ["REF A", "REF B", "REF C"];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: The Holographic Mirror (The Diamond Standard)
              _build3DMirror(displayDirect, displayIndirect, theme.primaryColor, isDark),

              SizedBox(height: 50.h),
              
              // Reflection Options
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: List.generate(
                          options.length, 
                          (i) => _buildReflectionChip(options[i], i, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark)
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flip_to_back_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "CHOOSE THE CORRECT REFLECTION", 
            style: GoogleFonts.outfit(
              fontSize: 10.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor, 
              letterSpacing: 1.5
            )
          ),
        ],
      ),
    );
  }

  Widget _build3DMirror(String direct, String indirect, Color primaryColor, bool isDark) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: _rotation),
      duration: 1000.ms,
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        final isFront = value < 1.57;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(value),
          alignment: Alignment.center,
          child: Container(
            width: 320.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: (isFront ? primaryColor : Colors.greenAccent).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ],
            ),
            child: GlassTile(
              padding: EdgeInsets.all(32.r),
              borderRadius: BorderRadius.circular(32.r),
              color: (isFront ? primaryColor : Colors.greenAccent).withValues(alpha: 0.1),
              child: Transform(
                transform: Matrix4.identity()..rotateY(isFront ? 0 : 3.14),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: (isFront ? primaryColor : Colors.greenAccent).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        isFront ? "DIRECT SPEECH" : "REPORTED SPEECH", 
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp, 
                          fontWeight: FontWeight.w900, 
                          color: isFront ? primaryColor : Colors.greenAccent,
                          letterSpacing: 1.5
                        )
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      isFront ? direct : indirect, 
                      textAlign: TextAlign.center, 
                      style: GoogleFonts.fredoka(
                        fontSize: 22.sp, 
                        color: isDark ? Colors.white : Colors.black87, 
                        fontWeight: FontWeight.bold,
                        height: 1.4
                      )
                    ),
                  ],
                ),
              ),
            ),
          ).animate(key: ValueKey(isFront)).shimmer(duration: 2.seconds, color: Colors.white10),
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
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: GlassTile(
          padding: EdgeInsets.all(20.r),
          borderRadius: BorderRadius.circular(24.r),
          color: isCorrect 
              ? Colors.greenAccent.withValues(alpha: 0.2) 
              : (isWrong ? Colors.redAccent.withValues(alpha: 0.2) : (isSelected ? primaryColor.withValues(alpha: 0.2) : null)),
          border: Border.all(
            color: isCorrect 
                ? Colors.greenAccent 
                : (isWrong ? Colors.redAccent : (isSelected ? primaryColor : Colors.white.withValues(alpha: 0.1))),
            width: 2,
          ),
          child: Text(
            text, 
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15.sp, 
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, 
              color: isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isDark ? Colors.white : Colors.black87)),
              height: 1.4
            )
          ),
        ),
      ),
    );
  }
}

