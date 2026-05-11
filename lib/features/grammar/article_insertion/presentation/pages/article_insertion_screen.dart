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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArticleInsertionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ArticleInsertionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.articleInsertion,
  });

  @override
  State<ArticleInsertionScreen> createState() => _ArticleInsertionScreenState();
}

class _ArticleInsertionScreenState extends State<ArticleInsertionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  String? _selectedArticle;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPop(String article, String correctAnswer) {
    if (_isAnswered) return;
    
    _hapticService.selection();

    bool isCorrect = article.toLowerCase() == correctAnswer.toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _selectedArticle = article; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
        _selectedArticle = article;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedArticle = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ARTICLE ACE!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["a", "an", "the", "Ø"];
        
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
              _buildSentenceBoard(quest.sentenceWithBlank ?? quest.question ?? "____ sentence.", _selectedArticle, theme.primaryColor, isDark),
              SizedBox(height: 40.h),
              Expanded(
                child: _isAnswered 
                  ? _buildResultView(theme.primaryColor)
                  : _buildBubbleArea(options, quest.correctAnswer ?? "", theme.primaryColor, isDark),
              ),
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
          Icon(Icons.bubble_chart_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("POP THE CORRECT BUBBLE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceBoard(String template, String? selected, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(24.r),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.fredoka(fontSize: 22.sp, color: isDark ? Colors.white70 : Colors.black87),
          children: _buildSentenceWithBlank(template, selected, primaryColor, isDark),
        ),
      ),
    );
  }

  List<InlineSpan> _buildSentenceWithBlank(String template, String? selected, Color primaryColor, bool isDark) {
    final parts = template.split("____");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected != null ? primaryColor : (isDark ? Colors.white38 : Colors.black38), width: 2))),
            child: Text(selected ?? "      ", style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.bold, color: primaryColor)),
          ),
        ));
      }
    }
    return spans;
  }

  Widget _buildBubbleArea(List<String> options, String correct, Color primaryColor, bool isDark) {
    return Stack(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final article = entry.value;
        return _FloatingBubble(
          article: article,
          index: index,
          onTap: () => _onPop(article, correct),
          primaryColor: primaryColor,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildResultView(Color primaryColor) {
    return Center(
      child: Icon(
        _isCorrect == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: _isCorrect == true ? Colors.greenAccent : Colors.redAccent,
        size: 80.r,
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

class _FloatingBubble extends StatefulWidget {
  final String article;
  final int index;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  const _FloatingBubble({required this.article, required this.index, required this.onTap, required this.primaryColor, required this.isDark});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _driftController;
  late double _top;
  late double _left;

  @override
  void initState() {
    super.initState();
    _top = widget.index * 60.h + 20.h;
    _left = (widget.index % 2 == 0) ? 40.w : 200.w;
    _driftController = AnimationController(vsync: this, duration: Duration(seconds: 3 + widget.index))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, child) {
        return Positioned(
          top: _top + (10.h * _driftController.value),
          left: _left + (10.w * (1 - _driftController.value)),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 80.r, height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.primaryColor.withValues(alpha: 0.4),
                    widget.primaryColor.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                boxShadow: [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Center(
                child: Text(widget.article.toUpperCase(), style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
          ),
        );
      },
    );
  }
}

