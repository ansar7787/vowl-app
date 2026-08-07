import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_instruction.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_workbench.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_piece_pool.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_keyboard_input.dart';

class SentenceBuilderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SentenceBuilderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceBuilder,
  });

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _ttsService = di.sl<TtsService>();

  // PERF FIX: cached so getTheme() isn't called on every build().
  late dynamic _theme;

  dynamic _lastQuest;

  final _textController = TextEditingController();
  final List<String> _assembledPieces = [];
  bool _showConfetti = false;

  // FIX: full whitespace normalization to prevent false mismatches.
  // ".toLowerCase()" alone fails when correctAnswer has double-spaces or
  // when assembled pieces are joined with inconsistent spacing.
  static String _normalizeAnswer(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  @override
  void initState() {
    super.initState();
    _theme = LevelThemeHelper.getTheme('writing', level: widget.level);
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void didUpdateWidget(SentenceBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _theme = LevelThemeHelper.getTheme('writing', level: widget.level);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSnap(String piece, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.success();
    setState(() => _assembledPieces.add(piece));
  }

  void _onRemovePiece(int index, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    setState(() => _assembledPieces.removeAt(index));
  }

  void _submitAnswer(String correct, bool isAnswered) {
    final isHardMode = widget.level >= 6;
    if (isAnswered ||
        (!isHardMode && _assembledPieces.isEmpty) ||
        (isHardMode && _textController.text.trim().isEmpty)) {
      return;
    }

    if (isHardMode) {
      final rawText = _textController.text.trim();
      if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
        CustomSnackBar.show(
          context: context,
          message: "Please start your sentence with a capital letter.",
          type: CustomSnackBarType.warning,
        );
        _hapticService.selection();
        return;
      }

      final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
      if (!['.', '!', '?'].contains(lastChar)) {
        CustomSnackBar.show(
          context: context,
          message:
              "Please end your sentence with proper punctuation (., !, or ?).",
          type: CustomSnackBarType.warning,
        );
        _hapticService.selection();
        return;
      }
    }

    // FIX: normalize both sides before comparison.
    final built = _normalizeAnswer(
      isHardMode ? _textController.text : _assembledPieces.join(' '),
    );
    final expected = _normalizeAnswer(correct);
    final isCorrect = built == expected;

    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && prev is! WritingLoaded) ||
          (prev is WritingLoaded &&
              curr is WritingLoaded &&
              prev.lastAnswerCorrect != curr.lastAnswerCorrect),
      listener: (context, state) {
        if (state is WritingLoaded && state.lastAnswerCorrect == null) {
          // New question loaded or retry triggered â€” clear the selected option.
          setState(() {
            _assembledPieces.clear();
            _textController.clear();
          });
        }

        if (state is WritingLoaded && state.lastAnswerCorrect == true) {
          _ttsService.speak(state.currentQuest.correctAnswer ?? '');
        }

        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SYNTAX ARCHITECT!',
            enableDoubleUp: true,
          );
        }

        if (state is WritingGameOver) {
          // Handled globally by the base layout.
        }
      },
      // PERF FIX: only rebuild when the quest itself changes, not on every
      // hintUsed / wrongCount update (those are handled inside WritingBaseLayout).
      buildWhen: (prev, curr) =>
          prev.runtimeType != curr.runtimeType ||
          (prev is WritingLoaded &&
              curr is WritingLoaded &&
              prev.currentIndex != curr.currentIndex) ||
          (prev is WritingLoaded &&
              curr is WritingLoaded &&
              prev.lastAnswerCorrect != curr.lastAnswerCorrect),
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded) {
          _lastQuest = state.currentQuest;
        }
        final quest = isLoaded ? state.currentQuest : _lastQuest;
        final pool = quest?.shuffledWords ?? const [];
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

        final lives = state.livesRemaining;
        final isFinalFailure = isLoaded ? state.isFinalFailure : (lives == 0);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          // FIX: WritingHintUsed is already dispatched inside WritingGameHeader.
          // Passing it here too caused a double dispatch. onHint() is reserved
          // for any screen-specific side effects (currently none needed).
          onHint: () {},
          child: quest == null
              ? const SizedBox.shrink()
              : _SentenceBuilderBody(
                  quest: quest,
                  pool: pool,
                  level: widget.level,
                  textController: _textController,
                  assembledPieces: _assembledPieces,
                  isAnswered: isAnswered,
                  isCorrect: isCorrect,
                  theme: _theme,
                  isDark: isDark,
                  onSnap: (piece) => _onSnap(piece, isAnswered),
                  onRemovePiece: (idx) => _onRemovePiece(idx, isAnswered),
                  onSubmit: () =>
                      _submitAnswer(quest.correctAnswer ?? '', isAnswered),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SentenceBuilderBody
//
// Extracted from the builder lambda to reduce build() complexity and prevent
// unnecessary allocations of the full widget tree on unrelated state changes.
// ---------------------------------------------------------------------------
class _SentenceBuilderBody extends StatelessWidget {
  final dynamic quest;
  final List<String> pool;
  final int level;
  final TextEditingController textController;
  final List<String> assembledPieces;
  final bool isAnswered;
  final bool? isCorrect;
  final dynamic theme;
  final bool isDark;
  final ValueChanged<String> onSnap;
  final ValueChanged<int> onRemovePiece;
  final VoidCallback onSubmit;

  const _SentenceBuilderBody({
    required this.quest,
    required this.pool,
    required this.level,
    required this.textController,
    required this.assembledPieces,
    required this.isAnswered,
    required this.isCorrect,
    required this.theme,
    required this.isDark,
    required this.onSnap,
    required this.onRemovePiece,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          SentenceBuilderInstruction(
            primaryColor: theme.primaryColor,
            instruction: quest.instruction,
          ),
          SizedBox(height: 32.h),

          if (level >= 6) ...[
            GestureDetector(
              onTap: () {
                CustomSnackBar.show(
                  context: context,
                  message:
                      "Hard Mode! Dragging is disabled. Please type your answer below.",
                  type: CustomSnackBarType.info,
                );
              },
              child: AbsorbPointer(
                child: Opacity(
                  opacity: 0.8,
                  child: SentenceBuilderPiecePool(
                    pool: pool,
                    assembledPieces: const [],
                    color: theme.primaryColor,
                    isDark: isDark,
                    onSnap: (_) {},
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SentenceBuilderKeyboardInput(
              controller: textController,
              color: theme.primaryColor,
              isDark: isDark,
            ),
          ] else ...[
            SentenceBuilderWorkbench(
              assembledPieces: assembledPieces,
              color: theme.primaryColor,
              isDark: isDark,
              onSnap: onSnap,
              onRemovePiece: onRemovePiece,
            ),
            SizedBox(height: 32.h),
            SentenceBuilderPiecePool(
              pool: pool,
              assembledPieces: assembledPieces,
              color: theme.primaryColor,
              isDark: isDark,
              onSnap: onSnap,
            ),
          ],

          SizedBox(height: 40.h),
          if (!isAnswered) _SubmitButton(theme: theme, onTap: onSubmit),
          SizedBox(height: 60.h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SubmitButton â€” extracted for clarity and Semantics isolation
// ---------------------------------------------------------------------------
class _SubmitButton extends StatelessWidget {
  final dynamic theme;
  final VoidCallback onTap;

  const _SubmitButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Submit assembled sentence',
      button: true,
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: theme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'POLISH SENTENCE',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
