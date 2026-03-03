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
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';

class SyllableStressScreen extends StatefulWidget {
  final int level;
  const SyllableStressScreen({super.key, required this.level});

  @override
  State<SyllableStressScreen> createState() => _SyllableStressScreenState();
}

class _SyllableStressScreenState extends State<SyllableStressScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  int? _selectedSyllableIndex;
  final List<int> _eliminatedIndices = [];
  bool _hasSubmitted = false;
  bool _showConfetti = false;
  bool _isPlaying = false;

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
        gameType: GameSubtype.syllableStress,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onSyllableTap(int index, AccentQuest quest) {
    if (_hasSubmitted || _eliminatedIndices.contains(index)) return;
    _hapticService.selection();
    _soundService.playClick();
    setState(() => _selectedSyllableIndex = index);
    _submitAnswer(quest);
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed) {
      _hapticService.error();
      return;
    }
    _hapticService.selection();
    _soundService.playHint();

    final syllables = quest.options ?? [];
    int wrongIndex = -1;
    for (int i = 0; i < syllables.length; i++) {
      if (i != quest.correctAnswerIndex && !_eliminatedIndices.contains(i)) {
        wrongIndex = i;
        break;
      }
    }
    if (wrongIndex != -1) {
      setState(() => _eliminatedIndices.add(wrongIndex));
    }
    context.read<AccentBloc>().add(AccentHintUsed());
  }

  void _submitAnswer(AccentQuest quest) {
    final isCorrect = _selectedSyllableIndex == quest.correctAnswerIndex;
    if (isCorrect) {
      setState(() => _hasSubmitted = true);
      _hapticService.success();
      // Sound is now handled by Bloc for consistency, but UI can play it too for zero lag
      _soundService.playCorrect();

      context.read<AccentBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          context.read<AccentBloc>().add(NextQuestion());
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() => _hasSubmitted = false);
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
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
            _showCompletionDialog(context, state.xpEarned, state.coinsEarned);
          } else if (state is AccentGameOver) {
            _showGameOverDialog(context);
          } else if (state is AccentLoaded) {
            _lastLoadedState = state;
            if (state.lastAnswerCorrect == null) {
              setState(() {
                _selectedSyllableIndex = null;
                _hasSubmitted = false;
                _eliminatedIndices.clear();
              });
            } else if (state.lastAnswerCorrect == false) {
              final accentBloc = context.read<AccentBloc>();
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted && state.livesRemaining > 0) {
                  setState(() {
                    _selectedSyllableIndex = null;
                  });
                  if (mounted) {
                    accentBloc.add(RestoreLife());
                  }
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
                  gameType: GameSubtype.syllableStress,
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
    final syllables = quest.options ?? [];

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              _buildHeader(context, state, progress, theme, isDark, quest),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "SYLLABLE STRESS",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
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
                              : const Color(0xFF0F172A),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      SizedBox(height: 60.h),
                      _buildWordDisplay(quest.word ?? '', theme, isDark),
                      SizedBox(height: 60.h),
                      _buildSyllablesList(
                        syllables,
                        theme,
                        isDark,
                        quest,
                        state.lastAnswerCorrect,
                      ),
                      SizedBox(height: 60.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccentLoaded state,
    double progress,
    ThemeResult theme,
    bool isDark,
    AccentQuest quest,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 10.h),
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
          if (!state.hintUsed) ...[
            _buildHintButton(state, theme.primaryColor, quest),
            SizedBox(width: 12.w),
          ],
          _buildHeartCount(state.livesRemaining),
        ],
      ),
    );
  }

  Widget _buildWordDisplay(String word, ThemeResult theme, bool isDark) {
    return Column(
      children: [
        // Explicit Audio Playback Button
        ScaleButton(
          onTap: () => _playAudio(word),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
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
                  color: theme.primaryColor.withValues(alpha: 0.3),
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
        SizedBox(height: 40.h),
        GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 32.h),
          borderRadius: BorderRadius.circular(40.r),
          borderColor: theme.primaryColor.withValues(alpha: 0.3),
          child: Column(
            children: [
              Text(
                word.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(),
      ],
    );
  }

  Widget _buildSyllablesList(
    List<String> syllables,
    ThemeResult theme,
    bool isDark,
    AccentQuest quest,
    bool? lastAnswerCorrect,
  ) {
    return Wrap(
      spacing: 24.w,
      runSpacing: 24.h,
      alignment: WrapAlignment.center,
      children: List.generate(
        syllables.length,
        (index) => _buildRhythmPad(
          syllables[index],
          index,
          theme,
          isDark,
          quest,
          lastAnswerCorrect,
        ),
      ),
    );
  }

  Widget _buildRhythmPad(
    String syllable,
    int index,
    ThemeResult theme,
    bool isDark,
    AccentQuest quest,
    bool? lastAnswerCorrect,
  ) {
    final isSelected = _selectedSyllableIndex == index;
    final isEliminated = _eliminatedIndices.contains(index);
    final isSubmitted = _hasSubmitted;
    final isCorrectSyllable = index == quest.correctAnswerIndex;

    Color inactiveColor = isDark ? Colors.white24 : Colors.black12;

    return ScaleButton(
      onTap: isEliminated ? null : () => _onSyllableTap(index, quest),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Continuous background pulse indicating rhythm
          if (!isSubmitted)
            Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withValues(alpha: 0.2),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.3, 1.3),
                  duration: 1500.ms,
                  curve: Curves.easeOut,
                )
                .fadeOut(duration: 1500.ms),

          // The Drum Pad
          Container(
            width: 90.r,
            height: 90.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEliminated
                  ? (isDark ? Colors.white10 : Colors.black12)
                  : isSelected
                  ? theme.primaryColor
                  : inactiveColor,
              border: Border.all(
                color: isEliminated
                    ? Colors.transparent
                    : isSelected
                    ? Colors.white
                    : theme.primaryColor.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  syllable.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: isEliminated
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : (isSelected && isDark)
                        ? Colors.white
                        : (isSelected && !isDark)
                        ? Colors.black87
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (_hasSubmitted &&
                    isCorrectSyllable &&
                    lastAnswerCorrect == true) ...[
                  SizedBox(height: 8.h),
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 24.r,
                  ).animate().scale().shake(),
                ],
                if (isSelected &&
                    !isCorrectSyllable &&
                    lastAnswerCorrect == false) ...[
                  SizedBox(height: 8.h),
                  Icon(
                    Icons.cancel_rounded,
                    color: Colors.redAccent,
                    size: 24.r,
                  ).animate().scale().shake(),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 200).ms).slideY(begin: 0.2);
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
    AccentQuest quest,
  ) {
    bool disabled = state.hintUsed;
    return ScaleButton(
      onTap: disabled ? null : () => _useHint(state, quest),
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
    _hapticService.success();
    _soundService.playLevelComplete();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernGameDialog(
        title: "STRESS MASTER!",
        description:
            "You've got the rhythm of a native speaker! Earned $xp XP and $coins coins.",
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
      builder: (c) => ModernGameDialog(
        title: "OUT OF STEP",
        description: "Don't lose your pulse. Try again to find the stress!",
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
