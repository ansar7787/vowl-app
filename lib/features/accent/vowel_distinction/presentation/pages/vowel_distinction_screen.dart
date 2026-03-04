import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
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
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import '../widgets/vowel_playback_controls.dart';
import '../widgets/vowel_word_card.dart';
import '../widgets/vowel_feedback_panel.dart';

class VowelDistinctionScreen extends StatefulWidget {
  final int level;
  const VowelDistinctionScreen({super.key, required this.level});

  @override
  State<VowelDistinctionScreen> createState() => _VowelDistinctionScreenState();
}

class _VowelDistinctionScreenState extends State<VowelDistinctionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  int _listenCount = 0;
  static const int _maxListens = 3;

  bool _hasSubmitted = false;
  int? _selectedOptionIndex;
  int? _wrongIndex;
  final List<int> _eliminatedIndices = [];
  List<int> _shuffledIndices = [];

  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.vowelDistinction,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _shuffleOptions(AccentQuest quest) {
    if (_shuffledIndices.isEmpty) {
      _shuffledIndices = List.generate(quest.options!.length, (i) => i);
      _shuffledIndices.shuffle();
    }
  }

  Future<void> _playAudio(String text, {double? rate}) async {
    if (_listenCount >= _maxListens && !_hasSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Max listens reached for this question!")),
      );
      return;
    }

    setState(() => _isPlaying = true);
    await _ttsService.speak(text, rate: rate ?? _playbackRate);
    if (!_hasSubmitted && rate == null) {
      setState(() => _listenCount++);
    }
    setState(() => _isPlaying = false);
  }

  void _checkAnswer(int index, AccentQuest quest) {
    if (_hasSubmitted) return;

    final isCorrect = _shuffledIndices[index] == quest.correctAnswerIndex;
    _hapticService.selection();

    if (isCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() {
        _hasSubmitted = true;
        _selectedOptionIndex = index;
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.read<AccentBloc>().add(NextQuestion());
          setState(() {
            _hasSubmitted = false;
            _selectedOptionIndex = null;
            _listenCount = 0;
            _shuffledIndices = [];
            _eliminatedIndices.clear();
          });
        }
      });
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() {
        _wrongIndex = index;
        _eliminatedIndices.add(index);
        _selectedOptionIndex = index;
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));

      // Reset transient wrong state after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _wrongIndex == index) {
          setState(() {
            _wrongIndex = null;
            _selectedOptionIndex = null;
          });
        }
      });
    }
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed) return;
    _hapticService.selection();
    _soundService.playHint();

    final hintText =
        quest.hint ?? "👂 Focus on whether the sound is short or long.";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                hintText,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.indigo.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 4),
      ),
    );

    // Eliminate a wrong option for pedagogical benefit
    if (_shuffledIndices.isNotEmpty && quest.correctAnswerIndex != null) {
      for (int i = 0; i < _shuffledIndices.length; i++) {
        if (_shuffledIndices[i] != quest.correctAnswerIndex &&
            !_eliminatedIndices.contains(i)) {
          setState(() => _eliminatedIndices.add(i));
          break;
        }
      }
    }

    context.read<AccentBloc>().add(AccentHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

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
                  gameType: 'vowelDistinction',
                  level: widget.level,
                  title: 'VOWEL MASTER!',
                  description:
                      'You distinguished between those tricky minimal pairs with ease.',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          }
          if (state is AccentLoaded) {
            _shuffleOptions(state.currentQuest);
          }
        },
        builder: (context, state) {
          if (state is AccentLoading || state is AccentInitial) {
            return const GameShimmerLoading();
          }

          if (state is AccentLoaded || state is AccentGameComplete) {
            final loadedState = state is AccentLoaded
                ? state
                : (state as AccentGameComplete).lastState;
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                HarmonicWaves(color: theme.primaryColor.withValues(alpha: 0.1)),
                SafeArea(
                  child: _buildGameUI(context, loadedState, isDark, theme),
                ),
                if (_showConfetti) const GameConfetti(),
              ],
            );
          }
          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<AccentBloc>().add(
                FetchAccentQuests(
                  gameType: GameSubtype.vowelDistinction,
                  level: widget.level,
                ),
              ),
            );
          }
          return const Center(child: Text("Quest Unavailable"));
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
                _buildPurposeSubtitle(isDark),
                SizedBox(height: 12.h),
                _buildInstruction(quest, isDark),
                SizedBox(height: 30.h),
                VowelPlaybackControls(
                  playbackRate: _playbackRate,
                  listenCount: _listenCount,
                  maxListens: _maxListens,
                  isPlaying: _isPlaying,
                  onPlay: () {
                    final wordToSpeak = quest.correctAnswerIndex == 0
                        ? (quest.word1 ?? quest.options?[0] ?? "")
                        : (quest.word2 ?? quest.options?[1] ?? "");
                    _playAudio(wordToSpeak);
                  },
                  onRateChange: (rate) => setState(() => _playbackRate = rate),
                  isDark: isDark,
                  theme: theme,
                ),
                SizedBox(height: 40.h),
                _buildVisualWordCards(quest, isDark, theme),
                SizedBox(height: 40.h),
                if (!_hasSubmitted) _buildAnswerButtons(quest, isDark, theme),
                if (_hasSubmitted)
                  VowelFeedbackPanel(
                    quest: quest,
                    isCorrect:
                        _shuffledIndices[_selectedOptionIndex!] ==
                        quest.correctAnswerIndex,
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
      "VOWEL DISTINCTION",
      style: GoogleFonts.outfit(
        fontSize: 12.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        color: theme.primaryColor,
      ),
    );
  }

  Widget _buildPurposeSubtitle(bool isDark) {
    return Text(
      "MINIMAL PAIR TRAINING",
      style: GoogleFonts.outfit(
        fontSize: 10.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInstruction(AccentQuest quest, bool isDark) {
    return Text(
      quest.instruction,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildVisualWordCards(
    AccentQuest quest,
    bool isDark,
    ThemeResult theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        VowelWordCard(
          word: quest.word1 ?? quest.options?[0] ?? "",
          ipa: quest.ipa1,
          isDark: isDark,
          theme: theme,
          onPlay: () => _playAudio(
            quest.word1 ?? quest.options?[0] ?? "",
            rate: _playbackRate,
          ),
        ),
        VowelWordCard(
          word: quest.word2 ?? quest.options?[1] ?? "",
          ipa: quest.ipa2,
          isDark: isDark,
          theme: theme,
          onPlay: () => _playAudio(
            quest.word2 ?? quest.options?[1] ?? "",
            rate: _playbackRate,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButtons(
    AccentQuest quest,
    bool isDark,
    ThemeResult theme,
  ) {
    return Column(
      children: List.generate(_shuffledIndices.length, (index) {
        final originalIndex = _shuffledIndices[index];
        final option = quest.options![originalIndex];
        final isSelected = _selectedOptionIndex == index;
        final isEliminated = _eliminatedIndices.contains(index);

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ScaleButton(
            onTap: () => _checkAnswer(index, quest),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isEliminated ? Colors.red : theme.primaryColor)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isSelected
                      ? (isEliminated ? Colors.red : theme.primaryColor)
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: isSelected && isEliminated ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  option.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
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
