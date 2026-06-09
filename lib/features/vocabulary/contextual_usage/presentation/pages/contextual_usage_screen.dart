import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_painters.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_card.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_option_chip.dart';

class ContextualUsageScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextualUsageScreen({
    super.key, 
    required this.level, 
    this.gameType = GameSubtype.contextualUsage
  });

  @override
  State<ContextualUsageScreen> createState() => _ContextualUsageScreenState();
}

class _ContextualUsageScreenState extends State<ContextualUsageScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
        setState(() => _isCorrect = true);
        context.read<VocabularyBloc>().add(SubmitAnswer(true));
      } else {
        _hapticService.error();
        _soundService.playWrong();
        setState(() => _isCorrect = false);
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'USAGE EXPERT!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        final loadedState = state is VocabularyLoaded ? state : null;

        if (state is VocabularyLoading || (quest == null && state is! VocabularyGameComplete && state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        _isAnswered = loadedState?.lastAnswerCorrect != null;
        _isCorrect = loadedState?.lastAnswerCorrect;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          disablePadding: true,
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(
                          theme.primaryColor.withValues(
                            alpha: isDarkMode ? 0.05 : 0.03,
                          ),
                        ),
                      ),
                    ),
                    _buildUnfoldContent(quest, theme.primaryColor, isDarkMode),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildUnfoldContent(VocabularyQuest quest, Color color, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 580;

        final double estimatedContentHeight = (isCompact ? 40.h : 60.h) + (isCompact ? 100.h : 150.h) + (isCompact ? 80.h : 120.h) + 20.h;
        final remainingHeight = maxHeight - estimatedContentHeight;

        final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
        final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(10.0, 40.0) : 10.0;
        final double gapMiddle = remainingHeight > 0 ? (gapUnit * 1.5).clamp(15.0, 40.0) : 15.0;
        final double gapBottom = remainingHeight > 0 ? (gapUnit * 2.5).clamp(20.0, 60.0) : 20.0;

        return Column(
          children: [
            SizedBox(height: gapTop),
            isCompact
                ? SizedBox(
                    height: 25.h,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "USAGE UNFOLD",
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 11.sp,
                          color: color,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    "USAGE UNFOLD",
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11.sp,
                      color: color,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 800.ms).shimmer(duration: 2.seconds),

            SizedBox(height: gapMiddle),

            isCompact
                ? SizedBox(
                    height: 120.h,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth - 40.w,
                        child: ContextualUsageCard(
                          question: quest.question ?? "",
                          color: color,
                          isDark: isDark,
                          isAnswered: _isAnswered,
                          isCorrect: _isCorrect,
                          selectedOption: _selectedOption,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ContextualUsageCard(
                      question: quest.question ?? "",
                      color: color,
                      isDark: isDark,
                      isAnswered: _isAnswered,
                      isCorrect: _isCorrect,
                      selectedOption: _selectedOption,
                    ),
                  ),

            SizedBox(height: gapMiddle),

            isCompact
                ? SizedBox(
                    height: 100.h,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: _buildChipsWrap(quest, color, isDark, isCompact),
                      ),
                    ),
                  )
                : _buildChipsWrap(quest, color, isDark, isCompact),
            SizedBox(height: gapBottom),
          ],
        );
      },
    );
  }

  Widget _buildChipsWrap(VocabularyQuest quest, Color color, bool isDark, bool isCompact) {
    return Wrap(
      spacing: 16.w, 
      runSpacing: isCompact ? 10.h : 16.h,
      alignment: WrapAlignment.center,
      children: (quest.options ?? []).map((o) {
        return ContextualUsageOptionChip(
          text: o,
          color: color,
          isDark: isDark,
          isSelected: _selectedOption == o,
          isCorrect: _isCorrect,
          onTap: () => _submitAnswer(o, quest.correctAnswer ?? ""),
        );
      }).toList(),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

}
