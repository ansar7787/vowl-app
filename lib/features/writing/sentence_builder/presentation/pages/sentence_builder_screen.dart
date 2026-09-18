import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_instruction.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_workbench.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_piece_pool.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_keyboard_input.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

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

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> with WritingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  // PERF FIX: cached so getTheme() isn't called on every build().
  late dynamic _theme;

  dynamic _lastQuest;

  final _textController = TextEditingController();
  final ValueNotifier<List<String>> _assembledPieces = ValueNotifier([]);
    final ValueNotifier<bool> _showTypeToConfirm = ValueNotifier(false);
  late final ScrollController _scrollController;

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
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _scrollController = ScrollController();
    _theme = LevelThemeHelper.getTheme('writing', level: widget.level);
    initWritingGame();
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
    _scrollController.dispose();
    _textController.dispose();
    _assembledPieces.dispose();
        _showTypeToConfirm.dispose();
    disposeWritingGame();
    disposeWritingGame();
    disposeWritingGame();
    super.dispose();
  }

  void _onSnap(String piece, bool isAnswered) {
    if (isAnswered) return;
    hapticService.success();
    _assembledPieces.value = List.from(_assembledPieces.value)..add(piece);
  }

  void _onRemovePiece(int index, bool isAnswered) {
    if (isAnswered) return;
    hapticService.selection();
    _assembledPieces.value = List.from(_assembledPieces.value)..removeAt(index);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _submitAnswer(String correct, bool isAnswered) {
    final isHardMode = widget.level >= 6;
    if (isAnswered ||
        (!isHardMode && _assembledPieces.value.isEmpty) ||
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
        hapticService.selection();
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
        hapticService.selection();
        return;
      }
    }

    // FIX: normalize both sides before comparison.
    final built = _normalizeAnswer(
      isHardMode ? _textController.text : _assembledPieces.value.join(' '),
    );
    final expected = _normalizeAnswer(correct);
    final isCorrect = built == expected;

    if (isCorrect) {
      hapticService.success();
      if (isHardMode) {
        // They already typed it manually, no need to type to confirm.
        context.read<WritingBloc>().add(const SubmitAnswer(true));
      } else {
        _showTypeToConfirm.value = true;
        _scrollToBottom();
      }
    } else {
      hapticService.error();
      context.read<WritingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onTypeConfirmed() {
    _showTypeToConfirm.value = false;
    context.read<WritingBloc>().add(const SubmitAnswer(true));
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
              prev.answerStatus != curr.answerStatus),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded) {
          _lastQuest = state.currentQuest;
        }
        final quest = isLoaded ? state.currentQuest : _lastQuest;
        final pool = quest?.shuffledWords ?? const [];
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        final lives = state.livesRemaining;
        final isFinalFailure = isLoaded ? state.isFinalFailure : (lives == 0);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () {},
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _showTypeToConfirm,
              _assembledPieces,
            ]),
            builder: (context, _) {
              return quest == null
                  ? const SizedBox.shrink()
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: _theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: _SentenceBuilderBody(
                        quest: quest,
                        pool: pool,
                        level: widget.level,
                        textController: _textController,
                        assembledPieces: _assembledPieces.value,
                        isAnswered: isAnswered,
                        isCorrect: isCorrect,
                        theme: _theme,
                        isDark: isDark,
                        scrollController: _scrollController,
                        showTypeToConfirm: _showTypeToConfirm.value,
                        onSnap: (piece) => _onSnap(piece, isAnswered),
                        onRemovePiece: (idx) => _onRemovePiece(idx, isAnswered),
                        onSubmit: () => _submitAnswer(
                          quest.correctAnswer ?? '',
                          isAnswered,
                        ),
                        onTypeConfirmed: _onTypeConfirmed,
                        onSkipped: () {
                          _showTypeToConfirm.value = false;
                          context.read<WritingBloc>().add(
                            const SubmitAnswer(false),
                          );
                        },
                      ),
                    );
            },
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
  final ScrollController scrollController;
  final bool showTypeToConfirm;
  final ValueChanged<String> onSnap;
  final ValueChanged<int> onRemovePiece;
  final VoidCallback onSubmit;
  final VoidCallback onTypeConfirmed;
  final VoidCallback onSkipped;

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
    required this.scrollController,
    required this.showTypeToConfirm,
    required this.onSnap,
    required this.onRemovePiece,
    required this.onSubmit,
    required this.onTypeConfirmed,
    required this.onSkipped,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          sliver: SliverToBoxAdapter(
            child: AbsorbPointer(
              absorbing: showTypeToConfirm,
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  SentenceBuilderInstruction(
                    primaryColor: theme.primaryColor,
                    instruction: InstructionHelper.getInstruction(quest),
                  ),
                  SizedBox(height: 16.h),
                  if (quest.sentenceType != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        quest.sentenceType!.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
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
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: 40.h),
              if (!isAnswered && !showTypeToConfirm)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: _SubmitButton(theme: theme, onTap: onSubmit),
                ),
              if (showTypeToConfirm && !isAnswered)
                TypeToConfirmOverlay(
                  expectedText: quest.correctAnswer ?? '',
                  primaryColor: theme.primaryColor,
                  onConfirmed: onTypeConfirmed,
                  onSkipped: onSkipped,
                  isPositioned: false, // Renders inline instead of stacked!
                ),
              SizedBox(
                height: !isAnswered
                    ? ((level >= 6 || showTypeToConfirm)
                          ? MediaQuery.viewInsetsOf(context).bottom + 40.h
                          : 60.h)
                    : 160.h,
              ),
            ],
          ),
        ),
      ],
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




