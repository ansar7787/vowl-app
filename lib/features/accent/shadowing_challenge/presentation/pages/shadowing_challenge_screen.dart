import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
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

// Custom Widget Imports
import '../widgets/sc_top_bar.dart';
import '../widgets/sc_sentence_display.dart';
import '../widgets/sc_audio_controls.dart';
import '../widgets/sc_recording_button.dart';
import '../widgets/sc_feedback_card.dart';

class ShadowingChallengeScreen extends StatefulWidget {
  final int level;
  const ShadowingChallengeScreen({super.key, required this.level});

  @override
  State<ShadowingChallengeScreen> createState() =>
      _ShadowingChallengeScreenState();
}

class _ShadowingChallengeScreenState extends State<ShadowingChallengeScreen> {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isRecording = false;
  bool _isPlaying = false;
  String _recognizedText = '';
  String _currentSpokenWord = '';
  bool _hasAnalyzed = false;
  bool _showConfetti = false;
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    _speechService.initializeStt();
    _speechService.setWordCallback((word) {
      if (mounted) setState(() => _currentSpokenWord = word);
    });
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.shadowingChallenge,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _speechService.setWordCallback(null);
    super.dispose();
  }

  void _playAudio(String text, {double rate = 0.5}) async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _currentSpokenWord = '';
    });
    _hapticService.light();
    await _speechService.speak(text, rate: rate);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _startListening() {
    _hapticService.success();
    // If we were previously showing feedback (wrong answer), reset the state
    final state = context.read<AccentBloc>().state;
    if (state is AccentLoaded && state.lastAnswerCorrect != null) {
      context.read<AccentBloc>().add(SubmitAnswer(null));
    }

    setState(() {
      _isRecording = true;
      _recognizedText = '';
      _hasAnalyzed = false;
      _currentSpokenWord = '';
    });

    // START AUDIO SIMULTANEOUSLY FOR TRUE SHADOWING
    if (state is AccentLoaded) {
      final quest = state.currentQuest;
      _playAudio(quest.sentence ?? quest.word ?? "");
    }

    _speechService.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result;
        });
      },
      onDone: () {
        if (mounted && _isRecording) {
          // Only auto-complete if the engine stopped itself after a long pause
          setState(() => _isRecording = false);
          _analyzeSpeech();
        }
      },
    );
  }

  void _stopListening() async {
    if (!_isRecording) return;
    _hapticService.light();
    await _speechService.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPlaying = false;
      });
      _analyzeSpeech();
    }
  }

  void _analyzeSpeech() {
    if (_hasAnalyzed || _recognizedText.isEmpty) return;
    _hasAnalyzed = true;

    final state = context.read<AccentBloc>().state;
    if (state is! AccentLoaded) return;

    final quest = state.currentQuest;
    final targetContent = quest.sentence ?? quest.word ?? "";

    final targetText = targetContent.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    final utteredText = _recognizedText.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    // Shadowing is challenging, 80% match is enough for "shadowing" success
    bool isCorrect =
        utteredText == targetText ||
        utteredText.contains(targetText) ||
        (targetText.contains(utteredText) &&
            utteredText.length > targetText.length * 0.8);

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.read<AccentBloc>().add(NextQuestion());
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _hasAnalyzed = false;
        _recognizedText = '';
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));

      // Auto-reset back to recording state after 2.5 seconds so they can read the feedback
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          context.read<AccentBloc>().add(SubmitAnswer(null));
        }
      });
    }
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed || _hasAnalyzed) {
      _hapticService.error();
      return;
    }

    // Deduct a hint point
    context.read<AccentBloc>().add(AccentHintUsed());
    _soundService.playHint();

    // PEDAGOGICAL HINT: Slow-motion preview
    _playAudio(quest.sentence ?? quest.word ?? "", rate: 0.35);
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
                  gameType: 'shadowingChallenge',
                  level: widget.level,
                  title: 'SHADOWING HERO!',
                  description:
                      'Your timing and accent mimicry are getting incredibly sharp!',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Out of Sync',
              description: 'The shadow faded away. Try to stay closer!',
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            if (state.gameType == GameSubtype.shadowingChallenge &&
                state.level == widget.level) {
              _lastLoadedState = state;
            }
          }
        },
        builder: (context, state) {
          final bool isStale =
              state is AccentLoaded &&
              (state.gameType != GameSubtype.shadowingChallenge ||
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
                  gameType: GameSubtype.shadowingChallenge,
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
                HarmonicWaves(color: theme.primaryColor, height: 100),
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
    final isLastQuestion = state.currentIndex == state.quests.length - 1;

    return Column(
      children: [
        SCTopBar(
          state: state,
          theme: theme,
          isDark: isDark,
          quest: quest.copyWith(
            instruction: _isRecording
                ? "SHADOW THE VOICE NOW"
                : (_isPlaying
                      ? "LISTEN TO THE RHYTHM"
                      : "PREVIEW, THEN SHADOW"),
          ),
          onHintPressed: () => _useHint(state, quest),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                SCSentenceDisplay(
                  quest: quest,
                  theme: theme,
                  isDark: isDark,
                  currentSpokenWord: _currentSpokenWord,
                ),
                SizedBox(height: 32.h),
                SCAudioControls(
                  theme: theme,
                  isPlaying:
                      _isPlaying && !_isRecording, // Only show wave in Step 1
                  onPlayAudio: () =>
                      _playAudio(quest.sentence ?? quest.word ?? ""),
                ),
                SizedBox(height: 48.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  child: state.lastAnswerCorrect == null
                      ? SCRecordingButton(
                          key: const ValueKey('recording'),
                          isListening: _isRecording,
                          isDark: isDark,
                          theme: theme,
                          recognizedText: _recognizedText,
                          targetSentence: quest.sentence ?? quest.word ?? "",
                          onStartListening: _startListening,
                          onStopListening: _stopListening,
                        )
                      : SCFeedbackCard(
                          key: const ValueKey('feedback'),
                          isDark: isDark,
                          theme: theme,
                          isCorrect: state.lastAnswerCorrect!,
                          isLastQuestion: isLastQuestion,
                        ),
                ),
                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
