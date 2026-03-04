import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart' as entities;
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';

import '../widgets/ss_top_bar.dart';
import '../widgets/ss_word_display.dart';
import '../widgets/ss_option_button.dart';
import '../widgets/ss_feedback_card.dart';

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

  int? _selectedOptionIndex;
  final List<int> _eliminatedIndices = [];
  bool _hasAnswered = false;
  bool _showConfetti = false;
  bool _isPlaying = false;
  bool _showFeedback = false;
  List<int> _shuffledIndices = [];
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: entities.GameSubtype.syllableStress,
        level: widget.level,
      ),
    );
  }

  void _onOptionSelected(int index, AccentQuest quest) {
    if (_hasAnswered || _eliminatedIndices.contains(index)) return;
    _hapticService.selection();

    final isCorrect = index == quest.correctAnswerIndex;

    setState(() {
      _selectedOptionIndex = index;
      _hasAnswered = true;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _showFeedback = true);
      }
    });

    context.read<AccentBloc>().add(SubmitAnswer(isCorrect));
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _nextQuestion() {
    setState(() => _showFeedback = false);
    context.read<AccentBloc>().add(NextQuestion());
  }

  void _shuffleOptions(List<String>? options) {
    if (options == null || options.isEmpty) return;
    setState(() {
      _shuffledIndices = List.generate(options.length, (i) => i)..shuffle();
    });
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
                  gameType: 'syllableStress',
                  level: widget.level,
                  title: 'STRESS MASTER!',
                  description:
                      'You have mastered the rhythm! Your syllable stress is spot on.',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'OUT OF SYNC',
              description:
                  'Don\'t lose the beat! Try again to find the stress.',
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            // Verification: Only process if state matches current game and level
            if (state.gameType == entities.GameSubtype.syllableStress &&
                state.level == widget.level) {
              _lastLoadedState = state;
              if (state.lastAnswerCorrect == null) {
                setState(() {
                  _selectedOptionIndex = null;
                  _hasAnswered = false;
                  _showFeedback = false;
                  _eliminatedIndices.clear();
                });
                _shuffleOptions(state.currentQuest.options);
              }
            }
          }
        },
        builder: (context, state) {
          final bool isStale =
              state is AccentLoaded &&
              (state.gameType != entities.GameSubtype.syllableStress ||
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
                  gameType: entities.GameSubtype.syllableStress,
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: HarmonicWaves(
                    color: theme.primaryColor,
                    height: 120.h,
                  ),
                ),
                _buildMainUI(displayState, isDark, theme),
                if (_showFeedback)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SsFeedbackCard(
                      isCorrect: displayState.lastAnswerCorrect ?? false,
                      hint:
                          displayState.currentQuest.hint ??
                          "Feel the rhythm of the word.",
                      word: displayState.currentQuest.word ?? "",
                      correctOption:
                          displayState.currentQuest.options![displayState
                                  .currentQuest
                                  .correctAnswerIndex ??
                              0],
                      primaryColor: theme.primaryColor,
                      onNext: _nextQuestion,
                    ),
                  ),
                if (_showConfetti) const GameConfetti(),
              ],
            );
          }
          return const Center(child: Text("Quest Unavailable"));
        },
      ),
    );
  }

  Widget _buildMainUI(AccentLoaded state, bool isDark, ThemeResult theme) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return SafeArea(
      child: Column(
        children: [
          SsTopBar(
            progress: progress,
            livesRemaining: state.livesRemaining,
            primaryColor: theme.primaryColor,
          ),
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
                  ).animate().fadeIn(),
                  SizedBox(height: 8.h),
                  Text(
                    "Where is the stress?",
                    style: GoogleFonts.outfit(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                  SizedBox(height: 48.h),
                  SsWordDisplay(
                    word: quest.word ?? "",
                    isPlaying: _isPlaying,
                    primaryColor: theme.primaryColor,
                    onPlayTap: () => _playAudio(quest.word ?? ""),
                  ),
                  SizedBox(height: 48.h),
                  Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    alignment: WrapAlignment.center,
                    children: _shuffledIndices.map((originalIndex) {
                      return SsOptionButton(
                        option: quest.options![originalIndex],
                        index: originalIndex,
                        isSelected: _selectedOptionIndex == originalIndex,
                        isEliminated: _eliminatedIndices.contains(
                          originalIndex,
                        ),
                        isCorrect: originalIndex == quest.correctAnswerIndex,
                        hasSubmitted: _hasAnswered,
                        primaryColor: theme.primaryColor,
                        onTap: () => _onOptionSelected(originalIndex, quest),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 120.h), // Space for feedback card
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
