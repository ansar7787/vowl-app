import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_instruction.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_target_wall.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_ballista_ammo.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_trajectory_painter.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_keyboard_input.dart';

// ---------------------------------------------------------------------------
// Immutable record for drag state â€” replaces two nullable Offset fields.
// ---------------------------------------------------------------------------
class _DragState {
  final Offset start;
  final Offset current;
  const _DragState({required this.start, required this.current});
}

class CompleteSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const CompleteSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.completeSentence,
  });

  @override
  State<CompleteSentenceScreen> createState() => _CompleteSentenceScreenState();
}

class _CompleteSentenceScreenState extends State<CompleteSentenceScreen> {
  final _hapticService = di.sl<HapticService>();

  // PERF FIX: theme cached â€” not recomputed on every build().
  late dynamic _theme;

  final _stackKey = GlobalKey();

  // PERF FIX: drag state moved to ValueNotifier so _onBridgeUpdate never
  // calls setState. Only the ValueListenableBuilder around the CustomPaint
  // rebuilds on each pointer-move event (~60fps), not the entire widget tree.
  final _dragNotifier = ValueNotifier<_DragState?>(null);

  String? _selectedProjectile;
  bool _showConfetti = false;

  GameQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    _theme = LevelThemeHelper.getTheme('writing', level: widget.level);
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void didUpdateWidget(CompleteSentenceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _theme = LevelThemeHelper.getTheme('writing', level: widget.level);
    }
  }

  @override
  void dispose() {
    _dragNotifier.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Drag / trajectory handlers
  // ---------------------------------------------------------------------------

  void _onBridgeStart(Offset globalPosition, bool isAnswered) {
    if (isAnswered) return;
    // FIX: Use the stack's render box, not the screen's, to ensure the
    // trajectory start point aligns with the dragged card exactly.
    final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPos = renderBox.globalToLocal(globalPosition);
    // No setState â€” only update the notifier. Only the painter redraws.
    _dragNotifier.value = _DragState(start: localPos, current: localPos);
    _hapticService.selection();
  }

  void _onBridgeUpdate(Offset globalPosition, bool isAnswered) {
    if (isAnswered || _dragNotifier.value == null) return;
    final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    // PERF FIX: no setState â€” ValueNotifier update only repaints the CustomPaint.
    _dragNotifier.value = _DragState(
      start: _dragNotifier.value!.start,
      current: renderBox.globalToLocal(globalPosition),
    );
  }

  // ---------------------------------------------------------------------------
  // Answer logic
  // ---------------------------------------------------------------------------

  void _onFire(String selected, String correct, bool isAnswered) {
    if (isAnswered) return;

    setState(() {
      _selectedProjectile = selected;
    });

    final isCorrect =
        selected.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '') == correct.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Clear trajectory immediately on fire â€” no lingering aim line.
    _dragNotifier.value = null;

    // We let the BLoC handle all state now! No local timers hiding the continue button!
    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is WritingLoaded && state.lastAnswerCorrect == null) {
          // New question loaded or retry triggered â€” clear the selected option.
          setState(() {
            _selectedProjectile = null;
            _dragNotifier.value = null;
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'COMPLETION MASTER!',
            enableDoubleUp: true,
          );
        }
        if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<WritingBloc>().add(const RestoreLife()),
          );
        }
      },
      // PERF FIX: only rebuild when quest changes, not on hint/wrong-count updates.
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
        final options = quest?.options ?? const [];
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          // FIX: WritingHintUsed is dispatched inside WritingGameHeader.
          // Passing it here caused a double dispatch â€” now a no-op.
          onHint: () {},
          child: quest == null
              ? (_lastQuest == null
                  ? GameShimmerLoading(primaryColor: _theme.primaryColor)
                  : const SizedBox.shrink())
              : Stack(
                  key: _stackKey,
                  children: [
                    // Scrollable body content â€” extracted to reduce build() size.
                    _CompleteSentenceBody(
                      quest: quest,
                      options: options,
                      level: widget.level,
                      selectedProjectile: _selectedProjectile,
                      isAnswered: isAnswered,
                      isCorrect: isCorrect,
                      theme: _theme,
                      isDark: isDark,
                      onBridgeStart: (pos) => _onBridgeStart(pos, isAnswered),
                      onBridgeUpdate: (pos) => _onBridgeUpdate(pos, isAnswered),
                      // FIX: screen owns correctAnswer â€” widgets only report selected.
                      onFire: (selected) => _onFire(
                        selected,
                        quest.correctAnswer ?? '',
                        isAnswered,
                      ),
                    ),
                    // PERF FIX: ValueListenableBuilder isolates repaints to this
                    // subtree only. The RepaintBoundary prevents the parent layer
                    // from being invalidated on each drag-move frame.
                    ValueListenableBuilder<_DragState?>(
                      valueListenable: _dragNotifier,
                      builder: (_, drag, _) {
                        if (drag == null) return const SizedBox.shrink();
                        return IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: CompleteSentenceTrajectoryPainter(
                                start: drag.start,
                                end: drag.current,
                                color: _theme.primaryColor,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CompleteSentenceBody
// Extracted from the builder lambda to keep build() readable and avoid
// re-allocating the full widget tree on unrelated state changes.
// ---------------------------------------------------------------------------
class _CompleteSentenceBody extends StatelessWidget {
  final dynamic quest;
  final List<String> options;
  final int level;
  final String? selectedProjectile;
  final bool isAnswered;
  final bool? isCorrect;
  final dynamic theme;
  final bool isDark;
  final ValueChanged<Offset> onBridgeStart;
  final ValueChanged<Offset> onBridgeUpdate;
  final ValueChanged<String> onFire;

  const _CompleteSentenceBody({
    required this.quest,
    required this.options,
    required this.level,
    required this.selectedProjectile,
    required this.isAnswered,
    required this.isCorrect,
    required this.theme,
    required this.isDark,
    required this.onBridgeStart,
    required this.onBridgeUpdate,
    required this.onFire,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            CompleteSentenceInstruction(primaryColor: theme.primaryColor),
            SizedBox(height: 32.h),
            CompleteSentenceTargetWall(
              text: quest.partialSentence ?? '',
              injected: selectedProjectile,
              color: theme.primaryColor,
              isDark: isDark,
              // FIX: onFire now receives only the selected word.
              // correctAnswer comparison is handled in the screen.
              onFire: onFire,
            ),
            SizedBox(height: 32.h),
            if (level >= 6) ...[
              GestureDetector(
                onTap: () {
                  CustomSnackBar.show(
                    context: context,
                    message: "Hard Mode! Dragging is disabled. Please type your answer below.",
                    type: CustomSnackBarType.info,
                  );
                },
                child: AbsorbPointer(
                  child: Opacity(
                    opacity: 0.8,
                    child: CompleteSentenceBallistaAmmo(
                      options: options,
                      color: theme.primaryColor,
                      isDark: isDark,
                      onBridgeStart: (_) {},
                      onBridgeUpdate: (_) {},
                      onFire: (_) {},
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              CompleteSentenceKeyboardInput(
                color: theme.primaryColor,
                isDark: isDark,
                onFire: onFire,
              ),
            ] else
              CompleteSentenceBallistaAmmo(
                options: options,
                color: theme.primaryColor,
                isDark: isDark,
                onBridgeStart: onBridgeStart,
                onBridgeUpdate: onBridgeUpdate,
                // FIX: onFire now receives only the fired word.
                onFire: onFire,
              ),
            SizedBox(
              height: 160.h,
            ), // Provide enough bottom padding for the WritingFeedbackCard
          ],
        ),
      ),
    );
  }
}


