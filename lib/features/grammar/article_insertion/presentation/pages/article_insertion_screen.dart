import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/widgets/article_insertion_instruction.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/widgets/article_floating_orb.dart';

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
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onPop(String article, String correctAnswer) {
    if (_isAnswered) return;

    _hapticService.selection();
    bool isCorrect = article.toLowerCase() == correctAnswer.toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _selectedArticle = article;
    });
    context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
  }

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
  ) {
    final parts = template.contains("____")
        ? template.split("____")
        : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected != null
                      ? primaryColor
                      : (isDark ? Colors.white38 : Colors.black38),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              selected ?? "      ",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ).animate(target: selected != null ? 1 : 0).shimmer(duration: 2.seconds),
        ));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedArticle = null;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'ARTICLE ACE!',
            enableDoubleUp: true,
          );
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["a", "an", "the", "Ø"];
        final correctAnswer = quest?.correctAnswer ?? "";

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Column(
                  children: [
                    SizedBox(height: 10.h),
                    ArticleInsertionInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 20.h),

                    // Context Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(fontFamily: 'Outfit', 
                              fontSize: 20.sp,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.5,
                            ),
                            children: _buildSentenceWithBlank(
                              quest.sentence ?? quest.question ?? "___ sentence.",
                              _selectedArticle,
                              theme.primaryColor,
                              isDark,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                    // Floating Orb Bubble Area
                    Expanded(
                      child: Stack(
                        children: options.asMap().entries.map((entry) {
                          final article = entry.value;
                          return ArticleFloatingOrb(
                            article: article,
                            index: entry.key,
                            onTap: () => _onPop(article, correctAnswer),
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            isAnswered: _isAnswered,
                            isSelected: _selectedArticle == article,
                            isCorrectAnswer: article.toLowerCase() == correctAnswer.toLowerCase(),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
        );
      },
    );
  }
}
