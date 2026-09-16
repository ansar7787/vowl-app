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
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_instruction.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_target_wall.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_ballista_ammo.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_keyboard_input.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_anagram_wrapper.dart';

// ---------------------------------------------------------------------------
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

  // PERF FIX: theme cached Ã¢â‚¬â€ not recomputed on every build().
  late dynamic _theme;

  final ValueNotifier<String?> _selectedProjectile = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _showAnagram = ValueNotifier(false);

  late final ScrollController _scrollController;

  GameQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    _selectedProjectile.dispose();
    _showConfetti.dispose();
    _showAnagram.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Answer logic
  // ---------------------------------------------------------------------------

  void _onFire(String selected, String correct, bool isAnswered) {
    if (isAnswered) return;

    _selectedProjectile.value = selected;

    final isCorrect =
        selected.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '') ==
        correct.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // We let the BLoC handle all state now! No local timers hiding the continue button!
    if (isCorrect) {
      _hapticService.success();
      _showAnagram.value = true;
      _scrollToBottom();
    } else {
      _hapticService.error();
      context.read<WritingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onAnagramSuccess() {
    _showAnagram.value = false;
    context.read<WritingBloc>().add(const SubmitAnswer(true));
  }

  void _onAnagramFailed() {
    _showAnagram.value = false;
    context.read<WritingBloc>().add(const SubmitAnswer(false));
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
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          // New question loaded or retry triggered Ã¢â‚¬â€ clear the selected option.
          _selectedProjectile.value = null;
          _showAnagram.value = false;
        }
        if (state is WritingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'COMPLETION MASTER!',
            enableDoubleUp: true,
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
              prev.answerStatus != curr.answerStatus),
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded) {
          _lastQuest = state.currentQuest;
        }

        final quest = isLoaded ? state.currentQuest : _lastQuest;
        final options = quest?.options ?? const [];
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = isLoaded
            ? state.isFinalFailure
            : (state.livesRemaining == 0);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          // FIX: WritingHintUsed is dispatched inside WritingGameHeader.
          // Passing it here caused a double dispatch â€” now a no-op.
          onHint: () {},
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _showConfetti,
              _selectedProjectile,
              _showAnagram,
            ]),
            builder: (context, _) {
              return quest == null
                  ? (_lastQuest == null
                        ? GameShimmerLoading(primaryColor: _theme.primaryColor)
                        : const SizedBox.shrink())
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: _theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: _CompleteSentenceBody(
                        quest: quest,
                        options: options,
                        level: widget.level,
                        selectedProjectile: _selectedProjectile.value,
                        isAnswered: isAnswered,
                        isCorrect: isCorrect,
                        theme: _theme,
                        isDark: isDark,
                        scrollController: _scrollController,
                        showAnagram: _showAnagram.value,
                        onAnagramSuccess: _onAnagramSuccess,
                        onAnagramFailed: _onAnagramFailed,
                        // FIX: screen owns correctAnswer â€” widgets only report selected.
                        onFire: (selected) => _onFire(
                          selected,
                          quest.correctAnswer ?? '',
                          isAnswered,
                        ),
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
  final ScrollController scrollController;
  final bool showAnagram;
  final VoidCallback onAnagramSuccess;
  final VoidCallback onAnagramFailed;
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
    required this.scrollController,
    required this.showAnagram,
    required this.onAnagramSuccess,
    required this.onAnagramFailed,
    required this.onFire,
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
              absorbing: showAnagram,
              child: Opacity(
                opacity: showAnagram ? 0.5 : 1.0,
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    CompleteSentenceInstruction(
                      primaryColor: theme.primaryColor,
                    ),
                    if (quest.grammarFocus != null) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.rule,
                              color: theme.primaryColor,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              quest.grammarFocus!,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            message:
                                "Hard Mode! Dragging is disabled. Please type your answer below.",
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
                        // FIX: onFire now receives only the fired word.
                        onFire: onFire,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showAnagram && !isAnswered)
          SliverPadding(
            padding: EdgeInsets.only(top: 32.h, left: 24.w, right: 24.w),
            sliver: SliverToBoxAdapter(
              child: DynamicAnagramWrapper(
                expectedText: quest.correctAnswer ?? '',
                primaryColor: theme.primaryColor,
                onConfirmed: onAnagramSuccess,
                onFailed: onAnagramFailed,
                isPositioned: false,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: !isAnswered
                ? MediaQuery.viewInsetsOf(context).bottom + 40.h
                : 60.h,
          ), // Bottom docking padding
        ),
      ],
    );
  }
}

