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
import 'package:voxai_quest/core/presentation/widgets/listening/sound_wave.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_result_overlay.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';

class DetailSpotlightScreen extends StatefulWidget {
  final int level;
  const DetailSpotlightScreen({super.key, required this.level});

  @override
  State<DetailSpotlightScreen> createState() => _DetailSpotlightScreenState();
}

class _DetailSpotlightScreenState extends State<DetailSpotlightScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  int? _selectedOptionIndex;
  bool _isPlaying = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(
        gameType: GameSubtype.detailSpotlight,
        level: widget.level,
      ),
    );
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _speechService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onOptionTap(int index, int correctIndex) {
    if (_selectedOptionIndex != null) return;
    _hapticService.selection();
    setState(() => _selectedOptionIndex = index);

    final isCorrect = index == correctIndex;
    context.read<ListeningBloc>().add(SubmitAnswer(isCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'listening',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<ListeningBloc, ListeningState>(
        listener: (context, state) {
          if (state is ListeningGameComplete) {
            setState(() => _showConfetti = true);
            _showCompletionDialog(context, state.xpEarned, state.coinsEarned);
          } else if (state is ListeningGameOver) {
            _showGameOverDialog(context);
          } else if (state is ListeningLoaded &&
              state.lastAnswerCorrect == null) {
            setState(() => _selectedOptionIndex = null);
          }
        },
        builder: (context, state) {
          if (state is ListeningLoading || state is ListeningInitial) {
            return const GameShimmerLoading();
          }

          if (state is ListeningError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<ListeningBloc>().add(
                FetchListeningQuests(
                  gameType: GameSubtype.detailSpotlight,
                  level: widget.level,
                ),
              ),
            );
          }
          if (state is ListeningLoaded) {
            return Stack(
              children: [
                const MeshGradientBackground(),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    BuildContext context,
    ListeningLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              _buildHeader(context, state, progress, theme, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "DETAIL SPOTLIGHT",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        quest.instruction,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      SizedBox(height: 30.h),
                      _buildAudioPlayer(
                        quest.transcript ??
                            "Listen carefully for specific details.",
                        theme,
                      ),
                      SizedBox(height: 40.h),
                      _buildOptionsGrid(
                        quest.options ?? [],
                        quest.correctAnswerIndex ?? 0,
                        theme,
                        isDark,
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "SHARP EARS!" : "MISSED DETAIL!",
            subtitle: "Excellence is in the details.",
            onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ListeningLoaded state,
    double progress,
    ThemeResult theme,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
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
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _buildHeartCount(state.livesRemaining),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(String transcript, ThemeResult theme) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isPlaying)
                SizedBox(
                  width: 60.r,
                  height: 60.r,
                  child: SoundWave(color: theme.primaryColor),
                ),
              ScaleButton(
                onTap: () => _playAudio(transcript),
                child: Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              _isPlaying ? "ANALYZING AUDIO..." : "HEAR FULL CONTEXT",
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildOptionsGrid(
    List<String> options,
    int correctIndex,
    ThemeResult theme,
    bool isDark,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisExtent: 80.h,
        mainAxisSpacing: 16.h,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildOptionTile(
          index,
          options[index],
          correctIndex,
          theme,
          isDark,
        );
      },
    );
  }

  Widget _buildOptionTile(
    int index,
    String text,
    int correctIndex,
    ThemeResult theme,
    bool isDark,
  ) {
    final isSelected = _selectedOptionIndex == index;

    return ScaleButton(
      onTap: () => _onOptionTap(index, correctIndex),
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        borderRadius: BorderRadius.circular(20.r),
        borderColor: isSelected ? theme.primaryColor : Colors.white12,
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor
                    : (isDark ? Colors.white10 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
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
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.primaryColor,
                size: 24.r,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2);
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

  void _showCompletionDialog(BuildContext context, int xp, int coins) {
    _hapticService.success();
    _soundService.playLevelComplete();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernGameDialog(
        title: "PRECISION LISTENER!",
        description:
            "Your attention to detail is remarkable. Earned $xp XP and $coins coins.",
        buttonText: "CONTINUE",
        onButtonPressed: () {
          Navigator.pop(context);
          context.pop();
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
        title: "OUT OF FOCUS",
        description:
            "The small details matter most. Ready to sharpen your focus?",
        isSuccess: false,
        isRescueLife: true,
        buttonText: 'GIVE UP',
        onButtonPressed: () {
          Navigator.pop(context);
          context.pop();
        },
        onAdAction: () {
          void restoreLife() {
            context.read<ListeningBloc>().add(RestoreLife());
            Navigator.pop(context);
          }

          final isPremium =
              context.read<AuthBloc>().state.user?.isPremium ?? false;
          if (isPremium) {
            restoreLife();
          } else {
            di.sl<AdService>().showRewardedAd(
              isPremium: false,
              onUserEarnedReward: (_) => restoreLife(),
              onDismissed: () {},
            );
          }
        },
        adButtonText: 'WATCH AD TO CONTINUE',
      ),
    );
  }
}
