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

class SentenceOrderScreen extends StatefulWidget {
  final int level;
  const SentenceOrderScreen({super.key, required this.level});

  @override
  State<SentenceOrderScreen> createState() => _SentenceOrderScreenState();
}

class _SentenceOrderScreenState extends State<SentenceOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  List<int>? _currentOrder;
  bool _hasSubmitted = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(
        gameType: GameSubtype.sentenceOrderReading,
        level: widget.level,
      ),
    );
  }

  void _initializeOrderIfNeeded(List<String> sentences) {
    _currentOrder ??= List.generate(sentences.length, (i) => i);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_hasSubmitted) return;
    _hapticService.selection();
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _currentOrder!.removeAt(oldIndex);
      _currentOrder!.insert(newIndex, item);
    });
  }

  void _submitAnswer(List<int> correctOrder) {
    if (_hasSubmitted) return;
    _hapticService.selection();
    setState(() => _hasSubmitted = true);

    bool isCorrect = true;
    for (int i = 0; i < correctOrder.length; i++) {
      if (_currentOrder![i] != correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
    } else {
      _soundService.playWrong();
      _hapticService.error();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ReadingBloc>().add(SubmitAnswer(isCorrect));
      }
    });
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
          title: 'Order Master!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins!',
        ),
            );
          } else if (state is ReadingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Out of Logic',
        description: 'The sentences are still a bit messy. Try again!',
        onRestore: () => context.read<ReadingBloc>().add(RestoreLife()),
      );
          } else if (state is ReadingLoaded &&
              state.lastAnswerCorrect == null) {
            setState(() {
              _hasSubmitted = false;
              _currentOrder = null;
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
                  gameType: GameSubtype.sentenceOrderReading,
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
    final sentences =
        quest.shuffledSentences ?? ["Sentence 1", "Sentence 2", "Sentence 3"];
    final correctOrder = quest.correctOrder ?? [0, 1, 2];

    _initializeOrderIfNeeded(sentences);

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

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                children: [
                  Text(
                    theme.title,
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    quest.instruction.isNotEmpty
                        ? quest.instruction
                        : "Reorder the blocks into a logical story.",
                    style: GoogleFonts.outfit(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Theme(
                data: ThemeData(canvasColor: Colors.transparent),
                child: ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 8.h,
                  ),
                  itemCount: _currentOrder!.length,
                  onReorder: _onReorder,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 0,
                      child: child.animate().scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.02, 1.02),
                        duration: 150.ms,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final originalIndex = _currentOrder![index];
                    final text = sentences[originalIndex];

                    Color? cardColor;
                    Color? borderColor;

                    if (_hasSubmitted && state.lastAnswerCorrect != null) {
                      bool isRightPlace = originalIndex == correctOrder[index];
                      cardColor = isRightPlace
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E);
                      borderColor = cardColor;
                    }

                    return Padding(
                          key: ValueKey(originalIndex),
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: GlassTile(
                            padding: EdgeInsets.all(24.r),
                            borderRadius: BorderRadius.circular(24.r),
                            borderColor:
                                borderColor ??
                                theme.primaryColor.withValues(alpha: 0.15),
                            color:
                                cardColor ??
                                (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.02)),
                            child: Row(
                              children: [
                                Container(
                                  width: 36.r,
                                  height: 36.r,
                                  decoration: BoxDecoration(
                                    color: (cardColor != null)
                                        ? Colors.white24
                                        : theme.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900,
                                        color: (cardColor != null)
                                            ? Colors.white
                                            : theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: GoogleFonts.spectral(
                                      fontSize: 17.sp,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                      color: (cardColor != null)
                                          ? Colors.white.withValues(alpha: 0.95)
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.85,
                                                  )
                                                : Colors.black87),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Icon(
                                  Icons.drag_indicator_rounded,
                                  color: (cardColor != null)
                                      ? Colors.white38
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.black12),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideX(begin: 0.02);
                  },
                ),
              ),
            ),

            if (!_hasSubmitted)
              Padding(
                padding: EdgeInsets.all(24.r),
                child: SizedBox(
                  width: double.infinity,
                  height: 64.h,
                  child: ScaleButton(
                    onTap: () => _submitAnswer(correctOrder),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "CHECK ORDER",
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "CHRONO MASTER!" : "MISALIGNED!",
            subtitle: quest.explanation ?? "Structure recognized!",
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
      onTap: used
          ? null
          : () => context.read<ReadingBloc>().add(ReadingHintUsed()),
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

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  

  
}
