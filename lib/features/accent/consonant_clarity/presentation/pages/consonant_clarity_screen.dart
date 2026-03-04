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
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/core/presentation/widgets/games/premium_game_widgets.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import '../widgets/consonant_playback_controls.dart';
import '../widgets/consonant_word_card.dart';
import '../widgets/consonant_mouth_tip.dart';
import '../widgets/consonant_feedback_panel.dart';

class ConsonantClarityScreen extends StatefulWidget {
  final int level;
  const ConsonantClarityScreen({super.key, required this.level});

  @override
  State<ConsonantClarityScreen> createState() => _ConsonantClarityScreenState();
}

class _ConsonantClarityScreenState extends State<ConsonantClarityScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  bool _isPlaying = false;
  bool _showConfetti = false;
  double _playbackRate = 1.0;

  bool _hasSubmitted = false;
  int? _selectedOptionIndex;
  final Set<int> _eliminatedIndices = {};
  List<int> _shuffledIndices = [];

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.consonantClarity,
        level: widget.level,
      ),
    );
  }

  void _playAudio(String text, {double? rate}) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text, rate: rate ?? _playbackRate);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _shuffleOptions(int count) {
    if (_shuffledIndices.isEmpty) {
      _shuffledIndices = List<int>.generate(count, (i) => i);
      _shuffledIndices.shuffle();
    }
  }

  void _checkAnswer(int index, AccentQuest quest) {
    final originalIndex = _shuffledIndices[index];
    if (_hasSubmitted || _eliminatedIndices.contains(originalIndex)) return;

    setState(() {
      _selectedOptionIndex = index;
    });

    bool isCorrect = false;
    if (quest.correctAnswerIndex != null) {
      isCorrect = (originalIndex == quest.correctAnswerIndex);
    } else if (quest.options != null && quest.correctAnswer != null) {
      isCorrect = (quest.options![originalIndex] == quest.correctAnswer);
    } else {
      isCorrect = (originalIndex == 0); // Fallback
    }

    if (isCorrect) {
      setState(() => _hasSubmitted = true);
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) {
          context.read<AccentBloc>().add(NextQuestion());
          setState(() {
            _hasSubmitted = false;
            _selectedOptionIndex = null;
            _shuffledIndices = [];
            _eliminatedIndices.clear();
          });
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _eliminatedIndices.add(originalIndex);
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));

      // Reset selected index after a short delay so user can try again
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_hasSubmitted) {
          setState(() => _selectedOptionIndex = null);
        }
      });
    }
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed) return;
    _hapticService.selection();
    _soundService.playHint();

    final options = quest.options ?? [];
    int? wrongOriginalIndex;
    for (int i = 0; i < options.length; i++) {
      bool isCorrect = (quest.correctAnswerIndex != null)
          ? (i == quest.correctAnswerIndex)
          : (options[i] == quest.correctAnswer);

      if (!isCorrect && !_eliminatedIndices.contains(i)) {
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
                  gameType: 'consonantClarity',
                  level: widget.level,
                  title: 'CONSONANT MASTER!',
                  description:
                      'Your pronunciation is crystal clear. You\'ve mastered these consonants!',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            if (state.gameType == GameSubtype.consonantClarity &&
                state.level == widget.level) {
              _shuffleOptions(state.currentQuest.options?.length ?? 2);
            }
          }
        },
        builder: (context, state) {
          if (state is AccentLoading || state is AccentInitial) {
            return const GameShimmerLoading();
          }

          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<AccentBloc>().add(
                FetchAccentQuests(
                  gameType: GameSubtype.consonantClarity,
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
                HarmonicWaves(color: theme.primaryColor.withValues(alpha: 0.1)),
                SafeArea(
                  child: _buildGameUI(context, displayState, isDark, theme),
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

  Widget _buildGameUI(
    BuildContext context,
    AccentLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return Column(
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
                _buildTitle(theme),
                _buildSubtitle(isDark),
                SizedBox(height: 30.h),

                ConsonantPlaybackControls(
                  playbackRate: _playbackRate,
                  isPlaying: _isPlaying,
                  onPlayNormal: () {
                    setState(() => _playbackRate = 1.0);
                    _playAudio(quest.word ?? "");
                  },
                  onPlaySlow: () {
                    setState(() => _playbackRate = 0.75);
                    _playAudio(quest.word ?? "");
                  },
                  isDark: isDark,
                  theme: theme,
                ),

                SizedBox(height: 40.h),
                ConsonantWordCard(
                  word: quest.word ?? "",
                  isDark: isDark,
                  theme: theme,
                ).animate().fadeIn(delay: 200.ms).scale(),

                SizedBox(height: 24.h),
                ConsonantMouthTip(
                  tip: quest
                      .mouthPosition, // Using mouthPosition from AccentQuest
                  isDark: isDark,
                ).animate().fadeIn(delay: 400.ms),

                SizedBox(height: 40.h),
                _buildQuestion(quest.instruction, isDark),
                SizedBox(height: 24.h),

                if (!_hasSubmitted)
                  _buildAnswerButtons(quest, isDark, theme)
                else
                  ConsonantFeedbackPanel(
                    quest: quest,
                    isCorrect:
                        _shuffledIndices[_selectedOptionIndex!] ==
                        quest.correctAnswerIndex,
                    onPlayAgain: () => _playAudio(quest.word ?? ""),
                    isDark: isDark,
                    theme: theme,
                  ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeResult theme) {
    return Text(
      "CONSONANT CLARITY",
      style: GoogleFonts.outfit(
        fontSize: 12.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        color: theme.primaryColor,
      ),
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Text(
      "IDENTIFY THE CONSONANT SOUND",
      style: GoogleFonts.outfit(
        fontSize: 10.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildQuestion(String instruction, bool isDark) {
    return Text(
      instruction,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildAnswerButtons(
    AccentQuest quest,
    bool isDark,
    ThemeResult theme,
  ) {
    final options = quest.options ?? [];
    return Column(
      children: List.generate(_shuffledIndices.length, (index) {
        final originalIndex = _shuffledIndices[index];
        final option = options[originalIndex];
        final isSelected = _selectedOptionIndex == index;
        final isEliminated = _eliminatedIndices.contains(originalIndex);

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ScaleButton(
            onTap: isEliminated ? null : () => _checkAnswer(index, quest),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor
                    : (isEliminated
                          ? (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05))
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white)),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? Colors.white10 : Colors.black12),
                  width: 1.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  option.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isEliminated
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : (isDark ? Colors.white : Colors.black87)),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
