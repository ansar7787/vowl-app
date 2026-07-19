import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_instruction.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_context_card.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_vortex.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_draggable_word.dart';

class PartsOfSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const PartsOfSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.partsOfSpeech,
  });

  @override
  State<PartsOfSpeechScreen> createState() => _PartsOfSpeechScreenState();
}

class _PartsOfSpeechScreenState extends State<PartsOfSpeechScreen> {
  // Services resolved in initState — not as field initializers.
  late final HapticService _hapticService;
  late final SoundService _soundService;

  Offset _dragOffset = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  /// Synchronous lock set BEFORE setState to prevent a race where multiple
  /// rapid onPanUpdate events all pass the `_isAnswered` guard before the
  /// first setState rebuild completes.
  bool _isSubmitting = false;

  /// Fallback part-of-speech labels when the quest has fewer than 4 options.
  static const List<String> _fallbackOptions = ['Noun', 'Verb', 'Adj', 'Adv'];

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _hapticService = di.sl<HapticService>();
    _soundService = di.sl<SoundService>();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  // -------------------------------------------------------------------------
  // Interaction
  // -------------------------------------------------------------------------

  void _onFlick(int targetIndex, int correctIndex) {
    if (_isAnswered || _isSubmitting) return;
    _isSubmitting = true; // Lock immediately — before any async work.

    final isCorrect = targetIndex == correctIndex;
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
    context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
  }

  void _checkCollision(int correctIndex, {required bool isCompact}) {
    final distance = _dragOffset.distance;
    final threshold = isCompact ? 60.r : 100.r;
    if (distance <= threshold) return;

    // Map quadrant → vortex index using a switch expression.
    final targetIndex = switch ((_dragOffset.dx < 0, _dragOffset.dy < 0)) {
      (true, true) => 0, // Top-Left
      (false, true) => 1, // Top-Right
      (true, false) => 2, // Bottom-Left
      (false, false) => 3, // Bottom-Right
    };
    _onFlick(targetIndex, correctIndex);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // : cache theme — widget.level is final, so the result is stable.
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: _onStateChange,
      builder: (context, state) {
        final quest = state is GrammarLoaded ? state.currentQuest : null;
        final options = (quest?.options?.length ?? 0) >= 4
            ? quest!.options!.sublist(0, 4)
            : _fallbackOptions;

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          child: quest == null
              ? const SizedBox.shrink()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 580;
                    return _PosQuestLayout(
                      quest: quest,
                      options: options,
                      theme: theme,
                      isDark: isDark,
                      isCompact: isCompact,
                      maxHeight: constraints.maxHeight,
                      dragOffset: _dragOffset,
                      isAnswered: _isAnswered,
                      onPanUpdate: (details) {
                        setState(() => _dragOffset += details.delta);
                        _checkCollision(
                          quest.correctAnswerIndex ?? 0,
                          isCompact: isCompact,
                        );
                      },
                      onPanEnd: (_) =>
                          setState(() => _dragOffset = Offset.zero),
                    );
                  },
                ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Listener — extracted to keep build() clean
  // -------------------------------------------------------------------------

  void _onStateChange(BuildContext context, GrammarState state) {
    if (state is GrammarLoaded) {
      final isNewQuestion = state.currentIndex != _lastProcessedIndex;
      // FIX: was `state.lastAnswerCorrect == null` → use AnswerStatus enum.
      final isRetry = _isAnswered && !state.answerStatus.isAnswered;
      final livesRestored =
          _lastLives != null && state.livesRemaining > _lastLives!;

      if (isNewQuestion || isRetry || livesRestored) {
        setState(() {
          _lastProcessedIndex = state.currentIndex;
          _isAnswered = false;
          _isCorrect = null;
          _dragOffset = Offset.zero;
          _isSubmitting = false; // Reset race guard on new question.
        });
      } else if (state.answerStatus.isAnswered && !_isAnswered) {
        // FIX: was `state.lastAnswerCorrect != null` and `state.lastAnswerCorrect`
        setState(() {
          _isAnswered = true;
          _isCorrect = state.answerStatus.asBoolOrNull;
        });
      }
      _lastLives = state.livesRemaining;
    }

    if (state is GrammarGameComplete) {
      setState(() => _showConfetti = true);
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        title: 'POS PRO!',
        enableDoubleUp: true,
      );
    }
      }
}

// =============================================================================
// Private layout widget — extracted to keep _PartsOfSpeechScreenState lean
// =============================================================================

class _PosQuestLayout extends StatelessWidget {
  final GrammarQuest quest;
  final List<String> options;
  final dynamic theme;
  final bool isDark;
  final bool isCompact;
  final double maxHeight;
  final Offset dragOffset;
  final bool isAnswered;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  static const _vortexColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
  ];

  static const _vortexAlignments = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  const _PosQuestLayout({
    required this.quest,
    required this.options,
    required this.theme,
    required this.isDark,
    required this.isCompact,
    required this.maxHeight,
    required this.dragOffset,
    required this.isAnswered,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  /// Distributes remaining vertical space across the three gaps proportionally,
  /// clamped so the layout never breaks on very small or very large screens.
  ({double top, double middle, double bottom}) _computeGaps() {
    final estimated =
        (isCompact ? 30.h : 40.h) +
        (isCompact ? 50.h : 80.h) +
        (isCompact ? 160.h : 260.h) +
        40.h;
    final remaining = (maxHeight - estimated).clamp(0.0, double.infinity);
    final unit = remaining / 5;
    return (
      top: (unit * 1.0).clamp(4.0, 15.0),
      middle: (unit * 1.5).clamp(6.0, 20.0),
      bottom: (unit * 2.5).clamp(10.0, 30.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gaps = _computeGaps();

    return Column(
      children: [
        SizedBox(height: gaps.top),
        _buildInstruction(),
        SizedBox(height: gaps.middle),
        SpeechContextCard(
          quest: quest,
          primaryColor: theme.primaryColor as Color,
          isDark: isDark,
          isCompact: isCompact,
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Corner vortex buckets
              for (int i = 0; i < 4; i++)
                SpeechVortex(
                  index: i,
                  label: options[i],
                  color: _vortexColors[i],
                  alignment: _vortexAlignments[i],
                  isCompact: isCompact,
                ),
              // Draggable word chip
              if (!isAnswered)
                GestureDetector(
                  onPanUpdate: onPanUpdate,
                  onPanEnd: onPanEnd,
                  child: Transform.translate(
                    offset: dragOffset,
                    child: Transform.rotate(
                      angle: dragOffset.dx / 100,
                      child: SpeechDraggableWord(
                        word: quest.targetWord ?? quest.word ?? '??',
                        primaryColor: theme.primaryColor as Color,
                        isDark: isDark,
                        isCompact: isCompact,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
        SizedBox(height: gaps.bottom),
      ],
    );
  }

  Widget _buildInstruction() {
    final instruction = SpeechInstruction(
      primaryColor: theme.primaryColor as Color,
    );
    if (!isCompact) return instruction;
    return SizedBox(
      height: 25.h,
      child: FittedBox(fit: BoxFit.scaleDown, child: instruction),
    );
  }
}
