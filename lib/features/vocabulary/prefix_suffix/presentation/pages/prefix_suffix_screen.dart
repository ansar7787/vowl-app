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
    
    // Check collision with terminals - INCREASED RADIUS (90.r) for better touch feedback
    for (int i = 0; i < options.length; i++) {
      final terminalPos = _getTerminalPosition(i, options.length, _lastConstraints!);
      final roverPos = Offset.zero + _dragOffset; 
      
      if ((roverPos - terminalPos).distance < 90.r) {
        dockedIndex = i;
        break;
      }
    }

    if (dockedIndex != null) {
      // Visual Snap to terminal
      setState(() {
        _dragOffset = _getTerminalPosition(dockedIndex!, options.length, _lastConstraints!);
      });
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
    final cleanOption = option.replaceAll('-', '').trim().toLowerCase();
    
    bool isCorrect = false;
    // ROBUST CHECK: Handles spelling changes (like Create -> Creation)
    if (option.endsWith('-')) { // Prefix (e.g., UN-)
      isCorrect = correctWord.startsWith(cleanOption);
    } else if (option.startsWith('-')) { // Suffix (e.g., -NESS)
      isCorrect = correctWord.endsWith(cleanOption);
    } else {
      isCorrect = correctWord.contains(cleanOption);
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

  BoxConstraints? _lastConstraints;

  Offset _getTerminalPosition(int index, int total, BoxConstraints constraints) {
    // FALLBACK: If constraints are infinite (common in ScrollViews), use screen size
    final screenSize = MediaQuery.of(context).size;
    final double safeMaxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
    final double safeMaxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (screenSize.height * 0.6);

    // Dynamic Responsive Positioning (Diamond/Corner Grid)
    double hDist = (safeMaxWidth - 120.w) / 2;
    double vDist = (safeMaxHeight - 180.h) / 2;
    
    // Use a smaller radius if the screen is tiny
    hDist = hDist.clamp(80.w, 140.w);
    vDist = vDist.clamp(100.h, 160.h);

    switch (index) {
      case 0: return Offset(-hDist, -vDist); // Top Left
      case 1: return Offset(hDist, -vDist);  // Top Right
      case 2: return Offset(-hDist, vDist);  // Bottom Left
      case 3: return Offset(hDist, vDist);   // Bottom Right
      default:
        double angle = (index * (2 * math.pi / total)) - (math.pi / 2);
        return Offset(math.cos(angle) * hDist, math.sin(angle) * vDist);
    }
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
          isFinalFailure: (state is VocabularyLoaded) ? state.isFinalFailure : false,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            final options = quest?.options ?? [];
            final correct = quest?.correctAnswer?.toLowerCase() ?? "";
            for (int i = 0; i < options.length; i++) {
              final opt = options[i].replaceAll('-', '').trim().toLowerCase();
              if (correct.contains(opt)) {
                setState(() => _dragOffset = _getTerminalPosition(i, options.length, _lastConstraints!) * 0.4);
                Future.delayed(1.seconds, () {
                  if (mounted && !_isAnswered) setState(() => _dragOffset = Offset.zero);
                });
                break;
              }
            }
          },
          child: quest == null ? const SizedBox() : LayoutBuilder(
            builder: (context, constraints) {
              _lastConstraints = constraints;
              final screenSize = MediaQuery.of(context).size;
              final double safeWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
              final double safeHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (screenSize.height * 0.6);

              return SizedBox(
                width: safeWidth,
                height: safeHeight,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildMissionControl(theme.primaryColor),
                    
                    // Docking Terminals (Options)
                    ...List.generate(quest.options?.length ?? 0, (i) => _buildDockingTerminal(i, quest.options![i], theme.primaryColor, isDark, quest.options!.length, constraints)),

                    // The Root Rover (Central Draggable)
                    _buildRootRover(quest, theme.primaryColor, isDark),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
  }

  Widget _buildMissionControl(Color color) {
    return Positioned(
      top: -80.h,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)],
            ),
            child: Text(
              "DOCK THE ROVER",
              style: GoogleFonts.shareTechMono(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
          SizedBox(height: 8.h),
          Text(
            "LEXICAL MISSION IN PROGRESS",
            style: GoogleFonts.outfit(fontSize: 8.sp, color: color.withValues(alpha: 0.5), fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDockingTerminal(int index, String text, Color color, bool isDark, int total, BoxConstraints constraints) {
    final pos = _getTerminalPosition(index, total, constraints);
    final screenSize = MediaQuery.of(context).size;
    final double safeWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (screenSize.height * 0.6);
    
    return Positioned(
      left: safeWidth / 2 + pos.dx - 40.w,
      top: safeHeight / 2 + pos.dy - 35.h,
      child: Container(
        width: 80.w,
        height: 70.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hexagonal tech pattern background
            Opacity(
              opacity: 0.1,
              child: Icon(Icons.hexagon_outlined, color: color, size: 50.r),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.toUpperCase(),
                  style: GoogleFonts.shareTechMono(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color),
                ),
                SizedBox(height: 2.h),
                Container(
                  width: 25.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 1.5.seconds)
       .shimmer(delay: (index * 150).ms, duration: 3.seconds, color: color.withValues(alpha: 0.2)),
    );
  }

  Widget _buildRootRover(VocabularyQuest quest, Color color, bool isDark) {
    return GestureDetector(
      onPanUpdate: _onRoverDrag,
      onPanEnd: (_) => _onRoverRelease(quest),
      child: Transform.translate(
        offset: _dragOffset,
        child: AnimatedScale(
          duration: 150.ms,
          scale: _dragOffset == Offset.zero ? 1.0 : 1.15,
          child: Container(
            width: 130.w,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 25, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Detailed Rocket Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.rocket_rounded, color: color, size: 32.r),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 4.r, height: 8.r,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scaleY(begin: 0.5, end: 1.5).fadeOut(),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  (quest.rootWord ?? "???").toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 20.sp, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white : Colors.black87, 
                    letterSpacing: 1.2
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: _dragOffset == Offset.zero ? 1 : 0)
     .shake(duration: 3.seconds, hz: 0.3);
  }
}



