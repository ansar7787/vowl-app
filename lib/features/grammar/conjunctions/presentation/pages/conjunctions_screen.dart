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

class ConjunctionsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConjunctionsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conjunctions,
  });

  @override
  State<ConjunctionsScreen> createState() => _ConjunctionsScreenState();
}

class _ConjunctionsScreenState extends State<ConjunctionsScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _placedBrick;
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

  void _onBridge(String conj, int correctIndex, List<String> options) {
    if (_isAnswered) return;
    
    bool isCorrect = conj == options[correctIndex];

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _placedBrick = conj; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _placedBrick = conj;
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
              _placedBrick = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNAPSE!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["AND", "BUT", "OR"];
        final question = quest?.question ?? "I like apples... I like oranges.";
        final parts = question.split("...");
        
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
              _buildIslands(parts, theme.primaryColor, isDark, quest.correctAnswerIndex ?? 0, options),
              const Spacer(),
              _buildBrickSheet(options, theme.primaryColor, isDark),
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
          Icon(Icons.architecture_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("DRAG THE CONJUNCTION BRICK TO LINK ISLANDS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildIslands(List<String> parts, Color primaryColor, bool isDark, int correctIndex, List<String> options) {
    return Column(
      children: [
        _buildIslandPiece(parts.first, isDark),
        SizedBox(height: 20.h),
        DragTarget<String>(
          onAcceptWithDetails: (details) => _onBridge(details.data, correctIndex, options),
          builder: (context, candidateData, rejectedData) {
            final isHighlight = candidateData.isNotEmpty;
            return Container(
              width: 150.w, height: 60.h,
              decoration: BoxDecoration(
                color: _placedBrick != null ? (_isCorrect == true ? Colors.greenAccent : Colors.redAccent) : (isHighlight ? primaryColor.withValues(alpha: 0.2) : Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3), style: _placedBrick != null ? BorderStyle.none : BorderStyle.solid, width: 2),
              ),
              child: Center(
                child: _placedBrick != null 
                  ? Text(_placedBrick!.toUpperCase(), style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white))
                  : (isHighlight ? Icon(Icons.download_rounded, color: primaryColor, size: 24.r) : null),
              ),
            );
          },
        ),
        SizedBox(height: 20.h),
        if (parts.length > 1) _buildIslandPiece(parts.last, isDark),
      ],
    );
  }

  Widget _buildIslandPiece(String text, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      borderRadius: BorderRadius.circular(20.r),
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildBrickSheet(List<String> options, Color primaryColor, bool isDark) {
    return Wrap(
      spacing: 16.w,
      runSpacing: 16.h,
      alignment: WrapAlignment.center,
      children: options.map((opt) => _buildBrick(opt, primaryColor, isDark)).toList(),
    );
  }

  Widget _buildBrick(String text, Color primaryColor, bool isDark) {
    final isPlaced = _placedBrick == text;
    return Draggable<String>(
      data: text,
      feedback: _buildTactileBrick(text, primaryColor, isDark, isDragging: true),
      childWhenDragging: Opacity(opacity: 0.2, child: _buildTactileBrick(text, primaryColor, isDark)),
      child: isPlaced ? const SizedBox(width: 80, height: 50) : _buildTactileBrick(text, primaryColor, isDark),
    );
  }

  Widget _buildTactileBrick(String text, Color primaryColor, bool isDark, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: isDragging ? 15 : 5, offset: isDragging ? const Offset(5, 5) : const Offset(2, 2)),
          ],
          border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Text(text.toUpperCase(), style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: primaryColor)),
      ),
    );
  }
}

