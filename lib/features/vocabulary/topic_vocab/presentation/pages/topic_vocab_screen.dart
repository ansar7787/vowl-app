import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopicVocabScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TopicVocabScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.topicVocab,
  });

  @override
  State<TopicVocabScreen> createState() => _TopicVocabScreenState();
}

class _TopicVocabScreenState extends State<TopicVocabScreen> {
  final _hapticService = di.sl<HapticService>();
  
  int _currentWordIndex = 0;
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

  void _onFlick(Offset velocity, String word, List<String> buckets, String correctAnswer) {
    if (_isAnswered) return;
    
    // Determine which bin the word was flicked towards based on velocity direction
    int targetBin = velocity.dx < 0 ? 0 : 1; 
    String bucket = buckets[targetBin % buckets.length];
    
    // Validation logic (simplified for the interaction)
    bool isCorrect = _validateFlick(word, bucket, correctAnswer);
    
    if (isCorrect) {
      _hapticService.success();
      setState(() {
        _currentWordIndex++;
        if (_currentWordIndex >= 5) { // Assuming 5 words per sort task
          _isAnswered = true;
          _isCorrect = true;
          context.read<VocabularyBloc>().add(SubmitAnswer(true));
        }
      });
    } else {
      _hapticService.error();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      });
    }
  }

  bool _validateFlick(String word, String bucket, String correctAnswer) {
     // Check if word belongs to bucket in the correctAnswer string mapping
     return correctAnswer.contains("$bucket:$word") || correctAnswer.contains("$bucket: $word") || 
            correctAnswer.contains(word) && correctAnswer.contains(bucket);
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
              _currentWordIndex = 0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TOPIC NEXUS!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final words = quest?.options ?? [];
        final buckets = quest?.topicBuckets ?? ["A", "B"];
        final currentWord = _currentWordIndex < words.length ? words[_currentWordIndex] : "";

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              Positioned(top: 100.h, child: _buildEmissionPort(theme.primaryColor)),
              ...List.generate(buckets.length, (i) => _buildContainmentBin(i, buckets[i], theme.primaryColor, isDark)),
              if (!_isAnswered) _buildFlickableWord(currentWord, (v) => _onFlick(v, currentWord, buckets, quest.correctAnswer ?? ""), theme.primaryColor, isDark),
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
      child: Text("FLICK WORDS INTO THE CORRECT BINS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
    );
  }

  Widget _buildEmissionPort(Color color) {
    return Container(
      width: 120.w, height: 40.h,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)), border: Border.all(color: color, width: 2)),
      child: Center(child: Icon(Icons.settings_suggest_rounded, color: color, size: 20.r)),
    ).animate(onPlay: (c) => c.repeat()).shimmer();
  }

  Widget _buildContainmentBin(int index, String name, Color color, bool isDark) {
    return Positioned(
      bottom: 100.h,
      left: index == 0 ? 40.w : null,
      right: index == 1 ? 40.w : null,
      child: Column(
        children: [
          Container(
            width: 120.r, height: 120.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30)],
            ),
            child: Center(child: Icon(Icons.hub_rounded, color: color, size: 40.r)),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
          SizedBox(height: 12.h),
          Text(name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildFlickableWord(String word, Function(Offset) onFlick, Color color, bool isDark) {
    return Positioned(
      top: 150.h,
      child: GestureDetector(
        onPanEnd: (details) => onFlick(details.velocity.pixelsPerSecond),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Text(word.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 16.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
      ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: 400.h, duration: 4.seconds, curve: Curves.linear),
    );
  }
}
