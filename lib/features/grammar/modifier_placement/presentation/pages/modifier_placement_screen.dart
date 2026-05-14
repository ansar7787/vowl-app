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
import 'package:flutter_animate/flutter_animate.dart';

class ModifierPlacementScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModifierPlacementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modifierPlacement,
  });

  @override
  State<ModifierPlacementScreen> createState() => _ModifierPlacementScreenState();
}

class _ModifierPlacementScreenState extends State<ModifierPlacementScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _targetIndex = -1;
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

  void _onDrop(int index, String correctAnswer, List<String> allWords) {
    if (_isAnswered) return;

    final words = List<String>.from(allWords);
    final modifier = words.removeAt(0);
    words.insert(index, modifier);
    
    final result = words.join(' ');
    bool isCorrect = result.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _targetIndex = index; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _targetIndex = -1;
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
              _targetIndex = -1;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SHAPER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final allWords = quest?.shuffledWords ?? [];
        if (allWords.isEmpty) return const SizedBox();
        
        final modifier = allWords[0];
        final sentenceWords = allWords.skip(1).toList();
        
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
              _buildModifierMagnet(modifier, theme.primaryColor),
              SizedBox(height: 60.h),
              _buildMagneticSentence(sentenceWords, quest.correctAnswer ?? "", allWords, theme.primaryColor, isDark),
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
          Icon(Icons.adjust_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("DRAG MAGNET TO CORRECT POSITION", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildModifierMagnet(String modifier, Color primaryColor) {
    if (_isAnswered) return const SizedBox(height: 80);
    return Draggable<String>(
      data: modifier,
      feedback: _buildMagnetChip(modifier, primaryColor, isDragging: true),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildMagnetChip(modifier, primaryColor)),
      child: _buildMagnetChip(modifier, primaryColor),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMagnetChip(String text, Color primaryColor, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.5), blurRadius: isDragging ? 30 : 15, spreadRadius: isDragging ? 5 : 0)
          ],
        ),
        child: Text(text.toUpperCase(), style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildMagneticSentence(List<String> words, String correct, List<String> all, Color primaryColor, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(words.length * 2 + 1, (index) {
        if (index % 2 == 1) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(words[index ~/ 2], style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87)),
          );
        } else {
          final slotIndex = index ~/ 2;
          return _buildMagneticSlot(slotIndex, correct, all, primaryColor);
        }
      }),
    );
  }

  Widget _buildMagneticSlot(int index, String correct, List<String> all, Color primaryColor) {
    final isFilled = _isAnswered && _targetIndex == index;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        _hapticService.selection();
        return true;
      },
      onAcceptWithDetails: (details) => _onDrop(index, correct, all),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: isFilled ? null : 30.w,
          height: 40.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: isFilled ? primaryColor.withValues(alpha: 0.2) : (candidateData.isNotEmpty ? primaryColor.withValues(alpha: 0.4) : Colors.transparent),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: candidateData.isNotEmpty ? primaryColor : Colors.transparent, width: 2),
          ),
          child: isFilled 
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(all[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: primaryColor)),
              ).animate().shimmer()
            : (candidateData.isNotEmpty ? Icon(Icons.download_rounded, color: primaryColor, size: 16.r) : null),
        );
      },
    );
  }
}

