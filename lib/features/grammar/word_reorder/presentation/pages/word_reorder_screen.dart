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

class WordReorderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordReorderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordReorder,
  });

  @override
  State<WordReorderScreen> createState() => _WordReorderScreenState();
}

class _WordReorderScreenState extends State<WordReorderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  List<String>? _availableWords;
  List<String> _assembledWords = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onWordTap(String word, String correctAnswer) {
    if (_isAnswered) return;
    
    final correctWords = correctAnswer.split(' ');
    final nextCorrectWord = correctWords[_assembledWords.length];

    if (word.toLowerCase() == nextCorrectWord.toLowerCase()) {
      _hapticService.selection();
      _soundService.playCorrect();
      setState(() {
        _assembledWords.add(word);
        _availableWords!.remove(word);
        
        if (_assembledWords.length == correctWords.length) {
          _submitAnswer(correctAnswer);
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      // Visual feedback handled by animation
    }
  }

  void _submitAnswer(String correctAnswer) {
    _hapticService.success();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<GrammarBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _availableWords = null;
              _assembledWords = [];
            });
          }
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SHARPSHOOTER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        if (quest != null && _availableWords == null) {
          _availableWords = List.from(quest.shuffledWords ?? []);
        }
        
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
              SizedBox(height: 32.h),
              _buildSentenceAssembly(theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              _buildGravityFallArea(quest.correctAnswer ?? "", theme.primaryColor, isDark),
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
          Icon(Icons.auto_fix_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CATCH WORDS IN ORDER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceAssembly(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 8.w, runSpacing: 8.h,
        alignment: WrapAlignment.center,
        children: _assembledWords.isEmpty 
          ? [Text("ASSEMBLING SENTENCE...", style: GoogleFonts.outfit(fontSize: 14.sp, color: primaryColor.withValues(alpha: 0.4), fontStyle: FontStyle.italic))]
          : _assembledWords.map((word) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: primaryColor.withValues(alpha: 0.3))),
              child: Text(word, style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w600, color: primaryColor)),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack)).toList(),
      ),
    );
  }

  Widget _buildGravityFallArea(String correctAnswer, Color primaryColor, bool isDark) {
    return SizedBox(
      height: 300.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: _availableWords!.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;
          return _FallingWord(
            word: word,
            index: index,
            onTap: () => _onWordTap(word, correctAnswer),
            primaryColor: primaryColor,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

class _FallingWord extends StatefulWidget {
  final String word;
  final int index;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  const _FallingWord({required this.word, required this.index, required this.onTap, required this.primaryColor, required this.isDark});

  @override
  State<_FallingWord> createState() => _FallingWordState();
}

class _FallingWordState extends State<_FallingWord> {
  late double _top;
  late double _left;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _top = -50.h;
    _left = (widget.index % 3) * 100.w + 20.w; // Simple distribution
    _startFalling();
  }

  void _startFalling() async {
    await Future.delayed(Duration(milliseconds: widget.index * 1500));
    if (mounted) {
      setState(() => _top = 300.h);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTapped) return const SizedBox();

    return AnimatedPositioned(
      duration: const Duration(seconds: 4),
      curve: Curves.linear,
      top: _top,
      left: _left,
      child: GestureDetector(
        onTap: () {
          setState(() => _isTapped = true);
          widget.onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: widget.primaryColor, width: 2),
            boxShadow: [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Text(widget.word, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w800, color: widget.isDark ? Colors.white : Colors.black87)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
      ),
    );
  }
}

