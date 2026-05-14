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
        final options = allWords.skip(1).toList();
        
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
                  child: Text(
                    "Insert the modifier '$modifier' into the correct position.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 18.sp, 
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              Expanded(
                child: _buildMagneticArena(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              ),

              if (!_isAnswered)
                _buildValidatorMagnet(theme.primaryColor),
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
          Icon(Icons.adjust_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "PICK THE CORRECT CORE", 
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

  Widget _buildValidatorMagnet(Color primaryColor) {
    return Draggable<bool>(
      data: true,
      feedback: _buildMagnetCore(primaryColor, isDragging: true),
      childWhenDragging: Opacity(opacity: 0.2, child: _buildMagnetCore(primaryColor)),
      child: _buildMagnetCore(primaryColor),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMagnetCore(Color primaryColor, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: isDragging ? 30 : 15, spreadRadius: isDragging ? 5 : 0)
          ],
        ),
        child: Icon(Icons.flash_on_rounded, color: Colors.white, size: 28.r),
      ),
    );
  }

  Widget _buildMagneticArena(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return Stack(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;
        return _SentenceCore(
          text: text,
          index: index,
          isAnswered: _isAnswered,
          isTarget: _targetIndex == index,
          isCorrect: _isCorrect,
          primaryColor: primaryColor,
          isDark: isDark,
          onDrop: () => _onDrop(index, options[correctIndex], options),
        );
      }).toList(),
    );
  }
}

class _SentenceCore extends StatelessWidget {
  final String text;
  final int index;
  final bool isAnswered;
  final bool isTarget;
  final bool? isCorrect;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onDrop;

  const _SentenceCore({
    required this.text, 
    required this.index, 
    required this.isAnswered, 
    required this.isTarget, 
    this.isCorrect, 
    required this.primaryColor, 
    required this.isDark,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final top = 20.h + (index * 85.h);
    final left = (index % 2 == 0) ? 20.w : 60.w;

    return AnimatedPositioned(
      duration: 600.ms,
      curve: Curves.easeOutBack,
      top: isTarget ? 150.h : top,
      left: isTarget ? 20.w : left,
      right: isTarget ? 20.w : 20.w,
      child: DragTarget<bool>(
        onWillAcceptWithDetails: (_) => !isAnswered,
        onAcceptWithDetails: (_) => onDrop(),
        builder: (context, candidateData, rejectedData) {
          final isHighlight = candidateData.isNotEmpty;
          final coreColor = isTarget 
              ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
              : (isHighlight ? primaryColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)));

          return Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: coreColor.withValues(alpha: isTarget ? 0.2 : 0.05),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: coreColor.withValues(alpha: isHighlight || isTarget ? 0.6 : 0.15), 
                width: isHighlight || isTarget ? 2.5 : 1.5
              ),
              boxShadow: [
                if (isHighlight || isTarget)
                  BoxShadow(color: coreColor.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 2)
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 16.sp,
                fontWeight: isTarget ? FontWeight.w700 : FontWeight.w500,
                color: isTarget ? coreColor : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ).animate(target: isHighlight ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
        },
      ),
    );
  }
}

