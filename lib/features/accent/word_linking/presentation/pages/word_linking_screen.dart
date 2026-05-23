import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class WordLinkingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordLinkingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordLinking,
  });

  @override
  State<WordLinkingScreen> createState() => _WordLinkingScreenState();
}

class _WordLinkingScreenState extends State<WordLinkingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedNodeIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onNodeTap(int index, String correctPair, List<String> words) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedNodeIndex = index;
    });

    String selectedPair = "${words[index]} ${words[index+1]}";
    bool isCorrect = selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false; 
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
      
      Future.delayed(2.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedNodeIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedNodeIndex = null;
            });
            // Proactively auto-play phonetic sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LINKAGE MASTER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;
        final words = quest?.words ?? [];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  _buildPromptCard(theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  _buildPulseSpeaker(quest.textToSpeak ?? "", theme.primaryColor),
                  SizedBox(height: 48.h),
                  
                  _buildSentenceLinkingField(words, quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 40.h),
                    _buildResultExplanation(quest, theme.primaryColor, isDark),
                  ],
                  SizedBox(height: 60.h),
                ],
              ),
            ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 14.r, color: color),
          SizedBox(width: 12.w),
          Text("TAP THE CHAIN LINK NODE WHERE CONTEXTUAL WORD LINKING OCCURS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPromptCard(Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Text(
            "Word linking (liaison) seamlessly connects speech, merging a word's final sound into the next word's initial sound. Can you locate where linking happens?",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseSpeaker(String text, Color color) {
    return ScaleButton(
      onTap: () => _playTts(text),
      child: Container(
        width: 110.r, height: 110.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20)
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded, color: color, size: 36.r)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
              SizedBox(height: 6.h),
              Text(
                "HEAR LINKING",
                style: GoogleFonts.shareTechMono(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 1)
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceLinkingField(List<String> words, String correctPair, Color color, bool isDark) {
    List<Widget> children = [];
    
    for (int i = 0; i < words.length; i++) {
      children.add(_buildWordChip(words[i], color, isDark));
      
      if (i < words.length - 1) {
        children.add(_buildLinkNode(i, correctPair, words, color, isDark));
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
      ),
      child: Center(
        child: Wrap(
          spacing: 8.w,
          runSpacing: 12.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _buildWordChip(String word, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.15))
      ),
      child: Text(
        word.toUpperCase(), 
        style: GoogleFonts.shareTechMono(
          fontSize: 15.sp, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white : Colors.black87
        )
      ),
    );
  }

  Widget _buildLinkNode(int index, String correctPair, List<String> words, Color color, bool isDark) {
    final bool isSelected = _selectedNodeIndex == index;
    
    // Check if this node represents the correct linking pair
    String selectedPair = "${words[index]} ${words[index+1]}";
    final bool correct = selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

    Color nodeColor = color.withValues(alpha: 0.3);
    if (_isAnswered) {
      if (correct) {
        nodeColor = Colors.greenAccent;
      } else if (isSelected) {
        nodeColor = Colors.redAccent;
      }
    } else if (isSelected) {
      nodeColor = color;
    }

    return ScaleButton(
      onTap: () => _onNodeTap(index, correctPair, words),
      child: Container(
        width: 32.r, height: 32.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected || (_isAnswered && correct) 
            ? nodeColor.withValues(alpha: 0.2) 
            : Colors.transparent,
          border: Border.all(color: nodeColor, width: 2),
          boxShadow: isSelected || (_isAnswered && correct)
            ? [BoxShadow(color: nodeColor.withValues(alpha: 0.4), blurRadius: 10)]
            : []
        ),
        child: Center(
          child: Icon(
            Icons.link_rounded, 
            size: 16.r, 
            color: nodeColor
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(1,1), end: const Offset(1.15, 1.15), duration: 2.seconds),
    );
  }

  Widget _buildResultExplanation(AccentQuest quest, Color color, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT LINKING!" : "INCORRECT LINKING",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
