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
    Future.delayed(500.milliseconds, () {
      if (!mounted || _isAnswered) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: 10.seconds,
        curve: Curves.linear,
      );
    });
  }

  void _onHighlight(String text, String correct) {
    if (_isAnswered) return;
    bool isCorrect = text.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      // Visual feedback for wrong highlight but don't fail immediately unless lives lost
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

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
            _scrollController.jumpTo(0);
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
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildTargetBadge(quest.targetItem ?? "", theme.primaryColor),
              SizedBox(height: 32.h),
              Expanded(
                child: _buildScanningTerminal(quest.passage ?? "", quest.correctAnswer ?? "", theme.primaryColor),
              ),
              if (!_isAnswered)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text("SWIPE TO HIGHLIGHT THE TARGET", style: GoogleFonts.shareTechMono(color: theme.primaryColor, fontSize: 12.sp, letterSpacing: 2)),
                ),
              SizedBox(height: 40.h),
            ],
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
    final words = text.split(' ');
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10, width: 4),
      ),
      child: Stack(
        children: [
          // Scrolling Content
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(24.r),
            itemCount: (words.length / 5).ceil(),
            itemBuilder: (context, index) {
              int start = index * 5;
              int end = (start + 5).clamp(0, words.length);
              String line = words.sublist(start, end).join(' ');
              return GestureDetector(
                onHorizontalDragEnd: (details) => line.contains(correct) ? _onHighlight(correct, correct) : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(line, style: GoogleFonts.shareTechMono(fontSize: 18.sp, color: Colors.greenAccent.withValues(alpha: 0.7), letterSpacing: 1)),
                ),
              );
            },
          ),
          
          // CRT Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent, Colors.black.withValues(alpha: 0.2)],
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
}

class _ScanlineEffect extends StatelessWidget {
  const _ScanlineEffect();
  @override
  Widget build(BuildContext context) {
    return const TechPatternOverlay(opacity: 0.05);
  }
}

