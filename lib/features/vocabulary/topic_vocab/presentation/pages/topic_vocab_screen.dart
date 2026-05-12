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
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

// Extracted Optimized Widgets
import '../widgets/topic_machine_head.dart';
import '../widgets/topic_containment_bin.dart';
import '../widgets/topic_batch_counter.dart';
import '../widgets/topic_draggable_core.dart';

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
  final _soundService = di.sl<SoundService>();

  int _currentWordIndex = 0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _lastProcessedIndex = -1;
  bool _isHintActive = false;
  VocabularyQuest? _lastQuest;

  // Track the user's choices for the batch check
  final List<Map<String, String>> _userChoices = [];

  // Track which words are currently "stored" in each bin for visualization
  final Map<int, List<String>> _wordsInBins = {0: [], 1: []};

  // Track the current flicking word for animation
  String? _flickedWord;
  int? _flickTarget;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _handleFlick(double velocity, String word, List<String> buckets, String correctAnswer) {
    if (_isAnswered || _flickedWord != null) return;

    setState(() {
      int targetBin = velocity < 0 ? 0 : 1;
      String bucketName = buckets[targetBin % buckets.length];

      _flickedWord = word;
      _flickTarget = targetBin;
      
      final bloc = context.read<VocabularyBloc>();
      // Delay the actual state update to allow animation to play
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!context.mounted) return;
        setState(() {
          _userChoices.add({'word': word, 'bucket': bucketName});
          _wordsInBins[targetBin]?.add(word);
          _flickedWord = null;
          _flickTarget = null;
          _isHintActive = false; 

          if (_currentWordIndex < (wordsPerQuest(buckets) - 1)) {
            _currentWordIndex++;
          } else {
            _performBatchCheck(correctAnswer, bloc);
          }
        });
      });
    });
  }

  int wordsPerQuest(List<String> buckets) => (buckets.length * 2 + 1).clamp(3, 5);

  void _performBatchCheck(String correctAnswer, VocabularyBloc bloc) {
    bool allCorrect = true;
    for (var choice in _userChoices) {
      if (!_validateChoice(choice['word']!, choice['bucket']!, correctAnswer)) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        bloc.add(SubmitAnswer(true));
      });
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        bloc.add(SubmitAnswer(false));
      });
    }
  }

  bool _validateChoice(String word, String bucket, String correctAnswer) {
    final cleanWord = word.trim().toLowerCase();
    final cleanLabel = bucket.trim().toLowerCase();
    
    final target1 = "$cleanLabel:$cleanWord";
    final target2 = "$cleanLabel: $cleanWord";
    final lowerAnswer = correctAnswer.toLowerCase();
    
    return lowerAnswer.contains(target1) || lowerAnswer.contains(target2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(widget.gameType.name, isDark: isDark);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = state.lastAnswerCorrect == null && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _currentWordIndex = 0;
              _isHintActive = false;
              _userChoices.clear();
              _wordsInBins.forEach((_, list) => list.clear());
            });
          }
        }
        if (state is VocabularyGameComplete) {
          final xp = state.xpEarned;
          final coins = state.coinsEarned;
          setState(() => _showConfetti = true);
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: xp,
            coins: coins,
            title: 'TOPIC NEXUS!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();

        final options = quest?.options ?? [];
        final buckets = quest?.topicBuckets ?? ["A", "B"];
        final currentWord = _currentWordIndex < options.length ? options[_currentWordIndex] : "";
        final correctAnswer = quest?.correctAnswer ?? "";
        
        String displayInstruction = quest?.instruction ?? "";
        if (displayInstruction.toLowerCase().contains("choose the correct answer")) {
          displayInstruction = "SORT THE WORDS INTO BINS";
        }

        return VocabularyBaseLayout(
          gameType: widget.gameType, 
          level: widget.level, 
          isAnswered: _isAnswered, 
          isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            setState(() => _isHintActive = true);
          },
          child: Container(
            height: 0.75.sh, 
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. BATCH PROGRESS
                Positioned(
                  top: 0,
                  child: RepaintBoundary(
                    child: TopicBatchCounter(
                      count: _userChoices.length, 
                      total: options.length, 
                      color: theme.primaryColor
                    ),
                  ),
                ),

                // 2. INSTRUCTION
                Positioned(
                  top: 60.h, 
                  child: _buildInstruction(displayInstruction, theme.primaryColor)
                ),

                // 3. EMISSION MACHINE
                Positioned(
                  top: 180.h,
                  child: RepaintBoundary(
                    child: TopicMachineHead(primaryColor: theme.primaryColor, emoji: quest?.topicEmoji ?? "📦"),
                  ),
                ),

                // Containment Bins
                Positioned(
                  bottom: 20.h,
                  left: 0,
                  child: RepaintBoundary(
                    child: TopicContainmentBin(
                      index: 0, label: buckets[0], color: theme.primaryColor, isDark: isDark, 
                      correctAnswer: correctAnswer, currentWord: currentWord, 
                      words: _wordsInBins[0] ?? [], isHintActive: _isHintActive,
                    ),
                  ),
                ),
                if (buckets.length > 1)
                  Positioned(
                    bottom: 20.h,
                    right: 0,
                    child: RepaintBoundary(
                      child: TopicContainmentBin(
                        index: 1, label: buckets[1], color: theme.primaryColor, isDark: isDark, 
                        correctAnswer: correctAnswer, currentWord: currentWord, 
                        words: _wordsInBins[1] ?? [], isHintActive: _isHintActive,
                      ),
                    ),
                  ),
                
                // Draggable Word Core
                if (!_isAnswered && currentWord.isNotEmpty && _flickedWord == null) 
                  Positioned(
                    bottom: 250.h,
                    child: TopicDraggableWord(
                      word: currentWord, 
                      primaryColor: theme.primaryColor, 
                      isDark: isDark,
                      onFlick: (v) => _handleFlick(v, currentWord, buckets, correctAnswer),
                    ).animate(key: ValueKey("word_$_currentWordIndex"))
                     .move(begin: const Offset(0, -100), end: Offset.zero, duration: 500.ms, curve: Curves.bounceOut)
                     .fadeIn(),
                  ),

                // Flying Word Animation
                if (_flickedWord != null)
                  Positioned(
                    bottom: 250.h,
                    child: Container(
                      width: 140.w, 
                      height: 70.h,  
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _flickedWord!.toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ).animate()
                     .move(
                       begin: Offset.zero, 
                       end: Offset(_flickTarget == 0 ? -120.w : 120.w, 180.h), 
                       duration: 400.ms, 
                       curve: Curves.easeInBack
                     )
                     .scale(begin: const Offset(1,1), end: const Offset(0.2, 0.2))
                     .fadeOut(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstruction(String text, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r), boxShadow: [BoxShadow(color: color, blurRadius: 10)]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_right_rounded, color: Colors.white, size: 12.r),
              SizedBox(width: 4.w),
              Text("FLICK TO SORT", style: GoogleFonts.shareTechMono(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1)),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
          child: Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.9), letterSpacing: 1.5), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
