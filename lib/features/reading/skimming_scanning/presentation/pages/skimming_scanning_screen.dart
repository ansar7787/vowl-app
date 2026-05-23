import 'dart:async';
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
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

class SkimmingScanningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SkimmingScanningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.skimmingScanning,
  });

  @override
  State<SkimmingScanningScreen> createState() => _SkimmingScanningScreenState();
}

class _SkimmingScanningScreenState extends State<SkimmingScanningScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late ScrollController _scrollController;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(800.milliseconds, () {
      if (!mounted || _isAnswered) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 12.seconds,
          curve: Curves.linear,
        );
      }
    });
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()\[\]]'), '').trim();
  }

  void _submitCorrectAnswer() {
    if (_isAnswered) return;
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<ReadingBloc>().add(SubmitAnswer(true));
  }

  void _submitIncorrectAnswer() {
    if (_isAnswered) return;
    _hapticService.error();
    _soundService.playWrong();
    context.read<ReadingBloc>().add(SubmitAnswer(false));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
            });
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
            _startAutoScroll();
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SCANNING ACE!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded) ? state.currentQuest as ReadingQuest? : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildTargetBadge(quest.targetItem ?? "", theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  // Scanning Terminal Box
                  SizedBox(
                    height: 260.h,
                    width: double.infinity,
                    child: _buildScanningTerminal(quest.passage ?? "", quest.correctAnswer ?? "", theme.primaryColor),
                  ),
                  
                  SizedBox(height: 20.h),
                  Text(
                    _isAnswered ? "TARGET ACQUIRED!" : "TAP THE TARGET WORD AS IT ROLLS BY", 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      color: _isAnswered ? Colors.greenAccent : theme.primaryColor, 
                      fontSize: 12.sp, 
                      letterSpacing: 2
                    )
                  ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 24.h),
                    _buildCorrectResult(quest, theme.primaryColor, isDark),
                  ],
                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetBadge(String item, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar_rounded, color: color, size: 24.r).animate(onPlay: (c) => c.repeat()).shimmer(),
          SizedBox(width: 12.w),
          Text("ACQUIRE: ${item.toUpperCase()}", style: GoogleFonts.shareTechMono(fontSize: 16.sp, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildScanningTerminal(String text, String correct, Color color) {
    final List<String> words = text.split(RegExp(r'\s+'));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10, width: 4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 2)
        ],
      ),
      child: Stack(
        children: [
          // Scrolling Content
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            itemCount: (words.length / 4).ceil(),
            itemBuilder: (context, index) {
              int start = index * 4;
              int end = (start + 4).clamp(0, words.length);
              final List<String> rowWords = words.sublist(start, end);
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Wrap(
                  spacing: 8.w, runSpacing: 8.h,
                  children: rowWords.map((word) {
                    final clean = _cleanWord(word);
                    final isCorrectTarget = clean.toLowerCase() == correct.toLowerCase();
                    
                    final bool isTapped = _isAnswered && isCorrectTarget;
                    
                    return GestureDetector(
                      onTap: () {
                        if (isCorrectTarget) {
                          _submitCorrectAnswer();
                        } else {
                          _submitIncorrectAnswer();
                        }
                      },
                      child: AnimatedContainer(
                        duration: 300.milliseconds,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isTapped 
                              ? Colors.greenAccent.withValues(alpha: 0.25) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isTapped 
                                ? Colors.greenAccent 
                                : Colors.transparent,
                            width: 1.5
                          ),
                        ),
                        child: Text(
                          word,
                          style: GoogleFonts.shareTechMono(
                            fontSize: 18.sp,
                            color: isTapped 
                                ? Colors.greenAccent 
                                : Colors.greenAccent.withValues(alpha: 0.8),
                            fontWeight: isTapped ? FontWeight.bold : FontWeight.normal,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          
          // CRT Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          
          // Scanline
          const Positioned.fill(child: _ScanlineEffect()),
        ],
      ),
    );
  }

  Widget _buildCorrectResult(ReadingQuest quest, Color primaryColor, bool isDark) {
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
            correct ? "CORRECT!" : "INCORRECT",
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

class _ScanlineEffect extends StatelessWidget {
  const _ScanlineEffect();
  @override
  Widget build(BuildContext context) {
    return const TechPatternOverlay(opacity: 0.05);
  }
}
