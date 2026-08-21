import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_instruction.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_jar.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_canvas.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_input.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/presentation/game_mechanics/blind_dictation_wrapper.dart';
import 'package:vowl/core/presentation/game_mechanics/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Height threshold below which the compact layout variant is used.
const double _kCompactHeightThreshold = 580.0;

/// Maximum character length for the transcription input.
const int _kMaxInputLength = 120;

// =============================================================================
// AudioFillBlanksScreen
// =============================================================================

class AudioFillBlanksScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const AudioFillBlanksScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioFillBlanks,
  });

  @override
  State<AudioFillBlanksScreen> createState() => _AudioFillBlanksScreenState();
}

class _AudioFillBlanksScreenState extends State<AudioFillBlanksScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();

  // ── Local UI state (synced from BLoC listener) ────────────────────────────
  double _revealProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  // ── Change-tracking helpers ───────────────────────────────────────────────
  int _lastProcessedIndex = -1;
  int? _lastLives;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Gesture handler ───────────────────────────────────────────────────────

  void _onSmear(double delta) {
    if (_isAnswered) return;
    setState(() {
      _revealProgress = (_revealProgress + delta).clamp(0.0, 1.0);
      if (_revealProgress > 0.05) _hapticService.selection();
    });
  }

  // ── Submit answer ─────────────────────────────────────────────────────────

  void _submitAnswer(String? correct) {
    // Guard: already answered, empty / whitespace-only input, or no answer key.
    final input = _controller.text.trim();
    if (_isAnswered || input.isEmpty || correct == null || correct.isEmpty) {
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, input)) {
      return;
    }

    String cleanInput = input
        .replaceAll(RegExp(r'[.,!?]'), '')
        .trim()
        .toLowerCase();
    String cleanCorrect = correct
        .replaceAll(RegExp(r'[.,!?]'), '')
        .trim()
        .toLowerCase();

    final isCorrect = cleanInput == cleanCorrect;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
      
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Audio Fill Blanks',
          userAnswer: input,
          correctAnswer: correct,
          level: widget.level,
        );
      }
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    // Bloc dispatches analytics internally via ListeningAnalytics.
    context.read<ListeningBloc>().add(SubmitAnswer(isCorrect));
  }

  // ── TTS playback ──────────────────────────────────────────────────────────

  void _playAudio(String? textToSpeak) {
    final text = textToSpeak?.trim();
    if (text == null || text.isEmpty) return;
    _soundService.playTts(text);
    _hapticService.selection();
  }

  // ── Reset local state for the next question ───────────────────────────────

  void _resetForNextQuestion(int newIndex) {
    setState(() {
      _lastProcessedIndex = newIndex;
      _isAnswered = false;
      _isCorrect = null;
      _revealProgress = 0.0;
      _controller.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // FIX: use widget.gameType.name — not the hardcoded 'listening' string.
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      isDark: isDark,
    );

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          // Detect a life-restore (lives increased, e.g. 0 → 1).
          final isLifeRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || isLifeRestored) {
            _resetForNextQuestion(state.currentIndex);
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            // Bloc already knows the result; sync local state.
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }

          _lastLives = state.livesRemaining;
        }

        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'AUDITORY ACE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = state is ListeningLoaded ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () =>
              context.read<ListeningBloc>().add(const NextQuestion()),
          // FIX: Layout now dispatches ListeningHintUsed internally.
          // This callback is for screen-level side-effects only.
          onHint: () => _hapticService.selection(),
          child: quest == null
              ? const SizedBox.shrink()
              : _AudioFillBlanksContent(
                  quest: quest,
                  isAnswered: _isAnswered,
                  isCorrect: _isCorrect,
                  revealProgress: _revealProgress,
                  controller: _controller,
                  theme: theme,
                  isDark: isDark,
                  maxInputLength: _kMaxInputLength,
                  compactThreshold: _kCompactHeightThreshold,
                  level: widget.level,
                  onSmear: _onSmear,
                  onPlayAudio: () => _playAudio(quest.textToSpeak),
                  onSubmit: () => _submitAnswer(quest.correctAnswer),
                  onBlindSubmit: (bool correct) {
                    if (!correct) {
                      final authState = context.read<AuthBloc>().state;
                      if (authState.status == AuthStatus.authenticated && authState.user != null) {
                        ErrorJournalCollector.record(
                          userId: authState.user!.id,
                          gameType: widget.gameType.name,
                          question: 'Blind Dictation',
                          userAnswer: '[Failed Dictation]',
                          correctAnswer: quest.correctAnswer ?? quest.textToSpeak ?? '',
                          level: widget.level,
                        );
                      }
                    }
                    setState(() {
                      _isAnswered = true;
                      _isCorrect = correct;
                    });
                    context.read<ListeningBloc>().add(SubmitAnswer(correct));
                  },
                ),
        );
      },
    );
  }
}

// =============================================================================
// _AudioFillBlanksContent
//
// Extracted layout widget — handles the adaptive gap / compact-mode logic
// and composes all sub-widgets. Keeping it private (underscore) as it is
// tightly coupled to this feature's UX.
// =============================================================================

class _AudioFillBlanksContent extends StatelessWidget {
  final dynamic quest;
  final bool isAnswered;
  final bool? isCorrect;
  final double revealProgress;
  final TextEditingController controller;
  final dynamic theme;
  final bool isDark;
  final int maxInputLength;
  final double compactThreshold;
  final int level;
  final void Function(double) onSmear;
  final VoidCallback onPlayAudio;
  final VoidCallback onSubmit;
  final void Function(bool) onBlindSubmit;

  const _AudioFillBlanksContent({
    required this.quest,
    required this.isAnswered,
    required this.isCorrect,
    required this.revealProgress,
    required this.controller,
    required this.theme,
    required this.isDark,
    required this.maxInputLength,
    required this.compactThreshold,
    required this.level,
    required this.onSmear,
    required this.onPlayAudio,
    required this.onSubmit,
    required this.onBlindSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          sliver: SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 6.h),
                AudioFillBlanksInstruction(
                  instruction: quest.instruction ??
                      'LISTEN TO THE AUDIO AND TYPE THE MISSING WORD',
                  color: theme.primaryColor,
                ),
                SizedBox(height: 24.h),
                AudioFillBlanksJar(
                  color: theme.primaryColor,
                  onTap: onPlayAudio,
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  height: 220.h,
                  child: AudioFillBlanksCanvas(
                    text: quest.textWithBlanks ?? '',
                    revealProgress: revealProgress,
                    onSmear: onSmear,
                    primaryColor: theme.primaryColor,
                    isDark: isDark,
                    imageUrl: quest.imageUrl,
                    isCorrectState: isCorrect,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (level >= 8 && !isAnswered)
                  BlindDictationWrapper(
                    expectedText: quest.correctAnswer ?? quest.textToSpeak ?? '',
                    primaryColor: theme.primaryColor,
                    isPositioned: false,
                    onConfirmed: () => onBlindSubmit(true),
                    onSkipped: () => onBlindSubmit(false),
                  )
                else ...[
                  AudioFillBlanksInput(
                    controller: controller,
                    isAnswered: isAnswered,
                    primaryColor: theme.primaryColor,
                    maxLength: maxInputLength,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  SizedBox(height: 16.h),
                  if (!isAnswered)
                    _SubmitButton(
                      isCompact: false,
                      primaryColor: theme.primaryColor,
                      onTap: onSubmit,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _SubmitButton
// =============================================================================

class _SubmitButton extends StatelessWidget {
  final bool isCompact;
  final Color primaryColor;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.isCompact,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Submit transcription',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: isCompact ? 50.h : 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: primaryColor,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'SUBMIT TRANSCRIPTION',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
