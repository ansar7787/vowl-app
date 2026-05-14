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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PunctuationMasteryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PunctuationMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.punctuationMastery,
  });

  @override
  State<PunctuationMasteryScreen> createState() => _PunctuationMasteryScreenState();
}

class _PunctuationMasteryScreenState extends State<PunctuationMasteryScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final Map<int, String> _placedStickers = {};
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

  void _onStick(int index, String mark) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _placedStickers[index] = mark);
  }

  void _submitAnswer(GameQuest quest) {
    if (_isAnswered) return;
    
    final words = (quest.sentence ?? "").split(" ");
    String result = "";
    for (int i = 0; i < words.length; i++) {
      result += words[i];
      if (_placedStickers.containsKey(i)) {
        result += _placedStickers[i]!;
      }
      if (i < words.length - 1) result += " ";
    }

    bool isCorrect = result.trim().toLowerCase() == (quest.correctAnswer ?? "").trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
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
              _placedStickers.clear();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'PUNCTUATION PRO!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final marks = [".", ",", "!", "?", ";", ":"];
        
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
              
              // Optimized: Concise Context Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: _buildStickerSentence(quest.sentence ?? "Missing sentence.", theme.primaryColor, isDark),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              SizedBox(height: 48.h),
              _buildStickerSheet(marks, theme.primaryColor),
              const Spacer(),
              if (!_isAnswered)
                _buildSubmitButton(theme.primaryColor, quest),
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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "APPLY HOLOGRAPHIC DECALS", 
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

  Widget _buildStickerSentence(String sentence, Color primaryColor, bool isDark) {
    final words = sentence.split(" ");
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4.w,
      runSpacing: 12.h,
      children: List.generate(words.length * 2, (index) {
        if (index % 2 == 0) {
          return Text(
            words[index ~/ 2], 
            style: GoogleFonts.fredoka(
              fontSize: 20.sp, 
              color: isDark ? Colors.white : Colors.black87
            )
          );
        } else {
          final slotIndex = index ~/ 2;
          return _buildStickerSlot(slotIndex, primaryColor);
        }
      }),
    );
  }

  Widget _buildStickerSlot(int index, Color primaryColor) {
    final mark = _placedStickers[index];
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _onStick(index, details.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        return Container(
          width: 34.r, height: 34.r,
          decoration: BoxDecoration(
            color: mark != null ? primaryColor : (isHighlight ? primaryColor.withValues(alpha: 0.3) : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighlight || mark != null ? primaryColor : primaryColor.withValues(alpha: 0.15), 
              width: isHighlight ? 2 : 1.5,
              style: mark != null ? BorderStyle.none : BorderStyle.solid
            ),
            boxShadow: [
              if (mark != null)
                BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)
            ],
          ),
          child: Center(
            child: mark != null 
              ? Text(
                  mark, 
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white
                  )
                ).animate().shimmer(duration: 2.seconds)
              : (isHighlight ? Icon(Icons.add, color: primaryColor, size: 18.r) : null),
          ),
        ).animate(target: mark != null ? 1 : 0).scale(duration: 300.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildStickerSheet(List<String> marks, Color primaryColor) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24.w,
      runSpacing: 24.h,
      children: marks.map((m) => _buildPunctuationSticker(m, primaryColor)).toList(),
    );
  }

  Widget _buildPunctuationSticker(String mark, Color primaryColor) {
    return Draggable<String>(
      data: mark,
      feedback: _buildTactileSticker(mark, primaryColor, isDragging: true),
      childWhenDragging: Opacity(opacity: 0.2, child: _buildTactileSticker(mark, primaryColor)),
      child: _buildTactileSticker(mark, primaryColor),
    );
  }

  Widget _buildTactileSticker(String mark, Color primaryColor, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 54.r, height: 54.r,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryColor.withValues(alpha: 0.1)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15), 
              blurRadius: isDragging ? 20 : 8, 
              offset: isDragging ? const Offset(0, 10) : const Offset(0, 4)
            ),
          ],
          border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 2),
        ),
        child: Center(
          child: Text(
            mark, 
            style: GoogleFonts.outfit(
              fontSize: 26.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor
            )
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.05, end: 0.05, duration: 2.seconds);
  }

  Widget _buildSubmitButton(Color primaryColor, GameQuest quest) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ScaleButton(
        onTap: () => _submitAnswer(quest),
        child: Container(
          width: double.infinity, height: 65.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
            boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 25, offset: const Offset(0, 12))],
          ),
          child: Center(
            child: Text(
              "FINALIZE ARCHITECTURE", 
              style: GoogleFonts.outfit(
                fontSize: 16.sp, 
                fontWeight: FontWeight.w900, 
                color: Colors.white, 
                letterSpacing: 2
              )
            )
          ),
        ),
      ),
    );
  }
}

