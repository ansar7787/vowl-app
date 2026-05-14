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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadAndAnswerScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadAndAnswerScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readAndAnswer,
  });

  @override
  State<ReadAndAnswerScreen> createState() => _ReadAndAnswerScreenState();
}

class _ReadAndAnswerScreenState extends State<ReadAndAnswerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final ScrollController _scrollController = ScrollController();
  double _depth = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
    _scrollController.addListener(() {
      setState(() => _depth = _scrollController.offset);
      if (_depth % 50 < 5) _hapticService.selection();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onChoiceTap(int index, String selected, String correct) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              _selectedIndex = null;
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ZEN READER!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            children: [
              // The Deep Sea Abyss
              _buildAbyssBackground(theme.primaryColor),
              
              // The Diving Scroll
              ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                children: [
                  SizedBox(height: 100.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 60.h),
                  _buildFloatingPassage(quest.passage ?? "", theme.primaryColor),
                  SizedBox(height: 100.h),
                  _buildAnchorPoint(quest.question ?? "", theme.primaryColor),
                  SizedBox(height: 40.h),
                  ...List.generate(quest.options?.length ?? 0, (index) => _buildBuoyOption(index, quest.options![index], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
                  SizedBox(height: 200.h),
                ],
              ),
              
              // Depth Indicator
              _buildDepthMeter(theme.primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAbyssBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05), Colors.black],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.scuba_diving_rounded, size: 14.r, color: primaryColor),
            SizedBox(width: 12.w),
            Text("DIVE THROUGH THE ABYSS TO ANCHOR TRUTH", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingPassage(String text, Color color) {
    return GlassTile(
      padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(30.r),
      color: color.withValues(alpha: 0.05),
      child: Text(text, style: GoogleFonts.fredoka(fontSize: 20.sp, height: 1.8, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w400)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(color: Colors.white10, duration: 3.seconds);
  }

  Widget _buildAnchorPoint(String question, Color color) {
    return Column(
      children: [
        Icon(Icons.anchor_rounded, color: color, size: 48.r),
        SizedBox(height: 16.h),
        Text(question, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  Widget _buildBuoyOption(int index, String text, String correct, Color color, bool isDark) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = _isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    bool isWrong = _isAnswered && isSelected && !isCorrect;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ScaleButton(
        onTap: () => _onChoiceTap(index, text, correct),
        child: GlassTile(
          padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(20.r),
          color: isCorrect ? Colors.greenAccent.withValues(alpha: 0.3) : (isWrong ? Colors.redAccent.withValues(alpha: 0.3) : (isSelected ? color.withValues(alpha: 0.2) : Colors.white10)),
          border: Border.all(color: isSelected ? color : Colors.white24, width: 2),
          child: Row(
            children: [
              Icon(Icons.radio_button_checked_rounded, color: isSelected ? color : Colors.white24),
              SizedBox(width: 16.w),
              Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepthMeter(Color color) {
    return Positioned(
      right: 16.w, top: 100.h, bottom: 100.h,
      child: Column(
        children: [
          Text("${(_depth / 10).toInt()}M", style: GoogleFonts.shareTechMono(color: color, fontSize: 14.sp)),
          Expanded(
            child: Container(
              width: 4.w,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2.r)),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: (_depth / 1000).clamp(0.0, 1.0),
                    child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.r))),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16.r),
        ],
      ),
    );
  }
}

