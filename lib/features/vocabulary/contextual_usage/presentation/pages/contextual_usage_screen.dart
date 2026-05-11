import 'dart:math' as math;
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

class ContextualUsageScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextualUsageScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextualUsage,
  });

  @override
  State<ContextualUsageScreen> createState() => _ContextualUsageScreenState();
}

class _ContextualUsageScreenState extends State<ContextualUsageScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _viewfinderPos = Offset.zero;
  int? _focusedIndex;
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

  void _onPan(DragUpdateDetails details, List<String> options) {
    if (_isAnswered) return;
    setState(() {
      _viewfinderPos += details.delta;
      
      // Focus detection
      _focusedIndex = null;
      for (int i = 0; i < options.length; i++) {
        double angle = (i * (2 * math.pi / options.length));
        double radius = 180.r;
        Offset subjectPos = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        if ((_viewfinderPos + subjectPos).distance < 60.r) {
          _focusedIndex = i;
          break;
        }
      }
    });
    if (_focusedIndex != null) _hapticService.selection();
  }

  void _onSnap(int correctIndex) {
    if (_isAnswered || _focusedIndex == null) return;
    
    _hapticService.success();
    bool isCorrect = _focusedIndex == correctIndex;
    
    if (isCorrect) {
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
              _viewfinderPos = Offset.zero;
              _focusedIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'USAGE EXPERT!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];
        final sentence = quest?.question ?? "???";

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildSentenceBoard(sentence, theme.primaryColor, isDark),
              _buildViewfinderScene(options, theme.primaryColor, isDark),
              if (!_isAnswered) _buildShutterButton(() => _onSnap(quest.correctAnswerIndex ?? 0), theme.primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 20.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("PAN AND SNAP THE CORRECT SUBJECT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSentenceBoard(String sentence, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Container(
        width: 0.8.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(sentence, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, height: 1.5)),
      ),
    );
  }

  Widget _buildViewfinderScene(List<String> options, Color color, bool isDark) {
    return GestureDetector(
      onPanUpdate: (d) => _onPan(d, options),
      child: Container(
        width: 1.sw, height: 0.5.sh,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Word Subjects
            ...List.generate(options.length, (i) => _buildWordSubject(i, options.length, options[i], color)),
            
            // Viewfinder Grid
            _buildGridOverlay(color),
            
            // Focus Ring
            _buildFocusRing(color),
          ],
        ),
      ),
    );
  }

  Widget _buildWordSubject(int index, int total, String text, Color color) {
    double angle = (index * (2 * math.pi / total));
    double radius = 180.r;
    double x = math.cos(angle) * radius + _viewfinderPos.dx;
    double y = math.sin(angle) * radius + _viewfinderPos.dy;

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: color, width: 2)),
        child: Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFocusRing(Color color) {
    bool isFocused = _focusedIndex != null;
    return Container(
      width: 100.r, height: 100.r,
      decoration: BoxDecoration(
        border: Border.all(color: isFocused ? Colors.greenAccent : color, width: 2),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(border: Border(top: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4), left: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4))))),
          Positioned(top: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(border: Border(top: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4), right: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4))))),
          Positioned(bottom: 0, left: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4), left: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4))))),
          Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4), right: BorderSide(color: isFocused ? Colors.greenAccent : color, width: 4))))),
        ],
      ),
    ).animate(target: isFocused ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 100.ms);
  }

  Widget _buildGridOverlay(Color color) {
    return IgnorePointer(
      child: Stack(
        children: [
          Center(child: SizedBox(width: 1, height: 200, child: ColoredBox(color: color.withValues(alpha: 0.1)))),
          Center(child: SizedBox(width: 200, height: 1, child: ColoredBox(color: color.withValues(alpha: 0.1)))),
        ],
      ),
    );
  }

  Widget _buildShutterButton(VoidCallback onSnap, Color color) {
    return Positioned(
      bottom: 40.h,
      child: GestureDetector(
        onTap: onSnap,
        child: Container(
          width: 80.r, height: 80.r,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 4), color: Colors.white.withValues(alpha: 0.1)),
          child: Center(child: Container(width: 60.r, height: 60.r, decoration: BoxDecoration(shape: BoxShape.circle, color: color))),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 1.seconds);
  }
}

