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
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

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
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onRoverDrag(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onRoverRelease(VocabularyQuest quest) {
    if (_isAnswered) return;
    
    final options = quest.options ?? [];
    int? dockedIndex;
    
    // Check collision with terminals
    for (int i = 0; i < options.length; i++) {
      final terminalPos = _getTerminalPosition(i, options.length);
      final roverPos = Offset.zero + _dragOffset; // Offset relative to center
      
      if ((roverPos - terminalPos).distance < 60.r) {
        dockedIndex = i;
        break;
      }
    }

    if (dockedIndex != null) {
      _submitAffix(options[dockedIndex], quest);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
      _hapticService.light();
    }
  }

  void _submitAffix(String option, VocabularyQuest quest) {
    final correctWord = quest.correctAnswer?.toLowerCase() ?? "";
    final root = quest.rootWord?.toLowerCase() ?? "";
    final cleanOption = option.replaceAll('-', '').trim().toLowerCase();
    
    bool isCorrect = false;
    if (option.endsWith('-')) { // Prefix
      isCorrect = (cleanOption + root) == correctWord;
    } else if (option.startsWith('-')) { // Suffix
      isCorrect = (root + cleanOption) == correctWord;
    } else {
      // Fallback: check if the word contains the option and root
      isCorrect = correctWord.contains(cleanOption) && correctWord.contains(root);
    }

    if (isCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  Offset _getTerminalPosition(int index, int total) {
    // Positioning around a circle
    double angle = (index * (2 * math.pi / total)) - (math.pi / 2);
    double radius = 160.r;
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dragOffset = Offset.zero;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'LEXICAL MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            // Find correct terminal
            final options = quest?.options ?? [];
            final correct = quest?.correctAnswer?.toLowerCase() ?? "";
            final root = quest?.rootWord?.toLowerCase() ?? "";
            
            for (int i = 0; i < options.length; i++) {
              final opt = options[i].replaceAll('-', '').trim().toLowerCase();
              if (correct.contains(opt)) {
                // Flash the correct terminal
                setState(() => _dragOffset = _getTerminalPosition(i, options.length) * 0.3);
                Future.delayed(1.seconds, () {
                  if (mounted && !_isAnswered) setState(() => _dragOffset = Offset.zero);
                });
                break;
              }
            }
          },
          child: quest == null ? const SizedBox() : Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _buildMissionControl(theme.primaryColor),
                
                // Docking Terminals
                ...List.generate(quest.options?.length ?? 0, (i) => _buildDockingTerminal(i, quest.options![i], theme.primaryColor, isDark, quest.options!.length)),

                // The Root Rover
                _buildRootRover(quest.rootWord ?? "???", theme.primaryColor, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionControl(Color color) {
    return Positioned(
      top: -60.h,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              "MISSION: DOCK ROVER TO CORRECT AFFIX",
              style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            "DRAG THE ROVER INTO A TERMINAL",
            style: GoogleFonts.outfit(fontSize: 9.sp, color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDockingTerminal(int index, String text, Color color, bool isDark, int total) {
    final pos = _getTerminalPosition(index, total);
    
    return Positioned(
      left: pos.dx - 45.w,
      top: pos.dy - 30.h,
      child: Container(
        width: 90.w,
        height: 60.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisSize.min,
          children: [
            Text(
              text.toUpperCase(),
              style: GoogleFonts.fredoka(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 4.h),
            Container(width: 20.w, height: 2.h, color: color.withValues(alpha: 0.2)),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .shimmer(delay: (index * 200).ms, duration: 2.seconds, color: color.withValues(alpha: 0.1)),
    );
  }

  Widget _buildRootRover(String root, Color color, bool isDark) {
    return GestureDetector(
      onPanUpdate: _onRoverDrag,
      onPanEnd: (_) => _onRoverRelease(_lastQuest!),
      child: Transform.translate(
        offset: _dragOffset,
        child: AnimatedScale(
          duration: 200.ms,
          scale: _dragOffset == Offset.zero ? 1.0 : 1.1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rocket_launch_rounded, color: color, size: 24.r),
                SizedBox(height: 12.h),
                Text(
                  root.toUpperCase(),
                  style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: _dragOffset == Offset.zero ? 1 : 0)
     .shake(duration: 2.seconds, hz: 0.5);
  }
}

