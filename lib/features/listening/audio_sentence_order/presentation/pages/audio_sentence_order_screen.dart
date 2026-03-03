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

class AudioSentenceOrderScreen extends StatefulWidget {
  final int level;
  const AudioSentenceOrderScreen({super.key, required this.level});

  @override
  State<AudioSentenceOrderScreen> createState() =>
      _AudioSentenceOrderScreenState();
}

class _AudioSentenceOrderScreenState extends State<AudioSentenceOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  List<String> _shuffledSentences = [];
  bool _isPlaying = false;
  bool _showConfetti = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(
        gameType: GameSubtype.audioSentenceOrder,
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

  void _submitAnswer(List<String> correctOrder) {
    bool isCorrect = true;
    for (int i = 0; i < correctOrder.length; i++) {
      if (_shuffledSentences[i] != correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

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
            final quest = state.currentQuest;
            _shuffledSentences = List.from(quest.options ?? []);
            if (!_hasStarted) {
              _shuffledSentences.shuffle();
              _hasStarted = true;
            }
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
                  gameType: GameSubtype.audioSentenceOrder,
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "SENTENCE ORDER",
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
                        quest.transcript ?? "Listen and arrange the sentences.",
                        theme,
                      ),
                      SizedBox(height: 30.h),
                      Expanded(child: _buildReorderableList(theme, isDark)),
                      SizedBox(height: 20.h),
                      _buildSubmitButton(quest.options ?? [], theme),
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
            title: state.lastAnswerCorrect! ? "PERFECT ORDER!" : "RE-ARRANGE!",
            subtitle: "Structure is the key to clarity.",
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
              _isPlaying ? "PLAYING SEQUENCE..." : "LISTEN TO SEQUENCE",
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

  Widget _buildReorderableList(ThemeResult theme, bool isDark) {
    return ReorderableListView.builder(
      itemCount: _shuffledSentences.length,
      padding: EdgeInsets.only(bottom: 20.h),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _shuffledSentences.removeAt(oldIndex);
          _shuffledSentences.insert(newIndex, item);
        });
        _hapticService.selection();
      },
      itemBuilder: (context, index) {
        return _buildSentenceTile(
          index,
          _shuffledSentences[index],
          theme,
          isDark,
        );
      },
    );
  }

  Widget _buildSentenceTile(
    int index,
    String text,
    ThemeResult theme,
    bool isDark,
  ) {
    return Padding(
      key: ValueKey(text),
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        borderRadius: BorderRadius.circular(20.r),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
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
            Icon(
              Icons.drag_indicator_rounded,
              color: Colors.white24,
              size: 24.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(List<String> correctOrder, ThemeResult theme) {
    return ScaleButton(
      onTap: () => _submitAnswer(correctOrder),
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
            "COMPLETED ORDER",
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
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
        title: "LOGICAL LISTENER!",
        description:
            "Your structural awareness is elite. Earned $xp XP and $coins coins.",
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
        title: "SEQUENCE BROKEN",
        description: "The order seems a bit scrambled. Ready to try again?",
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
