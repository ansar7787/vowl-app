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
import 'package:voxai_quest/core/presentation/widgets/roleplay/cinema_light.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/roleplay/presentation/bloc/roleplay_bloc.dart';

class SituationalResponseScreen extends StatefulWidget {
  final int level;
  const SituationalResponseScreen({super.key, required this.level});

  @override
  State<SituationalResponseScreen> createState() =>
      _SituationalResponseScreenState();
}

class _SituationalResponseScreenState extends State<SituationalResponseScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  bool _isPlaying = false;
  bool _showConfetti = false;
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(
        gameType: GameSubtype.situationalResponse,
        level: widget.level,
      ),
    );
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onOptionSelected(int index) {
    if (_selectedOptionIndex != null) return;
    _hapticService.selection();
    setState(() => _selectedOptionIndex = index);

    final state = context.read<RoleplayBloc>().state;
    if (state is RoleplayLoaded) {
      // Logic: Option at index 0 is best response in our mock setup
      final isCorrect = index == 0;

      if (isCorrect) {
        _soundService.playCorrect();
        _hapticService.success();
      } else {
        _soundService.playWrong();
        _hapticService.error();
      }
      context.read<RoleplayBloc>().add(SubmitAnswer(isCorrect));
    }
  }

  void _useHint() {
    _hapticService.selection();
    context.read<RoleplayBloc>().add(RoleplayHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<RoleplayBloc, RoleplayState>(
        listener: (context, state) {
          if (state is RoleplayGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Scenario Cleared!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for navigating the situation!',
        ),
            );
          } else if (state is RoleplayGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Social Setback',
        description: 'Take a breath and try to re-evaluate the conversation!',
        onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
      );
          } else if (state is RoleplayLoaded &&
              state.lastAnswerCorrect == null) {
            _selectedOptionIndex = null;
          }
        },
        builder: (context, state) {
          if (state is RoleplayLoading || state is RoleplayInitial) {
            return const GameShimmerLoading();
          }
          if (state is RoleplayLoaded) {
            final theme = LevelThemeHelper.getTheme(
              'roleplay',
              level: widget.level,
            );
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                CinemaLight(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is RoleplayError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<RoleplayBloc>().add(
                FetchRoleplayQuests(
                  gameType: GameSubtype.situationalResponse,
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
    RoleplayLoaded state,
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
                    SizedBox(height: 30.h),

                    // Character & Scenario Section
                    GlassTile(
                      padding: EdgeInsets.all(32.r),
                      borderRadius: BorderRadius.circular(40.r),
                      borderColor: theme.primaryColor.withValues(alpha: 0.3),
                      color: isDark
                          ? theme.primaryColor.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.5),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withValues(alpha: 0.2),
                                  theme.primaryColor.withValues(alpha: 0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 48.r,
                              color: theme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            quest.roleName ?? "Professional Advisor",
                            style: GoogleFonts.outfit(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: theme.primaryColor,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            quest.scenario ??
                                "You are in a high-stakes meeting and need to disagree politely.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                    SizedBox(height: 40.h),

                    // Interaction Card
                    GlassTile(
                      padding: EdgeInsets.all(32.r),
                      borderRadius: BorderRadius.circular(32.r),
                      borderColor: theme.primaryColor.withValues(alpha: 0.2),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleButton(
                                onTap: () => _playAudio(quest.instruction),
                                child: Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.volume_up_rounded
                                        : Icons.play_circle_fill_rounded,
                                    size: 32.r,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Text(
                                  quest.instruction,
                                  style: GoogleFonts.outfit(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),
                          ...List.generate(quest.options?.length ?? 0, (index) {
                            return _buildOptionCard(
                              quest.options![index],
                              index,
                              isDark,
                              theme.primaryColor,
                            );
                          }),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

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
                ? "PERFECTLY POLITE!"
                : "TRY ANOTHER WAY!",
            subtitle: "Key Response: ${quest.options?[0] ?? ""}",
            onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildOptionCard(
    String text,
    int index,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == 0; // Best response is at 0 in mock
    final showResult = _selectedOptionIndex != null;

    Color? cardColor;
    if (showResult) {
      if (isCorrect) {
        cardColor = const Color(0xFF10B981);
      } else if (isSelected) {
        cardColor = const Color(0xFFF43F5E);
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ScaleButton(
        onTap: () => _onOptionSelected(index),
        child: GlassTile(
          borderRadius: BorderRadius.circular(20.r),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          color: cardColor?.withValues(alpha: 0.8),
          borderColor: (isSelected && showResult
              ? Colors.white.withValues(alpha: 0.5)
              : (isSelected
                    ? primaryColor
                    : primaryColor.withValues(alpha: 0.1))),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isSelected
                          ? Colors.white24
                          : primaryColor.withValues(alpha: 0.1),
                      isSelected
                          ? Colors.white10
                          : primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white24
                        : primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF1E293B)),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (showResult && isCorrect)
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24.r,
                ),
            ],
          ),
        ),
      ),
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
