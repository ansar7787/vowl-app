import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';

import '../widgets/wl_top_bar.dart';
import '../widgets/wl_audio_controls.dart';
import '../widgets/wl_phrase_display.dart';
import '../widgets/wl_options_list.dart';
import '../widgets/wl_feedback_card.dart';

class WordLinkingScreen extends StatefulWidget {
  final int level;

  const WordLinkingScreen({super.key, required this.level});

  @override
  State<WordLinkingScreen> createState() => _WordLinkingScreenState();
}

class _WordLinkingScreenState extends State<WordLinkingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  bool _isPlaying = false;
  bool _showConfetti = false;
  bool _isSlowMode = false;

  bool _hasSubmitted = false;
  int? _selectedOptionIndex;
  final List<int> _eliminatedIndices = [];
  List<int> _shuffledIndices = [];
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: GameSubtype.wordLinking, level: widget.level),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _playAudio(String text, {bool slow = false}) async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _isSlowMode = slow;
    });
    _hapticService.light();
    await _ttsService.speak(text, rate: slow ? 0.35 : 0.5);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _shuffleOptions(int count) {
    _shuffledIndices = List<int>.generate(count, (i) => i);
    _shuffledIndices.shuffle();
  }

  void _checkAnswer(int shuffledIndex, AccentQuest quest) {
    final originalIndex = _shuffledIndices[shuffledIndex];
    if (_hasSubmitted || _eliminatedIndices.contains(originalIndex)) return;
    setState(() => _selectedOptionIndex = shuffledIndex);

    bool isCorrect = false;
    if (quest.correctAnswerIndex != null) {
      isCorrect = (originalIndex == quest.correctAnswerIndex);
    } else if (quest.correctAnswer != null && quest.options != null) {
      isCorrect = (quest.options![originalIndex] == quest.correctAnswer);
    } else {
      isCorrect = (originalIndex == 0); // Fallback
    }

    if (isCorrect) {
      setState(() {
        _hasSubmitted = true;
      });
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));

      // Auto-advance on the last question
      final currentState = context.read<AccentBloc>().state;
      if (currentState is AccentLoaded &&
          currentState.currentIndex == currentState.quests.length - 1) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            context.read<AccentBloc>().add(NextQuestion());
          }
        });
      }
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        // IMPORTANT BUG FIX: We eliminate the wrong answer and DO NOT set _hasSubmitted = true.
        // This forces the user to try again (and lose a life) until they find the correct answer,
        // matching the AccentBloc's logic which only proceeds if `lastAnswerCorrect == true`.
        _eliminatedIndices.add(originalIndex);
      });
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

    final options = quest.options ?? [];

    int? wrongOriginalIndex;
    for (int i = 0; i < options.length; i++) {
      bool isMatch = false;
      if (quest.correctAnswerIndex != null) {
        isMatch = (i == quest.correctAnswerIndex);
      } else if (quest.correctAnswer != null) {
        isMatch = (options[i] == quest.correctAnswer);
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
          if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: "Game Over",
              description: "Out of hearts. Try again!",
              buttonText: "RETRY",
              onRestore: () {
                context.read<AccentBloc>().add(
                  FetchAccentQuests(
                    gameType: GameSubtype.wordLinking,
                    level: widget.level,
                  ),
                );
              },
            );
          } else if (state is AccentGameComplete) {
            setState(() => _showConfetti = true);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VictoryScreen(
                  xp: state.xpEarned,
                  coins: state.coinsEarned,
                  category: 'accent',
                  gameType: 'wordLinking',
                  level: widget.level,
                  title: 'LINK MASTER!',
                  description:
                      'You mastered the art of connected speech and linking sounds!',
                ),
              ),
            );
          } else if (state is AccentLoaded) {
            if (_lastLoadedState != null &&
                _lastLoadedState!.currentIndex != state.currentIndex) {
              _hasSubmitted = false;
              _selectedOptionIndex = null;
              _eliminatedIndices.clear();
              _showConfetti = false;
              _isPlaying = false;

              final nextQuest = state.quests[state.currentIndex];
              _shuffleOptions(nextQuest.options?.length ?? 0);

              if (mounted) setState(() {});
            }
            _lastLoadedState = state;
          }
        },
        builder: (context, state) {
          if (state is AccentLoading) {
            return const GameShimmerLoading();
          }

          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.pop(),
            );
          }

          if (state is AccentLoaded || state is AccentGameComplete) {
            final loadedState = state is AccentLoaded
                ? state
                : (state as AccentGameComplete).lastState;

            if (loadedState.quests.isEmpty ||
                loadedState.currentIndex >= loadedState.quests.length) {
              return QuestUnavailableScreen(
                message: "No questions available for this level.",
                onRetry: () => context.pop(),
              );
            }

            // Security mismatch check
            if (loadedState.gameType != GameSubtype.wordLinking ||
                loadedState.level != widget.level) {
              return QuestUnavailableScreen(
                message: "Data mismatch detected.",
                onRetry: () {
                  context.pop();
                },
              );
            }

            final quest = loadedState.quests[loadedState.currentIndex];
            if (_shuffledIndices.isEmpty ||
                _shuffledIndices.length != (quest.options?.length ?? 0)) {
              _shuffleOptions(quest.options?.length ?? 0);
            }

            return _buildGameUI(loadedState, quest, isDark, theme);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    AccentLoaded state,
    AccentQuest quest,
    bool isDark,
    ThemeResult theme,
  ) {
    return Stack(
      children: [
        MeshGradientBackground(colors: [theme.primaryColor, theme.accentColor]),
        Column(
          children: [
            WLTopBar(
              state: state,
              theme: theme,
              isDark: isDark,
              onHintPressed: () => _useHint(state, quest),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      "WORD LINKING",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Identify the linked sounds",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    SizedBox(height: 40.h),

                    // Audio Controls Card
                    WLAudioControls(
                      quest: quest,
                      theme: theme,
                      isSlowMode: _isSlowMode,
                      onPlayAudio: (isSlow) =>
                          _playAudio(quest.word ?? "", slow: isSlow),
                    ),
                    SizedBox(height: 32.h),

                    // Enhanced Phrase Display
                    WLPhraseDisplay(
                      quest: quest,
                      theme: theme,
                      isDark: isDark,
                      isPlaying: _isPlaying,
                    ),
                    SizedBox(height: 18.h),

                    // Choice Section Title
                    if (!_hasSubmitted)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Text(
                          "WHICH VERSION SOUNDS NATURAL?",
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms),

                    // Options List
                    WLOptionsList(
                      quest: quest,
                      isDark: isDark,
                      theme: theme,
                      shuffledIndices: _shuffledIndices,
                      eliminatedIndices: _eliminatedIndices,
                      hasSubmitted: _hasSubmitted,
                      selectedOptionIndex: _selectedOptionIndex,
                      onOptionSelected: (index) => _checkAnswer(index, quest),
                    ),

                    // Enhanced Feedback & Explanation
                    if (_hasSubmitted)
                      WLFeedbackCard(
                        quest: quest,
                        isDark: isDark,
                        theme: theme,
                        isCorrect: state.lastAnswerCorrect ?? false,
                        isLastQuestion:
                            state.currentIndex == state.quests.length - 1,
                        onPlayAudio: () => _playAudio(quest.word ?? ""),
                        onContinue: () =>
                            context.read<AccentBloc>().add(NextQuestion()),
                      ),

                    SizedBox(height: 60.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }
}
