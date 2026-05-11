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

class PrefixSuffixScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrefixSuffixScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
  });

  @override
  State<PrefixSuffixScreen> createState() => _PrefixSuffixScreenState();
}

class _PrefixSuffixScreenState extends State<PrefixSuffixScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _dragOffset = Offset.zero;
  int? _activeBranchIndex;
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

  void _onBranchDrag(int index, DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _activeBranchIndex = index;
      _dragOffset += details.delta;
    });
  }

  void _onBranchRelease(String option, String target, String correct) {
    if (_isAnswered) return;
    
    // Check if close to center trunk
    if (_dragOffset.distance < 100) {
      _hapticService.success();
      _submitAffix(option, target, correct);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _activeBranchIndex = null;
      });
    }
  }

  void _submitAffix(String option, String target, String correct) {
    if (_isAnswered) return;
    bool isCorrect = option.trim().toLowerCase() == target.trim().toLowerCase();
    
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
              _activeBranchIndex = null;
              _dragOffset = Offset.zero;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'BOTANICAL ROOTS!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final root = quest?.rootWord ?? "???";
        final options = quest?.options ?? [];
        final target = quest?.prefix ?? quest?.suffix ?? "";

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildSemanticTrunk(root, theme.primaryColor, isDark),
              ...List.generate(options.length, (i) => _buildGraftableBranch(i, options[i], target, quest.correctAnswer ?? "", theme.primaryColor, isDark)),
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
        child: Text("GRAFT THE BRANCHES ONTO THE TRUNK", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSemanticTrunk(String root, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.spa_rounded, size: 80.r, color: Colors.greenAccent).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 2),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          child: Text(root.toUpperCase(), style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _buildGraftableBranch(int index, String text, String target, String correct, Color color, bool isDark) {
    bool isActive = _activeBranchIndex == index;
    // Circular positioning
    double angle = (index * (2 * math.pi / 6));
    double radius = 150.r;
    double x = math.cos(angle) * radius;
    double y = math.sin(angle) * radius;

    return Positioned(
      left: 150.w + x + (isActive ? _dragOffset.dx : 0),
      top: 300.h + y + (isActive ? _dragOffset.dy : 0),
      child: GestureDetector(
        onPanUpdate: (d) => _onBranchDrag(index, d),
        onPanEnd: (_) => _onBranchRelease(text, target, correct),
        child: AnimatedContainer(
          duration: isActive ? Duration.zero : 300.ms,
          curve: Curves.elasticOut,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)],
          ),
          child: Text(text.toUpperCase(), style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}
