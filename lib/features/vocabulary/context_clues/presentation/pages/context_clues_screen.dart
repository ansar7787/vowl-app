import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ContextCluesScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextCluesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextClues,
  });

  @override
  State<ContextCluesScreen> createState() => _ContextCluesScreenState();
}

class _ContextCluesScreenState extends State<ContextCluesScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _lensPosition = const Offset(150, 100);
  final Set<int> _foundClues = {};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onLensMove(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _lensPosition += details.delta;
      _checkClues();
    });
  }

  void _checkClues() {
    // Simplified clue detection logic based on lens position
    // In a real app, we would map the lens position to word spans
    if (_lensPosition.dx > 100 && _lensPosition.dx < 200) {
      if (!_foundClues.contains(1)) {
        _hapticService.success();
        setState(() => _foundClues.add(1));
      }
    }
  }

  void _submitAnswer(int index, String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final livesChanged = state.livesRemaining > (_lastLives ?? 3);
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _foundClues.clear();
              _lensPosition = const Offset(150, 100);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LEXICAL DETECTIVE!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInvestigationStatus(theme.primaryColor),
              Expanded(
                child: Stack(
                  children: [
                    _buildNoirPassage(quest.sentence ?? "", theme.primaryColor, isDark),
                    if (!_isAnswered) _buildDetectiveLens(theme.primaryColor),
                  ],
                ),
              ),
              if (_foundClues.isNotEmpty || _isAnswered)
                _buildEvidenceOptions(options, quest.correctAnswer ?? "", theme.primaryColor, isDark),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvestigationStatus(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 14.r, color: color),
          SizedBox(width: 8.w),
          Text("SCAN FOR SEMANTIC CLUES", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildNoirPassage(String text, Color color, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.specialElite(fontSize: 22.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildDetectiveLens(Color color) {
    return Positioned(
      left: _lensPosition.dx - 75.r, top: _lensPosition.dy - 75.r,
      child: GestureDetector(
        onPanUpdate: _onLensMove,
        child: Container(
          width: 150.r, height: 150.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30)],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                decoration: BoxDecoration(color: color.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: Center(child: Icon(Icons.center_focus_strong_rounded, color: color.withValues(alpha: 0.5), size: 40.r)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceOptions(List<String> options, String correct, Color color, bool isDark) {
    return Column(
      children: [
        Text("SELECT THE DEFINITION", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w, runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: options.map((o) => ScaleButton(
            onTap: () => _submitAnswer(options.indexOf(o), o, correct),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _isAnswered && o == correct ? Colors.greenAccent.withValues(alpha: 0.2) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: _isAnswered && o == correct ? Colors.greenAccent : color.withValues(alpha: 0.2)),
              ),
              child: Text(o, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ),
          )).toList(),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }
}

