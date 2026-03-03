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
import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:confetti/confetti.dart';

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  const MinimalPairsScreen({super.key, required this.level});

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  int? _selectedWordIndex;
  final List<int> _eliminatedIndices = [];
  bool _isPlaying = false;
  bool _showConfetti = false;

  late ConfettiController _confettiController;
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.minimalPairs,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    // Removed _soundService.playClick() as it was causing double sound
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onWordSelected(int index, String targetWord) {
    if (_selectedWordIndex != null || _eliminatedIndices.contains(index)) {
      return;
    }

    final state = context.read<AccentBloc>().state;
    if (state is AccentLoaded) {
      final correctWord =
          state.currentQuest.word ?? state.currentQuest.textToSpeak ?? "Word";
      final isCorrect =
          (correctWord.trim().toLowerCase() == targetWord.trim().toLowerCase());

      if (isCorrect) {
        _soundService.playCorrect();
        _hapticService.success();
        setState(() => _selectedWordIndex = index);

        // Immediate submit to update state
        context.read<AccentBloc>().add(SubmitAnswer(true));

        // Auto-proceed after a shorter 1-second delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _eliminatedIndices.clear();
              _selectedWordIndex = null;
            });
            context.read<AccentBloc>().add(NextQuestion());
          }
        });
      } else {
        _soundService.playWrong();
        _hapticService.error();
        setState(() => _selectedWordIndex = index);
        // Deduct life but don't show the correct answer or success overlay
        context.read<AccentBloc>().add(SubmitAnswer(false));
      }
    }
  }

  void _useHint(AccentLoaded state, List<String> words, String targetWord) {
    if (state.hintUsed) {
      _hapticService.error();
      return;
    }
    _hapticService.selection();
    _soundService.playHint();

    // Eliminate all wrong words
    setState(() {
      final target = targetWord.trim().toLowerCase();
      for (int i = 0; i < words.length; i++) {
        if (words[i].trim().toLowerCase() != target) {
          if (!_eliminatedIndices.contains(i)) {
            _eliminatedIndices.add(i);
          }
        }
      }
    });

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
            _confettiController.play();
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => _showCompletionDialog(
                context,
                state.xpEarned,
                state.coinsEarned,
              ),
            );
          } else if (state is AccentGameOver) {
            _showGameOverDialog(context);
          } else if (state is AccentLoaded) {
            final questChanged =
                _lastLoadedState?.currentQuest != state.currentQuest;
            if (questChanged) {
              setState(() {
                _selectedWordIndex = null;
                _eliminatedIndices.clear();
              });
            }
            _lastLoadedState = state;

            if (state.lastAnswerCorrect == false) {
              // Allow retry if life remaining
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted && state.livesRemaining > 0) {
                  setState(() {
                    _selectedWordIndex = null;
                    // Contextually, we let them try again. Eliminated indices remain.
                    context.read<AccentBloc>().add(RestoreLife());
                  });
                }
              });
            }
          }
        },
        builder: (context, state) {
          if (state is AccentLoading ||
              (state is AccentInitial && _lastLoadedState == null)) {
            return const GameShimmerLoading();
          }

          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<AccentBloc>().add(
                FetchAccentQuests(
                  gameType: GameSubtype.minimalPairs,
                  level: widget.level,
                ),
              ),
            );
          }

          final displayState = state is AccentLoaded ? state : _lastLoadedState;

          if (displayState != null) {
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                HarmonicWaves(color: theme.primaryColor, height: 100),
                _buildGameUI(context, displayState, isDark, theme),
                if (_showConfetti)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [
                        Colors.amber,
                        Colors.blue,
                        Colors.pink,
                        Colors.orange,
                        Colors.purple,
                      ],
                    ),
                  ),
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
    final targetWord = quest.word ?? quest.textToSpeak ?? "Word";
    final words = quest.options ?? [targetWord, "Alternative"];

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
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  if (!state.hintUsed) ...[
                    _buildHintButton(
                      state,
                      theme.primaryColor,
                      words,
                      targetWord,
                    ),
                    SizedBox(width: 12.w),
                  ],
                  _buildHeartCount(state.livesRemaining),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "MINIMAL PAIRS",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      Text(
                        quest.instruction,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87,
                        ),
                      ),

                      SizedBox(height: 50.h),

                      // Explicit Audio Playback Button
                      ScaleButton(
                        onTap: () => _playAudio(targetWord),
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
                                SizedBox(
                                  width: 40.w,
                                  child: const HarmonicWaves(
                                    color: Colors.white,
                                    height: 30,
                                  ),
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

                      SizedBox(height: 50.h),

                      // The Balance Scale Trays
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildScaleTray(
                              words[0],
                              0,
                              targetWord,
                              isDark,
                              theme,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: _buildScaleTray(
                              words[1],
                              1,
                              targetWord,
                              isDark,
                              theme,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      Text(
                        "DRAG PUCK OR TAP TO MATCH",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // The Draggable Sound Chip
                      if (_selectedWordIndex == null)
                        _buildDraggableSoundChip(targetWord, isDark, theme)
                      else
                        SizedBox(height: 120.r), // Empty space when answered

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildScaleTray(
    String word,
    int index,
    String correctWord,
    bool isDark,
    ThemeResult theme,
  ) {
    final isSelected = _selectedWordIndex == index;
    final isEliminated = _eliminatedIndices.contains(index);
    final isCorrect =
        word.trim().toLowerCase() == correctWord.trim().toLowerCase();
    final showResult = _selectedWordIndex != null;

    Color? cardColor;
    if (showResult && isSelected) {
      if (isCorrect) {
        cardColor = const Color(0xFF10B981);
      } else {
        cardColor = const Color(0xFFF43F5E);
      }
    } else if (showResult && isCorrect) {
      // Do not highlight correct answer if wrong answer was picked
      cardColor = null;
    }

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _onWordSelected(index, word);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final scaleFactor = isHovered ? 1.05 : 1.0;

        // A visual pedestal shape for the tray wrapped in a button for tapping
        return ScaleButton(
          onTap: () {
            if (_selectedWordIndex == null && !isEliminated) {
              _onWordSelected(index, word);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            // ignore: deprecated_member_use
            transform: Matrix4.identity()
              // ignore: deprecated_member_use
              ..scale(scaleFactor)
              // ignore: deprecated_member_use
              ..translate(0.0, isHovered ? -10.0 : 0.0),
            child: Opacity(
              opacity: isEliminated ? 0.0 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The Glass Tray
                  GlassTile(
                    borderRadius: BorderRadius.circular(24.r),
                    padding: EdgeInsets.symmetric(
                      vertical: 40.h,
                      horizontal: 10.w,
                    ),
                    color: isEliminated
                        ? (isDark ? Colors.white12 : Colors.black12)
                        : isHovered
                        ? theme.primaryColor.withValues(alpha: 0.3)
                        : (cardColor != null
                              ? cardColor.withValues(alpha: 0.8)
                              : (isDark ? Colors.white10 : Colors.white)),
                    borderColor: isEliminated
                        ? Colors.transparent
                        : (isSelected && showResult
                              ? Colors.white.withValues(alpha: 0.5)
                              : (isHovered
                                    ? theme.primaryColor
                                    : theme.primaryColor.withValues(
                                        alpha: 0.2,
                                      ))),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            word.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: isEliminated
                                  ? (isDark ? Colors.white24 : Colors.black26)
                                  : (isSelected && isDark)
                                  ? Colors.white
                                  : (isSelected && !isDark)
                                  ? Colors.black87
                                  : (isHovered && !isDark)
                                  ? Colors
                                        .black87 // Black text on light hover
                                  : (isDark ? Colors.white : Colors.black87),
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (showResult && isSelected && isCorrect) ...[
                            SizedBox(height: 12.h),
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.greenAccent,
                              size: 36.r,
                            ).animate().scale().shake(),
                          ],
                          if (showResult && isSelected && !isCorrect) ...[
                            SizedBox(height: 12.h),
                            Icon(
                              Icons.cancel_rounded,
                              color: Colors.redAccent,
                              size: 36.r,
                            ).animate().scale().shake(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // The Pedestal Base
                  Container(
                    height: 16.h,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: (index * 200).ms).slideY(begin: 0.1);
  }

  Widget _buildDraggableSoundChip(
    String targetWord,
    bool isDark,
    ThemeResult theme,
  ) {
    return Draggable<String>(
      data: "sound_chip",
      feedback: Material(
        color: Colors.transparent,
        child: _buildSoundPuck(theme, true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _buildSoundPuck(theme, false),
      ),
      onDragStarted: () => _hapticService.light(),
      child: _buildSoundPuck(theme, false),
    ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSoundPuck(ThemeResult theme, bool isDragging) {
    return Container(
      width: 120.r,
      height: 120.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: isDragging ? 0.9 : 0.7),
            theme.primaryColor.withValues(alpha: isDragging ? 1.0 : 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: isDragging ? 0.6 : 0.3),
            blurRadius: isDragging ? 24 : 12,
            spreadRadius: isDragging ? 4 : 2,
            offset: Offset(0, isDragging ? 12 : 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.touch_app_rounded, size: 48.r, color: Colors.white),
          ],
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

  Widget _buildHintButton(
    AccentLoaded state,
    Color primaryColor,
    List<String> words,
    String targetWord,
  ) {
    bool disabled = state.hintUsed;
    return ScaleButton(
      onTap: disabled ? null : () => _useHint(state, words, targetWord),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: disabled
                ? Colors.grey.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              disabled
                  ? Icons.lightbulb_outline_rounded
                  : Icons.lightbulb_rounded,
              color: disabled ? Colors.grey : primaryColor,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final hintCount = authState.user?.hintCount ?? 0;
                return Text(
                  "$hintCount",
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: disabled ? Colors.grey : primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, int xp, int coins) {
    _soundService.playLevelComplete();
    _hapticService.success();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: 'Phonetic Pro!',
        description: 'You earned $xp XP and $coins Coins for your sharp ears!',
        buttonText: 'OK',
        onButtonPressed: () {
          Navigator.pop(c);
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
      builder: (c) => ModernGameDialog(
        title: 'Frequency Lost',
        description: 'Your listening skills need a quick recharge. Try again!',
        isSuccess: false,
        isRescueLife: true,
        buttonText: 'GIVE UP',
        onButtonPressed: () {
          Navigator.pop(c);
          context.pop();
        },
        onAdAction: () {
          void restoreLife() {
            context.read<AccentBloc>().add(RestoreLife());
            Navigator.pop(c);
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
