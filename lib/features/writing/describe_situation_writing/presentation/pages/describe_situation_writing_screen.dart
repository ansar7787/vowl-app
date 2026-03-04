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
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/presentation/widgets/writing/ink_streak.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/writing/domain/entities/writing_quest.dart';
import 'package:voxai_quest/features/writing/presentation/bloc/writing_bloc.dart';

class DescribeSituationScreen extends StatefulWidget {
  final int level;
  const DescribeSituationScreen({super.key, required this.level});

  @override
  State<DescribeSituationScreen> createState() =>
      _DescribeSituationScreenState();
}

class _DescribeSituationScreenState extends State<DescribeSituationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final TextEditingController _controller = TextEditingController();
  bool _hasSubmitted = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(
        gameType: GameSubtype.describeSituationWriting,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (_hasSubmitted || _controller.text.trim().isEmpty) {
      return;
    }
    _hapticService.selection();
    setState(() => _hasSubmitted = true);

    bool isCorrect = _controller.text.trim().length > 10;

    if (isCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
    } else {
      _soundService.playWrong();
      _hapticService.error();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
      }
    });
  }

  void _useHint(WritingQuest quest) {
    _hapticService.light();
    if (quest.sampleAnswer != null && quest.sampleAnswer!.length > 20) {
      _controller.text = "${quest.sampleAnswer!.substring(0, 15)}...";
    } else {
      _controller.text = "In this situation, I can see...";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<WritingBloc, WritingState>(
        listener: (context, state) {
          if (state is WritingGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Situation Master!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins!',
        ),
            );
          } else if (state is WritingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Blank Canvas',
        description: 'The situation needs your words. Try again!',
        onRestore: () => context.read<WritingBloc>().add(RestoreLife()),
      );
          } else if (state is WritingLoaded &&
              state.lastAnswerCorrect == null) {
            setState(() {
              _hasSubmitted = false;
              _controller.clear();
            });
          }
        },
        builder: (context, state) {
          if (state is WritingLoading || state is WritingInitial) {
            return const GameShimmerLoading();
          }
          if (state is WritingLoaded) {
            final theme = LevelThemeHelper.getTheme(
              'writing',
              level: widget.level,
            );
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                InkStreak(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is WritingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<WritingBloc>().add(
                FetchWritingQuests(
                  gameType: GameSubtype.describeSituationWriting,
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
    WritingLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;
    final prompt =
        quest.prompt ?? "A scenario that needs a clear and vivid description.";

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
                  _buildHintButton(state.hintUsed, quest, theme.primaryColor),
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
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      quest.instruction,
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),

                    // Scene Description Area
                    GlassTile(
                      padding: EdgeInsets.all(24.r),
                      borderRadius: BorderRadius.circular(32.r),
                      borderColor: theme.primaryColor.withValues(alpha: 0.2),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 4.w,
                                height: 20.h,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "SCENE TO DESCRIBE",
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          Container(
                            height: 140.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withValues(alpha: 0.1),
                                  theme.primaryColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_mosaic_rounded,
                              color: theme.primaryColor,
                              size: 48.r,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            prompt,
                            style: GoogleFonts.spectral(
                              fontSize: 18.sp,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05),

                    SizedBox(height: 40.h),

                    // Text Input
                    GlassTile(
                      padding: EdgeInsets.all(4.r),
                      borderRadius: BorderRadius.circular(24.r),
                      borderColor: _hasSubmitted
                          ? (state.lastAnswerCorrect == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF43F5E))
                          : theme.primaryColor.withValues(alpha: 0.1),
                      child: TextField(
                        controller: _controller,
                        enabled: !_hasSubmitted,
                        maxLines: 8,
                        style: GoogleFonts.spectral(
                          fontSize: 17.sp,
                          height: 1.6,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Begin your depiction...",
                          hintStyle: GoogleFonts.spectral(
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                          contentPadding: EdgeInsets.all(24.r),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                    SizedBox(height: 40.h),

                    if (!_hasSubmitted)
                      Padding(
                        padding: EdgeInsets.only(bottom: 40.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 64.h,
                          child: ScaleButton(
                            onTap: _submitAnswer,
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
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "SUBMIT DESCRIPTION",
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
              ),
            ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect!
                ? "WONDERFUL!"
                : "NEED MORE DETAIL!",
            subtitle: quest.sampleAnswer ?? "Description recognized.",
            onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
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

  Widget _buildHintButton(bool used, WritingQuest quest, Color primaryColor) {
    return ScaleButton(
      onTap: used
          ? null
          : () {
              context.read<WritingBloc>().add(WritingHintUsed());
              _useHint(quest);
            },
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
