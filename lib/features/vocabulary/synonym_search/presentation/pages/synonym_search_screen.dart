import 'dart:math';
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

class SynonymSearchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SynonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.synonymSearch,
  });

  @override
  State<SynonymSearchScreen> createState() => _SynonymSearchScreenState();
}

class _SynonymSearchScreenState extends State<SynonymSearchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<Offset> _bombPositions = [];
  final List<double> _bombAngles = [];
  final Set<int> _detonatedIndices = {};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
    _initBombs();
  }

  void _initBombs() {
    final rand = Random();
    _bombPositions.clear();
    _bombAngles.clear();
    _detonatedIndices.clear();
    for (int i = 0; i < 6; i++) {
      _bombPositions.add(Offset(rand.nextDouble() * 300 - 150, rand.nextDouble() * 400 - 200));
      _bombAngles.add(rand.nextDouble() * pi * 2);
    }
  }

  void _onDetonate(int index, String text, String correct) {
    if (_isAnswered || _detonatedIndices.contains(index)) return;
    
    bool isActuallyCorrect = text.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isActuallyCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _detonatedIndices.add(index);
        if (_detonatedIndices.isNotEmpty) { // Assuming 1 correct synonym for simplicity in this interaction
           _isAnswered = true;
           _isCorrect = true;
        }
      });
      if (_isAnswered) context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
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
              _initBombs();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNONYM SEEKER!', enableDoubleUp: true);
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
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildCoreProcessor(quest.word ?? "", theme.primaryColor),
              ...List.generate(options.length, (i) => _buildWordBomb(i, options[i], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
              Positioned(top: 20.h, child: _buildInstruction(theme.primaryColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 14.r, color: color),
          SizedBox(width: 8.w),
          Text("DETONATE THE SYNONYM BOMBS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildCoreProcessor(String word, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140.r, height: 140.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, border: Border.all(color: color, width: 4), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 40)]),
          child: Center(child: Text(word.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2))),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        SizedBox(height: 240.h), // Space for bombs
      ],
    );
  }

  Widget _buildWordBomb(int index, String text, String correct, Color color, bool isDark) {
    if (_detonatedIndices.contains(index)) {
      return const SizedBox().animate().custom(duration: 500.ms, builder: (context, value, child) => Opacity(opacity: 0, child: child));
    }

    final pos = _bombPositions[index];

    return Positioned(
      left: 200.w + pos.dx, top: 400.h + pos.dy,
      child: GestureDetector(
        onTap: () => _onDetonate(index, text, correct),
        child: Container(
          width: 100.r, height: 100.r,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.settings_input_component_rounded, color: color.withValues(alpha: 0.2), size: 60.r),
              Padding(
                padding: EdgeInsets.all(8.r),
                child: Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ),
              // Fuse
              Positioned(top: 0, child: Container(width: 4.w, height: 15.h, color: Colors.orange).animate(onPlay: (c) => c.repeat()).shimmer()),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shake(hz: 2, curve: Curves.easeInOut).moveY(begin: -5, end: 5, duration: 2.seconds),
      ),
    );
  }
}

