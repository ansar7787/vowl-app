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
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class FlashcardsScreen extends StatefulWidget {
  final int level;

  const FlashcardsScreen({super.key, required this.level});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isFlipped = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(
        gameType: GameSubtype.flashcards,
        level: widget.level,
      ),
    );
  }

  void _onFlip() {
    setState(() => _isFlipped = !_isFlipped);
    _hapticService.selection();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'vocabulary',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          MeshGradientBackground(colors: theme.backgroundColors),
          BlocConsumer<VocabularyBloc, VocabularyState>(
            listener: (context, state) {
              if (state is VocabularyGameComplete) {
                setState(() => _showConfetti = true);
                final isPremium =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;
                di.sl<AdService>().showInterstitialAd(
                  isPremium: isPremium,
                  onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'FLASHCARD MASTER!',
          description:
              'Great job! You earned ${state.xpEarned} XP and ${state.coinsEarned} coins.',
        ),
                );
              } else if (state is VocabularyGameOver) {
                GameDialogHelper.showGameOver(
        context,
        title: 'GAME OVER',
        description: 'Flashcards can be tricky. Keep practicing!',
      );
              }
            },
            builder: (context, state) {
              if (state is VocabularyLoading || state is VocabularyInitial) {
                return const GameShimmerLoading();
              }

              if (state is VocabularyError) {
                return QuestUnavailableScreen(
                  message: state.message,
                  onRetry: () => context.read<VocabularyBloc>().add(
                    FetchVocabularyQuests(
                      gameType: GameSubtype.flashcards,
                      level: widget.level,
                    ),
                  ),
                );
              }
              if (state is VocabularyLoaded) {
                final quest = state.currentQuest;
                final progress = (state.currentIndex + 1) / state.quests.length;

                return SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, state, progress, theme, isDark),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          "Memorize and Reveal",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildFlashcard(quest, theme, isDark),
                      const Spacer(),
                      _buildActionButtons(context, state, theme, isDark),
                      SizedBox(height: 40.h),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          if (_showConfetti) const GameConfetti(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VocabularyLoaded state,
    double progress,
    ThemeResult theme,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: Row(
        children: [
          ScaleButton(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 24.r,
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                minHeight: 12.h,
              ),
            ),
          ),
          SizedBox(width: 15.w),
          _buildHeartCount(state.livesRemaining),
        ],
      ),
    );
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
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

  Widget _buildFlashcard(dynamic quest, ThemeResult theme, bool isDark) {
    return GestureDetector(
      onTap: _onFlip,
      child: SizedBox(
        height: 400.h,
        width: 320.w,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            final rotate = Tween(begin: 3.1415, end: 0.0).animate(animation);
            return AnimatedBuilder(
              animation: rotate,
              child: child,
              builder: (context, child) {
                final isUnder = (ValueKey(_isFlipped) != child!.key);
                final value = isUnder
                    ? rotate.value
                    : (rotate.value - 3.1415).abs();
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(value),
                  alignment: Alignment.center,
                  child: child,
                );
              },
            );
          },
          child: _isFlipped
              ? _buildCardSide(
                  key: const ValueKey(true),
                  title: 'Definition / Example',
                  content:
                      quest.explanation ?? quest.sentence ?? 'No explanation',
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  textColor: isDark ? Colors.white : Colors.black87,
                  theme: theme,
                )
              : _buildCardSide(
                  key: const ValueKey(false),
                  title: 'Vocabulary Word',
                  content: quest.word ?? 'Unknown',
                  color: theme.primaryColor.withValues(alpha: 0.9),
                  textColor: Colors.white,
                  theme: theme,
                ),
        ),
      ),
    );
  }

  Widget _buildCardSide({
    required Key key,
    required String title,
    required String content,
    required Color color,
    required Color textColor,
    required ThemeResult theme,
  }) {
    return GlassTile(
      key: key,
      borderRadius: BorderRadius.circular(30.r),
      borderColor: Colors.white10,
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20.r,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                letterSpacing: 2,
                color: textColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Divider(height: 40, color: Colors.white24),
            Text(
              content,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (_isFlipped) ...[
              const Spacer(),
              ScaleButton(
                onTap: () {
                  _hapticService.selection();
                  // Integration for speech could go here
                },
                child: Icon(
                  Icons.volume_up_rounded,
                  color: theme.primaryColor,
                  size: 48.r,
                ),
              ).animate().shimmer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    VocabularyLoaded state,
    ThemeResult theme,
    bool isDark,
  ) {
    if (!_isFlipped) {
      return Text(
            'TAP CARD TO REVEAL',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .fadeIn(duration: 1.seconds)
          .fadeOut(delay: 1.seconds);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'AGAIN',
              icon: Icons.refresh_rounded,
              color: Colors.red.withValues(alpha: 0.2),
              textColor: Colors.redAccent,
              onTap: () {
                _hapticService.error();
                setState(() => _isFlipped = false);
                context.read<VocabularyBloc>().add(SubmitAnswer(false));
              },
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: _buildActionButton(
              label: 'KNOW',
              icon: Icons.check_circle_rounded,
              color: theme.primaryColor.withValues(alpha: 0.2),
              textColor: theme.primaryColor,
              onTap: () {
                _hapticService.success();
                setState(() => _isFlipped = false);
                context.read<VocabularyBloc>().add(SubmitAnswer(true));
                context.read<VocabularyBloc>().add(NextQuestion());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  
}
