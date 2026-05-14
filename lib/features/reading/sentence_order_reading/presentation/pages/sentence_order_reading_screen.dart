import 'dart:ui';
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

class SentenceOrderReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceOrderReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceOrderReading,
  });

  @override
  State<SentenceOrderReadingScreen> createState() => _SentenceOrderReadingScreenState();
}

class _SentenceOrderReadingScreenState extends State<SentenceOrderReadingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  List<String> _currentOrder = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isAnswered) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
      _hapticService.selection();
    });
  }

  void _submitAnswer(List<int> correctOrder, List<String> original) {
    if (_isAnswered) return;
    
    bool isCorrect = true;
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i] != original[correctOrder[i]]) {
        isCorrect = false;
        break;
      }
    }

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
              _currentOrder = List<String>.from(state.currentQuest.shuffledSentences ?? []);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LOGIC FLOW EXPERT!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              Expanded(
                child: ReorderableListView(
                  physics: const BouncingScrollPhysics(),
                  proxyDecorator: (child, index, animation) => _buildProxy(child, animation, theme.primaryColor),
                  onReorder: _onReorder,
                  children: List.generate(_currentOrder.length, (index) => _buildStoneSlab(_currentOrder[index], index, theme.primaryColor, isDark)),
                ),
              ),
              if (!_isAnswered)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: _buildCapstone(quest.correctOrder ?? [], quest.shuffledSentences ?? [], theme.primaryColor),
                ),
              SizedBox(height: 20.h),
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
          Text("RESTORE THE LOGICAL STRUCTURE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStoneSlab(String text, int index, Color color, bool isDark) {
    return Container(
      key: ValueKey(text),
      margin: EdgeInsets.only(bottom: 12.h),
      child: GlassTile(
        padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(15.r),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white10, width: 2),
        child: Row(
          children: [
            Container(
              width: 32.r, height: 32.r,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2)),
              child: Center(child: Text("${index + 1}", style: GoogleFonts.shareTechMono(color: color, fontSize: 14.sp, fontWeight: FontWeight.bold))),
            ),
            SizedBox(width: 16.w),
            Expanded(child: Text(text, style: GoogleFonts.fredoka(fontSize: 15.sp, height: 1.4, color: Colors.white.withValues(alpha: 0.8)))),
            Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 24.r),
          ],
        ),
      ),
    );
  }

  Widget _buildProxy(Widget child, Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = lerpDouble(1, 1.05, animation.value)!;
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildCapstone(List<int> correct, List<String> original, Color color) {
    return ScaleButton(
      onTap: () {
        _hapticService.heavy();
        _submitAnswer(correct, original);
      },
      child: Container(
        width: double.infinity, height: 70.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_rounded, color: Colors.white, size: 24.r),
              SizedBox(width: 16.w),
              Text("LOCK CAPSTONE", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

