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
import 'package:voxai_quest/core/presentation/widgets/games/premium_game_widgets.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/accent/speed_variance/presentation/widgets/connected_speech_feedback_panel.dart';

class SpeedVarianceScreen extends StatefulWidget {
  final int level;
  const SpeedVarianceScreen({super.key, required this.level});

  @override
  State<SpeedVarianceScreen> createState() => _SpeedVarianceScreenState();
}

class _SpeedVarianceScreenState extends State<SpeedVarianceScreen> {
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
        gameType: GameSubtype.speedVariance,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _playAudio(String text, {double rate = 0.5}) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text, rate: rate);
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

    final options = quest.options ?? ['Slow', 'Normal', 'Fast'];

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
                  gameType: 'speedVariance',
                  level: widget.level,
                  title: 'TEMPO TITAN!',
                  description:
                      'Your timing and control are perfect. You mastered the rhythm!',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Timing Error',
              description: 'The pace was off. Try to match the target speed!',
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            // Verification: Only process if state matches current game and level
            if (state.gameType == GameSubtype.speedVariance &&
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
              (state.gameType != GameSubtype.speedVariance ||
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
                  gameType: GameSubtype.speedVariance,
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
                        "SPEED VARIANCE",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Match the target tempo",
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
                            _buildSpeedIndicator(theme.primaryColor),
                            SizedBox(height: 32.h),
                            Text(
                              quest.textToSpeak ?? "Transmission incoming",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 24.sp,
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
                            // Standard Playback Button
                            ScaleButton(
                              onTap: () => _playAudio(quest.textToSpeak ?? ""),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
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
                                        size: 24.r,
                                      ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "LISTEN",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.sp,
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

                      // Spy Decoder Options
                      _buildDecoderOptions(quest, isDark, theme),

                      if (_hasSubmitted && state.lastAnswerCorrect != null) ...[
                        SizedBox(height: 48.h),
                        ConnectedSpeechFeedbackPanel(
                          isCorrect: state.lastAnswerCorrect!,
                          fastForm: quest.textToSpeak ?? "Fast",
                          slowForm: quest.slowForm ?? "Slow",
                          hint:
                              quest.hint ??
                              'Words blend together in fast speech.',
                          onPlayAudio: (text, {rate = 0.5}) =>
                              _playAudio(text, rate: rate),
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
        ],
      ),
    );
  }

  Widget _buildDecoderOptions(
    AccentQuest quest,
    bool isDark,
    ThemeResult theme,
  ) {
    final options =
        quest.options ?? ['Fast casual speech', 'Careful slow speech'];

    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = _selectedOptionIndex == index;

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

        final isEliminated = _eliminatedIndices.contains(index);

        final bgColor = isEliminated
            ? (isDark ? Colors.white12 : Colors.black12)
            : _hasSubmitted
            ? (isCorrect
                  ? Colors.greenAccent
                  : (isSelected
                        ? Colors.redAccent
                        : (isDark ? Colors.white12 : Colors.black12)))
            : theme.primaryColor;

        IconData speedIcon;
        if (option.toLowerCase().contains('fast') ||
            option.toLowerCase().contains('quick')) {
          speedIcon = Icons.fast_forward_rounded;
        } else if (option.toLowerCase().contains('slow') ||
            option.toLowerCase().contains('leisure')) {
          speedIcon = Icons.fast_rewind_rounded;
        } else {
          speedIcon = Icons.play_arrow_rounded;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ScaleButton(
            onTap: () => _checkAnswer(index, quest),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: isEliminated
                    ? Colors.transparent
                    : isSelected
                    ? bgColor.withValues(alpha: 0.15)
                    : bgColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isEliminated
                      ? Colors.transparent
                      : isSelected || (isCorrect && _hasSubmitted)
                      ? bgColor
                      : bgColor.withValues(alpha: 0.3),
                  width: isSelected || (isCorrect && _hasSubmitted) ? 3 : 2,
                ),
                boxShadow: [
                  if (isSelected || (isCorrect && _hasSubmitted))
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      speedIcon,
                      color: isEliminated
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : bgColor,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Text(
                      option.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isEliminated
                            ? (isDark ? Colors.white24 : Colors.black26)
                            : (isDark ? Colors.white : Colors.black87),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (_hasSubmitted && isCorrect) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 28.r,
                    ).animate().scale().shake(),
                  ],
                  if (isSelected && !isCorrect) ...[
                    Icon(
                      Icons.cancel_rounded,
                      color: Colors.redAccent,
                      size: 28.r,
                    ).animate().scale().shake(),
                  ],
                ],
              ),
            ),
          ),
        ).animate(delay: (200 + index * 100).ms).slideX(begin: 0.2).fadeIn();
      }),
    );
  }

  Widget _buildSpeedIndicator(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, color: color, size: 24.r),
          SizedBox(width: 8.w),
          Text(
            "VARIANCE MODE",
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14.sp,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds);
  }
}
