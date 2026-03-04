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
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
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

class EmotionRecognitionScreen extends StatefulWidget {
  final int level;
  const EmotionRecognitionScreen({super.key, required this.level});

  @override
  State<EmotionRecognitionScreen> createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> {
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
        gameType: GameSubtype.emotionRecognition,
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

  String _getEmojiForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'surprised':
        return '😲';
      case 'fearful':
        return '😨';
      case 'disgusted':
        return '🤢';
      case 'neutral':
        return '😐';
      default:
        return '🎭';
    }
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
            GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'EMOTIONALLY INTELLIGENT!',
          description:
              'Youve mastered the art of hearing feelings. Earned ${state.xpEarned} XP and ${state.coinsEarned} coins.',
        );
          } else if (state is ListeningGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'MISUNDERSTOOD',
        description: 'Emotions are complex. Ready to listen again?',
        onRestore: () => context.read<ListeningBloc>().add(RestoreLife()),
      );
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
                  gameType: GameSubtype.emotionRecognition,
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
                      SizedBox(height: 10.h),
                      Text(
                        "EMOTION RADAR",
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
                      _buildAudioVisualizer(
                        quest.transcript ?? "Detect the emotion in the voice.",
                        theme,
                      ),
                      SizedBox(height: 30.h),
                      _buildEmotionGrid(
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
            title: state.lastAnswerCorrect! ? "EMPATHY EXPERT!" : "TONE DEAF?",
            subtitle: "Emotions are the colors of speech.",
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

  Widget _buildAudioVisualizer(String transcript, ThemeResult theme) {
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
            _isPlaying ? "CAPTURING VIBRATIONS..." : "PLAY VOICE CLIP",
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

  Widget _buildEmotionGrid(
    List<String> options,
    int correctIndex,
    ThemeResult theme,
    bool isDark,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.r,
        mainAxisSpacing: 16.r,
        childAspectRatio: 0.9,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildEmotionCard(
          index,
          options[index],
          correctIndex,
          theme,
          isDark,
        );
      },
    );
  }

  Widget _buildEmotionCard(
    int index,
    String text,
    int correctIndex,
    ThemeResult theme,
    bool isDark,
  ) {
    final isSelected = _selectedOptionIndex == index;
    final emoji = _getEmojiForEmotion(text);

    return ScaleButton(
          onTap: () => _onOptionTap(index, correctIndex),
          child: GlassTile(
            padding: EdgeInsets.all(16.r),
            borderRadius: BorderRadius.circular(24.r),
            borderColor: isSelected ? theme.primaryColor : Colors.white12,
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.1)
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: 40.sp)),
                SizedBox(height: 12.h),
                Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 100).ms)
        .scale(begin: const Offset(0.8, 0.8));
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

  

  
}
