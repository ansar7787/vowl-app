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

class AudioFillBlanksScreen extends StatefulWidget {
  final int level;
  const AudioFillBlanksScreen({super.key, required this.level});

  @override
  State<AudioFillBlanksScreen> createState() => _AudioFillBlanksScreenState();
}

class _AudioFillBlanksScreenState extends State<AudioFillBlanksScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  final _answerController = TextEditingController();
  bool _isPlaying = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(
        gameType: GameSubtype.audioFillBlanks,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _speechService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _submitAnswer(String correctAnswer) {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final isCorrect = userAnswer == correctAnswer.toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

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
            _answerController.clear();
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
                  gameType: GameSubtype.audioFillBlanks,
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
                        "FILL THE BLANK",
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
                      SizedBox(height: 40.h),
                      _buildAudioPlayer(
                        quest.transcript ??
                            quest.audioTranscript ??
                            "The quick brown fox jumps over the lazy dog.",
                        theme,
                      ),
                      SizedBox(height: 40.h),
                      _buildInputSection(theme, isDark),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(quest.correctAnswer ?? "", theme),
              SizedBox(height: 40.h),
            ],
          ),
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "SPOT ON!" : "ALMOST THERE!",
            subtitle: "Listening is half the conversation.",
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
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isPlaying)
                SizedBox(
                  width: 120.r,
                  height: 120.r,
                  child: SoundWave(color: theme.primaryColor),
                ),
              ScaleButton(
                onTap: () => _playAudio(transcript),
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            "PLAY AUDIO",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildInputSection(ThemeResult theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TYPE MISSING WORD",
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: 12.h),
        GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          borderRadius: BorderRadius.circular(20.r),
          child: TextField(
            controller: _answerController,
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "What did you hear?",
              hintStyle: GoogleFonts.outfit(color: Colors.white30),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String correctAnswer, ThemeResult theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: ScaleButton(
        onTap: () => _submitAnswer(correctAnswer),
        child: Container(
          width: double.infinity,
          height: 64.h,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "VERIFY ANSWER",
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
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

  void _showCompletionDialog(BuildContext context, int xp, int coins) {
    _hapticService.success();
    _soundService.playLevelComplete();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernGameDialog(
        title: "AUDITORY ACE!",
        description:
            "Your focus is remarkable. Earned $xp XP and $coins coins.",
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
        title: "OUT OF SYNC",
        description: "Misheard a few? Practice makes perfect. Try again!",
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
