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
import 'package:voxai_quest/features/reading/presentation/bloc/reading_bloc.dart';

class FindWordMeaningScreen extends StatefulWidget {
  final int level;
  const FindWordMeaningScreen({super.key, required this.level});

  @override
  State<FindWordMeaningScreen> createState() => _FindWordMeaningScreenState();
}

class _FindWordMeaningScreenState extends State<FindWordMeaningScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _selectedOptionIndex;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(
        gameType: GameSubtype.findWordMeaning,
        level: widget.level,
      ),
    );
  }

  void _submitAnswer(int index, int correctIndex) {
    if (_selectedOptionIndex != null || _hasSubmitted()) return;
    _hapticService.selection();
    setState(() => _selectedOptionIndex = index);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ReadingBloc>().add(SubmitAnswer(index == correctIndex));
      }
    });
  }

  void _useHint() {
    _hapticService.selection();
    context.read<ReadingBloc>().add(ReadingHintUsed());
  }

  bool _hasSubmitted() {
    final state = context.read<ReadingBloc>().state;
    return state is ReadingLoaded && state.lastAnswerCorrect != null;
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
          title: 'Lexical Master!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for your sharp eye!',
        ),
            );
          } else if (state is ReadingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Focus Needed',
        description: 'Your definition hunt paused. Try again!',
        onRestore: () => context.read<ReadingBloc>().add(RestoreLife()),
      );
          } else if (state is ReadingLoaded &&
              state.lastAnswerCorrect == null) {
            setState(() => _selectedOptionIndex = null);
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
                  gameType: GameSubtype.findWordMeaning,
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
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

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
                            : Colors.black12,
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
              child: SingleChildScrollView(
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
                    SizedBox(height: 32.h),
                    GlassTile(
                      borderRadius: BorderRadius.circular(32.r),
                      padding: EdgeInsets.symmetric(
                        vertical: 32.h,
                        horizontal: 24.w,
                      ),
                      borderColor: theme.primaryColor.withValues(alpha: 0.3),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (quest.passage != null) ...[
                            Row(
                              children: [
                                Container(
                                  width: 4.w,
                                  height: 16.h,
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  "CONTEXTUAL CLUE",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            _buildHighlightedPassage(
                              quest.passage!,
                              quest.targetWord ?? quest.highlightedWord ?? "",
                              isDark,
                              theme.primaryColor,
                            ),
                            SizedBox(height: 32.h),
                            Divider(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                            ),
                            SizedBox(height: 24.h),
                          ],
                          Text(
                            "DEFINE THE WORD",
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: theme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            quest.targetWord ?? "No word provided",
                            style: GoogleFonts.outfit(
                              fontSize: 42.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : theme.primaryColor,
                              letterSpacing: -1,
                            ),
                          ).animate().scale(
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                          if (quest.phoneticHint != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              "[ ${quest.phoneticHint} ]",
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                color: theme.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                    SizedBox(height: 48.h),
                    ...List.generate(quest.options?.length ?? 0, (index) {
                      final isSelected = _selectedOptionIndex == index;
                      final correctIndex = quest.correctAnswerIndex;
                      final isCorrectOption = (index == correctIndex);

                      Color? cardColor;
                      if (state.lastAnswerCorrect != null && isSelected) {
                        cardColor = isCorrectOption
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E);
                      }

                      return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: ScaleButton(
                              onTap: () =>
                                  _submitAnswer(index, correctIndex ?? 0),
                              child: GlassTile(
                                borderRadius: BorderRadius.circular(24.r),
                                padding: EdgeInsets.all(24.r),
                                color: cardColor,
                                borderColor: (state.hintUsed && isCorrectOption)
                                    ? theme.primaryColor
                                    : (isSelected &&
                                              state.lastAnswerCorrect == null
                                          ? theme.primaryColor.withValues(
                                              alpha: 0.5,
                                            )
                                          : theme.primaryColor.withValues(
                                              alpha: 0.1,
                                            )),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40.r,
                                      height: 40.r,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white24
                                            : theme.primaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + index),
                                          style: GoogleFonts.outfit(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected
                                                ? Colors.white
                                                : theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    Expanded(
                                      child: Text(
                                        quest.options![index],
                                        style: GoogleFonts.outfit(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (state.hintUsed && isCorrectOption)
                                      Icon(
                                            Icons.lightbulb_rounded,
                                            color: theme.primaryColor,
                                            size: 24.r,
                                          )
                                          .animate(onPlay: (c) => c.repeat())
                                          .shimmer(duration: 1500.ms),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: (index * 100).ms)
                          .slideX(begin: 0.05);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "VOCAB VIBES!" : "STAY CURIOUS!",
            subtitle: quest.explanation ?? "Semantic expansion!",
            onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
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
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: used ? Colors.grey : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedPassage(
    String passage,
    String word,
    bool isDark,
    Color primaryColor,
  ) {
    if (word.isEmpty) {
      return Text(
        passage,
        style: GoogleFonts.spectral(
          fontSize: 18.sp,
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }

    final lowerPassage = passage.toLowerCase();
    final lowerWord = word.toLowerCase();
    final index = lowerPassage.indexOf(lowerWord);

    if (index == -1) {
      return Text(
        passage,
        style: GoogleFonts.spectral(
          fontSize: 18.sp,
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: GoogleFonts.spectral(
          fontSize: 18.sp,
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        children: [
          TextSpan(text: passage.substring(0, index)),
          TextSpan(
            text: passage.substring(index, index + word.length),
            style: GoogleFonts.spectral(
              fontWeight: FontWeight.bold,
              color: primaryColor,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
            ),
          ),
          TextSpan(text: passage.substring(index + word.length)),
        ],
      ),
    );
  }

  

  
}
