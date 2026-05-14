import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DescribeSituationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DescribeSituationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.describeSituationWriting,
  });

  @override
  State<DescribeSituationScreen> createState() => _DescribeSituationScreenState();
}

class _DescribeSituationScreenState extends State<DescribeSituationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final List<String> _storyKeywords = [];
  int? _expandedEmojiIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onEmojiTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _expandedEmojiIndex = (_expandedEmojiIndex == index ? null : index));
  }

  void _addKeyword(String keyword) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() {
      _storyKeywords.add(keyword);
      _expandedEmojiIndex = null;
    });
  }

  void _removeKeyword(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _storyKeywords.removeAt(index));
  }

  void _submitAnswer(int minKeywords) {
    if (_isAnswered || _storyKeywords.length < minKeywords) return;
    
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _storyKeywords.clear();
              _expandedEmojiIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CREATIVE GENIUS!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        // Mock emojis/keywords for the constellation
        final emojiPrompt = ["🌟", "🎭", "🚀", "🔥"];
        final keywordMap = {
          0: ["GLOWING", "RADIANT", "CELESTIAL"],
          1: ["DRAMATIC", "STORY", "MOMENT"],
          2: ["JOURNEY", "FLIGHT", "ESCAPE"],
          3: ["PASSION", "INTENSE", "HEAT"],
        };

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 40.h),
              _buildNarrativeScroll(_storyKeywords, theme.primaryColor, isDark),
              SizedBox(height: 40.h),
              Expanded(
                child: _buildMentalMap(emojiPrompt, keywordMap, theme.primaryColor),
              ),
              if (!_isAnswered)
                ScaleButton(
                  onTap: () => _submitAnswer(3), // Min 3 keywords for demo
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: _storyKeywords.length >= 3 ? theme.primaryColor : Colors.grey, boxShadow: [if (_storyKeywords.length >= 3) BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)]),
                    child: Center(child: Text("SEAL NARRATIVE", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
                ),
              SizedBox(height: 20.h),
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
          Text("EXPAND THE CONSTELLATION TO REVEAL THE STORY", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildNarrativeScroll(List<String> keywords, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 100.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
        image: DecorationImage(image: const NetworkImage('https://www.transparenttextures.com/patterns/old-map.png'), opacity: 0.1, repeat: ImageRepeat.repeat),
      ),
      child: Wrap(
        spacing: 10.w, runSpacing: 10.h,
        children: keywords.asMap().entries.map((e) => GestureDetector(
          onTap: () => _removeKeyword(e.key),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color)),
            child: Text(e.value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        )).toList(),
      ),
    ).animate(target: keywords.isNotEmpty ? 1 : 0).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildMentalMap(List<String> emojis, Map<int, List<String>> keywords, Color color) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(emojis.length, (index) {
          bool isExpanded = _expandedEmojiIndex == index;
          return AnimatedPositioned(
            duration: 500.milliseconds,
            curve: Curves.elasticOut,
            top: 100.h + (index % 2 == 0 ? -60.h : 60.h),
            left: 40.w + (index * 80.w),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _onEmojiTap(index),
                  child: Container(
                    width: 60.r, height: 60.r,
                    decoration: BoxDecoration(
                      color: isExpanded ? color : Colors.white10,
                      shape: BoxShape.circle,
                      boxShadow: [if (isExpanded) BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20)],
                    ),
                    child: Center(child: Text(emojis[index], style: TextStyle(fontSize: 24.sp))),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                ),
                if (isExpanded)
                  Container(
                    margin: EdgeInsets.only(top: 10.h),
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: color)),
                    child: Column(
                      children: keywords[index]!.map((k) => TextButton(
                        onPressed: () => _addKeyword(k),
                        child: Text(k, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12.sp)),
                      )).toList(),
                    ),
                  ).animate().scale(alignment: Alignment.topCenter).fadeIn(),
              ],
            ),
          );
        }),
      ),
    );
  }
}
