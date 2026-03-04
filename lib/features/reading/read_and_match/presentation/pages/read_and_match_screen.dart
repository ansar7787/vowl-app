import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_result_overlay.dart';
import 'package:voxai_quest/core/presentation/widgets/reading/book_streak.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/reading/domain/entities/reading_quest.dart';
import 'package:voxai_quest/features/reading/presentation/bloc/reading_bloc.dart';

class ReadAndMatchScreen extends StatefulWidget {
  final int level;
  const ReadAndMatchScreen({super.key, required this.level});

  @override
  State<ReadAndMatchScreen> createState() => _ReadAndMatchScreenState();
}

class _ReadAndMatchScreenState extends State<ReadAndMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _selectedLeftIndex;
  int? _selectedRightIndex;
  List<int> _matchedIndices = [];
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(
        gameType: GameSubtype.readAndMatch,
        level: widget.level,
      ),
    );
  }

  void _onLeftSelect(int index) {
    if (_matchedIndices.contains(index)) return;
    _hapticService.selection();
    setState(() {
      _selectedLeftIndex = index;
      if (_selectedRightIndex != null) {
        _checkMatch();
      }
    });
  }

  void _onRightSelect(int index) {
    if (_matchedIndices.contains(index)) {
      return;
    }
    _hapticService.selection();
    setState(() {
      _selectedRightIndex = index;
      if (_selectedLeftIndex != null) {
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    // For simplicity in this UI, we assume parallel indices are the correct pairs
    // Real logic would use quest.pairs or similar
    if (_selectedLeftIndex == _selectedRightIndex) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() {
        _matchedIndices.add(_selectedLeftIndex!);
        _selectedLeftIndex = null;
        _selectedRightIndex = null;
      });

      // Check if all matched
      final state = context.read<ReadingBloc>().state;
      if (state is ReadingLoaded) {
        final totalPairs = state.currentQuest.pairs?.length ?? 3;
        if (_matchedIndices.length == totalPairs) {
          context.read<ReadingBloc>().add(SubmitAnswer(true));
        }
      }
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() {
        _selectedLeftIndex = null;
        _selectedRightIndex = null;
      });
      // Optionally deduct life on wrong match if that's the game design,
      // but usually matching games just let you try again until you fail overall or succeed
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  void _useHint() {
    _hapticService.selection();
    context.read<ReadingBloc>().add(ReadingHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<ReadingBloc, ReadingState>(
        listener: (context, state) {
          if (state is ReadingGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Matching Marvel!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for your connectivity!',
        ),
            );
          } else if (state is ReadingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Connection Lost',
        description: 'Try to match the items more accurately next time!',
        onRestore: () => context.read<ReadingBloc>().add(RestoreLife()),
      );
          } else if (state is ReadingLoaded &&
              state.lastAnswerCorrect == null) {
            // Reset for next question
            setState(() {
              _matchedIndices = [];
              _selectedLeftIndex = null;
              _selectedRightIndex = null;
            });
          }
        },
        builder: (context, state) {
          if (state is ReadingLoading || state is ReadingInitial) {
            return const GameShimmerLoading();
          }
          if (state is ReadingLoaded) {
            final theme = LevelThemeHelper.getTheme(
              'reading',
              level: widget.level,
            );
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                BookStreak(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is ReadingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<ReadingBloc>().add(
                FetchReadingQuests(
                  gameType: GameSubtype.readAndMatch,
                  level: widget.level,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    BuildContext context,
    ReadingLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final ReadingQuest quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;
    final pairs = quest.pairs ?? [];

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
              child: Row(
                children: [
                  ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 24.r,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14.h,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _buildHintButton(state.hintUsed, theme.primaryColor),
                  SizedBox(width: 12.w),
                  _buildHeartCount(state.livesRemaining),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      theme.title,
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ).animate().fadeIn(),
                    SizedBox(height: 20.h),
                    Text(
                      "Match the descriptions to the correct items.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ).animate().fadeIn(),
                    SizedBox(height: 40.h),
                    Expanded(
                      child: Row(
                        children: [
                          // Left Column
                          Expanded(
                            child: ListView.builder(
                              itemCount: pairs.length,
                              itemBuilder: (context, index) {
                                final text = pairs[index].keys.first;
                                final isMatched = _matchedIndices.contains(
                                  index,
                                );
                                final isSelected = _selectedLeftIndex == index;
                                return _buildMatchCard(
                                  text: text,
                                  isLeft: true,
                                  isSelected: isSelected,
                                  isMatched: isMatched,
                                  isDark: isDark,
                                  primaryColor: theme.primaryColor,
                                  onTap: () => _onLeftSelect(index),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // Right Column
                          Expanded(
                            child: ListView.builder(
                              itemCount: pairs.length,
                              itemBuilder: (context, index) {
                                final text = pairs[index].values.first;
                                final isMatched = _matchedIndices.contains(
                                  index,
                                );
                                final isSelected = _selectedRightIndex == index;
                                return _buildMatchCard(
                                  text: text,
                                  isLeft: false,
                                  isSelected: isSelected,
                                  isMatched: isMatched,
                                  isDark: isDark,
                                  primaryColor: theme.primaryColor,
                                  onTap: () => _onRightSelect(index),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "PERFECT MATCH!" : "ALMOST!",
            subtitle:
                state.currentQuest.explanation ??
                "Connectivity skills expanding!",
            onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildMatchCard({
    required String text,
    required bool isLeft,
    required bool isSelected,
    required bool isMatched,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    Color? cardColor;
    Color? borderColor;

    if (isMatched) {
      cardColor = const Color(0xFF10B981);
      borderColor = cardColor;
    } else if (isSelected) {
      cardColor = primaryColor.withValues(alpha: 0.2);
      borderColor = primaryColor;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: isMatched ? null : onTap,
        child: GlassTile(
          borderRadius: BorderRadius.circular(20.r),
          padding: EdgeInsets.all(20.r),
          color: cardColor,
          borderColor: borderColor ?? primaryColor.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.spectral(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isMatched
                    ? Colors.white
                    : isSelected
                    ? primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: isLeft ? -0.05 : 0.05);
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20.r),
          SizedBox(width: 6.w),
          Text(
            "$lives",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton(bool used, Color primaryColor) {
    return ScaleButton(
      onTap: used ? null : _useHint,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: used
              ? Colors.grey.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: used
                ? Colors.grey.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              used ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
              color: used ? Colors.grey : primaryColor,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            Text(
              "HINT",
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: used ? Colors.grey : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  
}
