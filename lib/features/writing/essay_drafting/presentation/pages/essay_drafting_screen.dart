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
import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_result_overlay.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/writing/domain/entities/writing_quest.dart';
import 'package:voxai_quest/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/games/premium_game_widgets.dart';

class EssayDraftingScreen extends StatefulWidget {
  final int level;
  const EssayDraftingScreen({super.key, required this.level});

  @override
  State<EssayDraftingScreen> createState() => _EssayDraftingScreenState();
}

class _EssayDraftingScreenState extends State<EssayDraftingScreen> {
  final TextEditingController _controller = TextEditingController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _hasSubmitted = false;
  bool _showConfetti = false;

  final List<String> _segments = [
    "Introduction",
    "Main Argument",
    "Conclusion",
  ];
  int _activeSegment = 0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(
        gameType: GameSubtype.essayDrafting,
        level: widget.level,
      ),
    );
    // Pre-load ads
    di.sl<AdService>().loadRewardedAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (_hasSubmitted || _controller.text.trim().isEmpty) return;
    _hapticService.selection();
    setState(() => _hasSubmitted = true);

    final text = _controller.text.trim();
    // Validate: At least 50 chars for a "Master Draft"
    bool isCorrect = text.length >= 50;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      GameSubtype.essayDrafting.name,
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<WritingBloc, WritingState>(
        listener: (context, state) {
          if (state is WritingGameComplete) {
            setState(() => _showConfetti = true);
            _showCompletionDialog(context, state.xpEarned, state.coinsEarned);
          } else if (state is WritingGameOver) {
            _showGameOverDialog(context);
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

          if (state is WritingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<WritingBloc>().add(
                FetchWritingQuests(
                  gameType: GameSubtype.essayDrafting,
                  level: widget.level,
                ),
              ),
            );
          }

          if (state is WritingLoaded) {
            final WritingQuest quest = state.currentQuest;
            final progress = (state.currentIndex + 1) / state.quests.length;

            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                Column(
                  children: [
                    SizedBox(height: 50.h),
                    PremiumGameHeader(
                      progress: progress,
                      lives: state.livesRemaining,
                      onHint: () {
                        context.read<WritingBloc>().add(WritingHintUsed());
                        _controller.text =
                            "Regarding ${quest.prompt ?? 'this topic'}, it is evident that ${quest.requiredPoints?.first ?? 'several factors play a key role'}...";
                      },
                      onClose: () => context.pop(),
                      isDark: isDark,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 10.h),
                            Text(
                              "MASTER DRAFT",
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: theme.primaryColor,
                              ),
                            ).animate().fadeIn(),
                            SizedBox(height: 8.h),
                            Text(
                                  quest.instruction.isNotEmpty
                                      ? quest.instruction
                                      : "Construct your literary masterpiece.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.1),
                            SizedBox(height: 32.h),

                            _buildPromptCard(
                              quest.prompt ?? 'Construct your essay.',
                              quest.requiredPoints,
                              theme,
                              isDark,
                            ),

                            SizedBox(height: 24.h),

                            _buildSegmentSelector(theme, isDark),

                            SizedBox(height: 16.h),

                            _buildInputArea(theme, isDark),

                            SizedBox(height: 48.h),

                            if (!_hasSubmitted)
                              ScaleButton(
                                    onTap: _submitAnswer,
                                    child: Container(
                                      width: double.infinity,
                                      height: 64.h,
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(
                                          24.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "FINALIZE DRAFT",
                                          style: GoogleFonts.outfit(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 800.ms)
                                  .slideY(begin: 0.1),

                            SizedBox(height: 40.h),
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
                        ? "DRAFT APPROVED!"
                        : "CONTENT INSUFFICIENT!",
                    subtitle:
                        "Sample: ${quest.sampleAnswer ?? 'Your essay structure is solid.'}",
                    onContinue: () =>
                        context.read<WritingBloc>().add(NextQuestion()),
                    primaryColor: theme.primaryColor,
                  ),
                if (_showConfetti) const GameConfetti(),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPromptCard(
    String topic,
    List<String>? mainPoints,
    ThemeResult theme,
    bool isDark,
  ) {
    return GlassTile(
      padding: EdgeInsets.all(28.r),
      borderRadius: BorderRadius.circular(36.r),
      borderColor: theme.primaryColor.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_document, color: theme.primaryColor, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                "THESIS PROMPT",
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
          Text(
            topic,
            textAlign: TextAlign.center,
            style: GoogleFonts.spectral(
              fontSize: 18.sp,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
            ),
          ),
          if (mainPoints != null && mainPoints.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: mainPoints
                  .map(
                    (point) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        point,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSegmentSelector(ThemeResult theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _segments.asMap().entries.map((entry) {
          final isSelected = _activeSegment == entry.key;
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () {
                _hapticService.light();
                setState(() => _activeSegment = entry.key);
              },
              child: AnimatedContainer(
                duration: 300.ms,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? Colors.white24 : Colors.transparent,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildInputArea(ThemeResult theme, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(8.r),
      borderRadius: BorderRadius.circular(28.r),
      borderColor: theme.primaryColor.withValues(alpha: 0.1),
      child: TextField(
        controller: _controller,
        enabled: !_hasSubmitted,
        maxLines: 12,
        style: GoogleFonts.spectral(
          fontSize: 17.sp,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText:
              "Elaborate on your ${_segments[_activeSegment].toLowerCase()}...",
          hintStyle: GoogleFonts.spectral(
            color: isDark ? Colors.white24 : Colors.black26,
            fontStyle: FontStyle.italic,
          ),
          contentPadding: EdgeInsets.all(24.r),
          border: InputBorder.none,
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05);
  }

  void _showCompletionDialog(BuildContext context, int xp, int coins) {
    _hapticService.success();
    _soundService.playLevelComplete();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernGameDialog(
        title: "LITERARY TRIUMPH!",
        description:
            "You've earned $xp XP and $coins coins. Your essay drafting skills are ready for publication!",
        buttonText: "CONTINUE",
        onButtonPressed: () {
          Navigator.pop(context);
          context.pop();
        },
        onAdAction: () {
          Navigator.pop(context);
          final isPremium =
              context.read<AuthBloc>().state.user?.isPremium ?? false;
          final adService = di.sl<AdService>();
          adService.showRewardedAd(
            isPremium: isPremium,
            onUserEarnedReward: (reward) {
              // Dispatch Double Up Event
              context.read<AuthBloc>().add(
                AuthDoubleUpRewardsRequested(xp, coins),
              );
              // Show Success SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("REWARDS DOUBLED! 💎💎"),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            onDismissed: () {
              context.pop();
            },
          );
        },
      ),
    );
  }

  void _showGameOverDialog(BuildContext context) {
    _hapticService.error();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernGameDialog(
        title: "WRITER'S BLOCK",
        description:
            "The draft was incomplete or lacked substance. Want to revisit your thesis?",
        buttonText: "RETRY",
        isSuccess: false,
        onButtonPressed: () {
          Navigator.pop(context);
          context.read<WritingBloc>().add(RestartLevel());
        },
        secondaryButtonText: "EXIT",
        onSecondaryPressed: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }
}
