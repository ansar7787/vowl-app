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
                  onSmear: _onSmear,
                  onPlayAudio: () => _playAudio(quest.textToSpeak),
                  onSubmit: () => _submitAnswer(quest.correctAnswer),
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
  final void Function(double) onSmear;
  final VoidCallback onPlayAudio;
  final VoidCallback onSubmit;

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
    required this.onSmear,
    required this.onPlayAudio,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < compactThreshold;

        // Distribute remaining vertical space proportionally across the 7
        // gap slots so the layout breathes naturally on every device height.
        final double canvasH = isCompact ? 150.h : 220.h;
        final double jarH = isCompact ? 80.h : 100.h;
        final double instructionH = isCompact ? 35.h : 40.h;
        final double submitH = isAnswered ? 0.0 : (isCompact ? 50.h : 60.h);

        final double fixed =
            instructionH + jarH + canvasH + submitH + 60.h /* input */;
        final double remaining = (maxHeight - fixed).clamp(
          0.0,
          double.infinity,
        );
        final double unit = remaining / 7;

        final double gapTop = (unit * 1.0).clamp(6.0, 16.0);
        final double gapInstruction = (unit * 1.0).clamp(10.0, 24.0);
        final double gapJar = (unit * 1.5).clamp(10.0, 24.0);
        final double gapCanvas = (unit * 1.5).clamp(10.0, 24.0);
        final double gapInput = (unit * 1.0).clamp(10.0, 20.0);
        final double gapBottom = (unit * 1.0).clamp(10.0, 24.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top section: instruction + jar + canvas ───────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: gapTop),

                    // Instruction badge
                    isCompact
                        ? SizedBox(
                            height: instructionH,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AudioFillBlanksInstruction(
                                instruction:
                                    quest.instruction ??
                                    'LISTEN TO THE AUDIO AND TYPE THE MISSING WORD',
                                color: theme.primaryColor,
                              ),
                            ),
                          )
                        : AudioFillBlanksInstruction(
                            instruction:
                                quest.instruction ??
                                'LISTEN TO THE AUDIO AND TYPE THE MISSING WORD',
                            color: theme.primaryColor,
                          ),

                    SizedBox(height: gapInstruction),

                    // Audio jar
                    isCompact
                        ? SizedBox(
                            height: jarH,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AudioFillBlanksJar(
                                color: theme.primaryColor,
                                onTap: onPlayAudio,
                              ),
                            ),
                          )
                        : AudioFillBlanksJar(
                            color: theme.primaryColor,
                            onTap: onPlayAudio,
                          ),

                    SizedBox(height: gapJar),

                    // Ink-smear canvas
                    SizedBox(
                      height: canvasH,
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

                // ── Bottom section: input + submit ────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: gapCanvas),

                    AudioFillBlanksInput(
                      controller: controller,
                      isAnswered: isAnswered,
                      primaryColor: theme.primaryColor,
                      maxLength: maxInputLength,
                      onSubmitted: (_) => onSubmit(),
                    ),

                    SizedBox(height: gapInput),

                    if (!isAnswered)
                      _SubmitButton(
                        isCompact: isCompact,
                        primaryColor: theme.primaryColor,
                        onTap: onSubmit,
                      ),

                    SizedBox(height: gapBottom),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
