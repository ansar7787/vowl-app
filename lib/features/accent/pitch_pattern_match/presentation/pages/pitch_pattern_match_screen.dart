import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/games/premium_game_widgets.dart';
import 'package:voxai_quest/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_feedback_panel.dart';

class PitchPatternMatchScreen extends StatefulWidget {
  final int level;
  const PitchPatternMatchScreen({super.key, required this.level});

  @override
  State<PitchPatternMatchScreen> createState() =>
      _PitchPatternMatchScreenState();
}

class _PitchPatternMatchScreenState extends State<PitchPatternMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  bool _isPlaying = false;
  bool _showConfetti = false;

  bool _hasSubmitted = false;
  int? _selectedOptionIndex;
  final Set<int> _eliminatedIndices = {};
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.pitchPatternMatch,
        level: widget.level,
      ),
    );
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    // Removed _soundService.playClick() to prevent double sound
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _checkAnswer(int index, AccentQuest quest) {
    if (_hasSubmitted || _eliminatedIndices.contains(index)) return;

    setState(() {
      _selectedOptionIndex = index;
    });

    bool isCorrect = false;
    if (quest.correctAnswerIndex != null) {
      isCorrect = (index == quest.correctAnswerIndex);
    } else if (quest.correctAnswer != null && quest.options != null) {
      isCorrect = (quest.options![index] == quest.correctAnswer);
    } else {
      isCorrect = (index == 0); // Fallback
    }

    if (isCorrect) {
      setState(() => _hasSubmitted = true);
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) context.read<AccentBloc>().add(NextQuestion());
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() => _hasSubmitted = false);
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed) {
      _hapticService.error();
      return;
    }
    _hapticService.selection();
    _soundService.playHint();

    final options = quest.options ?? ['Rising', 'Falling', 'Flat'];

    int? wrongOriginalIndex;
    for (int i = 0; i < options.length; i++) {
      bool isMatch = false;
      if (quest.correctAnswerIndex != null) {
        isMatch = (i == quest.correctAnswerIndex);
      } else if (quest.correctAnswer != null) {
        isMatch = (options[i] == quest.correctAnswer);
      } else {
        isMatch = (i == 0);
      }

      if (!isMatch && !_eliminatedIndices.contains(i)) {
        wrongOriginalIndex = i;
        break;
      }
    }

    if (wrongOriginalIndex != null) {
      setState(() => _eliminatedIndices.add(wrongOriginalIndex!));
    }
    context.read<AccentBloc>().add(AccentHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'accent',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<AccentBloc, AccentState>(
        listener: (context, state) {
          if (state is AccentGameComplete) {
            setState(() => _showConfetti = true);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VictoryScreen(
                  xp: state.xpEarned,
                  coins: state.coinsEarned,
                  category: 'accent',
                  gameType: 'pitchPatternMatch',
                  level: widget.level,
                  title: 'PITCH PRODIGY!',
                  description:
                      'Your melodic accuracy is incredible. You matched every pitch pattern!',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Off Key',
              description: 'The pitch was a bit flat. Try to sing the words!',
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            // Verification: Only process if state matches current game and level
            if (state.gameType == GameSubtype.pitchPatternMatch &&
                state.level == widget.level) {
              if (_lastLoadedState?.currentQuest != state.currentQuest) {
                _lastLoadedState = state;
                if (state.lastAnswerCorrect == null) {
                  setState(() {
                    _hasSubmitted = false;
                    _selectedOptionIndex = null;
                    _eliminatedIndices.clear();
                  });
                }
              }
            }
          }
        },
        builder: (context, state) {
          final bool isStale =
              state is AccentLoaded &&
              (state.gameType != GameSubtype.pitchPatternMatch ||
                  state.level != widget.level);

          if (state is AccentLoading ||
              (state is AccentInitial && _lastLoadedState == null) ||
              isStale) {
            return const GameShimmerLoading();
          }

          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<AccentBloc>().add(
                FetchAccentQuests(
                  gameType: GameSubtype.pitchPatternMatch,
                  level: widget.level,
                ),
              ),
            );
          }

          if (state is AccentLoaded || state is AccentGameComplete) {
            final displayState = state is AccentLoaded
                ? state
                : (state as AccentGameComplete).lastState;
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                RepaintBoundary(
                  child: HarmonicWaves(color: theme.primaryColor, height: 100),
                ),
                _buildGameUI(context, displayState, isDark, theme),
                if (_showConfetti) const GameConfetti(),
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
    AccentLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              PremiumGameHeader(
                progress: progress,
                lives: state.livesRemaining,
                hintCount: state.hintUsed ? null : 1,
                onHint: () => _useHint(state, quest),
                onClose: () => context.pop(),
                isDark: isDark,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "PITCH PATTERN MATCH",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Listen and match the rhythm",
                        style: GoogleFonts.outfit(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      SizedBox(height: 40.h),

                      // Media Playback Card
                      GlassTile(
                        padding: EdgeInsets.all(32.r),
                        borderRadius: BorderRadius.circular(40.r),
                        borderColor: theme.primaryColor.withValues(alpha: 0.3),
                        child: Column(
                          children: [
                            _buildPitchCurve(theme.primaryColor),
                            SizedBox(height: 24.h),
                            Text(
                              quest.textToSpeak ?? "Listen...",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              quest.instruction,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            ScaleButton(
                              onTap: () => _playAudio(quest.textToSpeak ?? ""),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 16.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor.withValues(alpha: 0.9),
                                      theme.primaryColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isPlaying)
                                      const HarmonicWaves(
                                        color: Colors.white,
                                        height: 30,
                                        width: 40,
                                      ).animate().fadeIn()
                                    else
                                      Icon(
                                        Icons.volume_up_rounded,
                                        color: Colors.white,
                                        size: 28.r,
                                      ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "LISTEN",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),

                      SizedBox(height: 48.h),

                      // Mood Canvas Grid
                      _buildMoodCanvases(quest, isDark, theme),

                      if (_hasSubmitted && state.lastAnswerCorrect != null) ...[
                        SizedBox(height: 48.h),
                        PitchPatternFeedbackPanel(
                          isCorrect: state.lastAnswerCorrect!,
                          correctPattern:
                              quest.options?[quest.correctAnswerIndex ?? 0] ??
                              'Pattern',
                          hint: quest.hint ?? 'Review the sentence intonation.',
                          onListenAgain: () =>
                              _playAudio(quest.textToSpeak ?? ""),
                          isDark: isDark,
                        ),
                      ],

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showConfetti) const GameConfetti(),
        ],
      ),
    );
  }

  Widget _buildMoodCanvases(AccentQuest quest, bool isDark, ThemeResult theme) {
    final options = quest.options ?? ['Rising', 'Falling', 'Flat'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: options.length > 2 ? 2 : 1,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: options.length > 2 ? 1.4 : 2.5,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _selectedOptionIndex == index;
        final isEliminated = _eliminatedIndices.contains(index);

        bool isCorrect = false;
        if (_hasSubmitted) {
          if (quest.correctAnswerIndex != null) {
            isCorrect = index == quest.correctAnswerIndex;
          } else if (quest.correctAnswer != null) {
            isCorrect = options[index] == quest.correctAnswer;
          } else {
            isCorrect = index == 0;
          }
        }

        Color canvasColor = theme.primaryColor;
        if (isEliminated) {
          canvasColor = isDark ? Colors.white10 : Colors.black12;
        } else if (_hasSubmitted) {
          if (isCorrect) {
            canvasColor = Colors.greenAccent;
          } else if (isSelected) {
            canvasColor = Colors.redAccent;
          } else {
            canvasColor = isDark ? Colors.white12 : Colors.black12;
          }
        }

        return ScaleButton(
          onTap: isEliminated || _hasSubmitted
              ? null
              : () => _checkAnswer(index, quest),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isEliminated
                  ? Colors.transparent
                  : isSelected
                  ? canvasColor.withValues(alpha: 0.15)
                  : canvasColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isEliminated
                    ? Colors.transparent
                    : isSelected || (isCorrect && _hasSubmitted)
                    ? canvasColor
                    : canvasColor.withValues(alpha: 0.3),
                width: isSelected || (isCorrect && _hasSubmitted) ? 3 : 2,
              ),
              boxShadow: [
                if (isSelected || (isCorrect && _hasSubmitted))
                  BoxShadow(
                    color: canvasColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getMoodIcon(
                  option,
                  canvasColor,
                  isSelected,
                  isCorrect && _hasSubmitted,
                ),
                SizedBox(height: 12.h),
                Text(
                  option,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: isEliminated
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : (isSelected || (isCorrect && _hasSubmitted)) && isDark
                        ? canvasColor
                        : (isSelected || (isCorrect && _hasSubmitted)) &&
                              !isDark
                        ? Colors.black87
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (200 + index * 100).ms).fadeIn().scale();
      },
    );
  }

  Widget _getMoodIcon(
    String option,
    Color color,
    bool isSelected,
    bool isCorrect,
  ) {
    IconData iconData;
    final lowerOption = option.toLowerCase();

    if (lowerOption.contains('rising')) {
      iconData = Icons.trending_up_rounded;
    } else if (lowerOption.contains('falling')) {
      iconData = Icons.trending_down_rounded;
    } else if (lowerOption.contains('flat') ||
        lowerOption.contains('neutral')) {
      iconData = Icons.trending_flat_rounded;
    } else {
      iconData = Icons.gesture_rounded; // Generic wave/pattern
    }

    Widget icon = Icon(iconData, color: color, size: 32.r);

    if (isSelected || isCorrect) {
      icon = icon
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .slideX(begin: -0.1, end: 0.1, duration: 800.ms)
          .shimmer(color: Colors.white.withValues(alpha: 0.5));
    }

    return icon;
  }

  Widget _buildPitchCurve(Color color) {
    return RepaintBoundary(
      child: SizedBox(
        height: 60.h,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(8, (index) {
            final height = (index % 3 + 1) * 15.0;
            return Container(
                  width: 8.w,
                  height: height.h,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3 + (index * 0.07)),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleY(
                  begin: 0.5,
                  end: 1.5,
                  duration: Duration(milliseconds: 600 + (index * 120)),
                );
          }),
        ),
      ),
    );
  }
}
