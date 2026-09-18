import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/academic_word/academic_word_constants.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_painters.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_instruction.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_thesis_paper.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_shard.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_field_collocations.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/utils/instruction_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public screen widget
// ─────────────────────────────────────────────────────────────────────────────

class AcademicWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const AcademicWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.academicWord,
  });
  @override
  State<AcademicWordScreen> createState() => _AcademicWordScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _AcademicWordScreenState extends State<AcademicWordScreen> with VocabularyGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;
  @override
  int get level => widget.level;
  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

        final ValueNotifier<bool> _isDragPassed = ValueNotifier(false);
  final ValueNotifier<String?> _misspelledWord = ValueNotifier(null);
  final ValueNotifier<bool> _isSlotSelected = ValueNotifier(false);

  final ScrollController _scrollController = ScrollController();

    VocabularyQuest? _lastQuest;

  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<int?> _activeShardIndex = ValueNotifier(null);
  BoxConstraints? _dragConstraints;
  @override
  void dispose() {
                _isDragPassed.dispose();
    _misspelledWord.dispose();
    _isSlotSelected.dispose();
    _dragOffset.dispose();
    _activeShardIndex.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  final GlobalKey _slotKey = GlobalKey();

  // Use dynamic so this works regardless of the actual return type of
  // LevelThemeHelper.getTheme() in your codebase.
  late dynamic _cachedTheme;
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

    _cachedTheme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    initVocabularyGame();
  }
  @override
  void didUpdateWidget(covariant AcademicWordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _cachedTheme = LevelThemeHelper.getTheme(
        'vocabulary',
        level: widget.level,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  void onQuestionReset() {
    _isDragPassed.value = false;
    _misspelledWord.value = null;
    _isSlotSelected.value = false;
    _dragOffset.value = Offset.zero;
    _activeShardIndex.value = null;
  }
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: _onStateChange,
      builder: _buildScreen,
    );
  }

  // ── Listener ──────────────────────────────────────────────────────────────

  void _onStateChange(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
      final isNewQuestion = state.currentIndex != lastProcessedIndex;
      final isRetry = isAnsweredNotifier.value && !state.answerStatus.isAnswered;

      if (isNewQuestion || isRetry) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
          );
        }
        _lastQuest = state.currentQuest;
        lastProcessedIndex = state.currentIndex;
        _dragOffset.value = Offset.zero;
        _activeShardIndex.value = null;

        isAnsweredNotifier.value = false;
        isCorrectNotifier.value = null;
        _isDragPassed.value = false;
        _misspelledWord.value = null;
        _isSlotSelected.value = false;
        return;
      }

      if (state.answerStatus.isAnswered && !isAnsweredNotifier.value) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = state.answerStatus.asBoolOrNull;
      }
    }

    if (state is VocabularyGameComplete) {
      showConfettiNotifier.value = true;
      if (!mounted) return;
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        enableDoubleUp: true,
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) showConfettiNotifier.value = false;
      });
      return;
    }
  }

  // ── Builder ──────────────────────────────────────────────────────────────

  Widget _buildScreen(BuildContext context, VocabularyState state) {
    final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;

    return ListenableBuilder(
      listenable: Listenable.merge([
        isAnsweredNotifier,
        isCorrectNotifier,
        showConfettiNotifier,
        _isDragPassed,
        _misspelledWord,
        _isSlotSelected,
        _dragOffset,
        _activeShardIndex,
      ]),
      builder: (context, _) {
        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnsweredNotifier.value,
          isCorrect: isCorrectNotifier.value,
          showConfetti: showConfettiNotifier.value,
          hasStage2: true,
          onContinue: () {
            final currentState = context.read<VocabularyBloc>().state;
            if (currentState is VocabularyLoaded &&
                !currentState.isFinalFailure &&
                isCorrectNotifier.value == false) {
              isAnsweredNotifier.value = false;
              isCorrectNotifier.value = null;
              _isDragPassed.value = false;
              _misspelledWord.value = null;
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              }
            } else {
              context.read<VocabularyBloc>().add(NextQuestion());
            }
          },
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          disablePadding: true,
          child: quest == null
              ? GameShimmerLoading(primaryColor: Theme.of(context).primaryColor)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardHeight = MediaQuery.of(
                      context,
                    ).viewInsets.bottom;
                    final trueMaxHeight = constraints.maxHeight;

                    return Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: _cachedTheme
                              .of(context)
                              .primaryColor
                              .withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: (!_isDragPassed.value)
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: trueMaxHeight,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: trueMaxHeight,
                                        child: IgnorePointer(
                                          ignoring: _isDragPassed.value,
                                          child: _AcademicWordGameBody(
                                            quest: quest,
                                            isAnswered: isAnsweredNotifier.value,
                                            isCorrect: isCorrectNotifier.value,
                                            isFirstStagePassed:
                                                _isDragPassed.value,
                                            misspelledWord:
                                                _misspelledWord.value,
                                            isSlotSelected:
                                                _isSlotSelected.value,
                                            onSlotTap: () {
                                              hapticService.light();
                                              _isSlotSelected.value =
                                                  !_isSlotSelected.value;
                                            },
                                            slotKey: _slotKey,
                                            activeShardIndex:
                                                _activeShardIndex.value,
                                            dragOffset: _dragOffset.value,
                                            themeColor: _cachedTheme
                                                .of(context)
                                                .primaryColor,
                                            onShardTap: (i) =>
                                                _attemptThrust(i, quest),
                                            onDragStart: _onShardDragStart,
                                            onDragUpdate: _onShardDragUpdate,
                                            onDragEnd: (i) =>
                                                _onShardDragEnd(i, quest),
                                            getInitialPosition:
                                                _getShardInitialPosition,
                                          ),
                                        ),
                                      ),
                                      if (_isDragPassed.value)
                                        Column(
                                          children: [
                                            SizedBox(height: 10.h),
                                            if (quest.academicField != null ||
                                                (quest.collocations != null &&
                                                    quest
                                                        .collocations!
                                                        .isNotEmpty) ||
                                                quest.contextSentence != null ||
                                                quest.example != null)
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20.w,
                                                ),
                                                child:
                                                    AcademicWordFieldCollocations(
                                                      academicField:
                                                          quest.academicField,
                                                      collocations:
                                                          quest.collocations,
                                                      contextSentence:
                                                          quest
                                                              .contextSentence ??
                                                          quest.example,
                                                      color: _cachedTheme
                                                          .primaryColor,
                                                    ),
                                              ),
                                            if (_isDragPassed.value &&
                                                !isAnsweredNotifier.value)
                                              Column(
                                                children: [
                                                  SizedBox(height: 24.h),
                                                  TypeToConfirmOverlay(
                                                    expectedText:
                                                        quest.correctAnswer ??
                                                        '',
                                                    primaryColor: _cachedTheme
                                                        .primaryColor,
                                                    onConfirmed: () =>
                                                        _submitFinalAnswer(
                                                          true,
                                                        ),
                                                    onSkipped: () =>
                                                        _submitFinalAnswer(
                                                          false,
                                                        ),
                                                    onBypassed: () =>
                                                        _submitFinalAnswer(
                                                          true,
                                                        ),
                                                    isPositioned: false,
                                                  ),
                                                ],
                                              ),
                                            SizedBox(
                                              height: 80.h + keyboardHeight,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ], // closes slivers
                          ), // closes CustomScrollView
                        ), // closes RawScrollbar
                      ], // closes Stack children
                    ); // closes Stack
                  },
                ),
        );
      },
    );
  }

  // ── Drag logic ────────────────────────────────────────────────────────────

  void _onShardDragStart(int index, BoxConstraints constraints) {
    if (isAnsweredNotifier.value) return;
    _dragConstraints = constraints;
    _activeShardIndex.value = index;
    hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (isAnsweredNotifier.value || _activeShardIndex.value != index) return;
    if (_dragConstraints == null) return;

    final c = _dragConstraints!;
    final sw = AcademicWordShard.resolveWidth(c.maxWidth);
    final sh = AcademicWordShard.resolveHeight(c.maxHeight);
    final initial = _getShardInitialPosition(index, c.maxHeight, c.maxWidth);

    final minX = -(c.maxWidth / 2) + sw / 2 - initial.dx;
    final maxX = (c.maxWidth / 2) - sw / 2 - initial.dx;
    final minY = -(c.maxHeight / 2) + sh / 2 - initial.dy;
    final maxY = (c.maxHeight / 2) - sh / 2 - initial.dy;

    final newOffset = _dragOffset.value + details.delta;
    _dragOffset.value = Offset(
      newOffset.dx.clamp(minX, maxX),
      newOffset.dy.clamp(minY, maxY),
    );

    if (_isNearSlot()) hapticService.selection();
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (isAnsweredNotifier.value || _activeShardIndex.value != index) return;
    if (_isNearSlot()) {
      _attemptThrust(index, quest);
    } else {
      _dragOffset.value = Offset.zero;
      _activeShardIndex.value = null;
      hapticService.light();
    }
  }

  // ── Answer submission ─────────────────────────────────────────────────────

  void _attemptThrust(int index, VocabularyQuest quest) {
    final options = quest.options;
    if (options == null || index >= options.length || _isDragPassed.value) {
      return;
    }

    final selected = options[index].trim().toLowerCase();
    final correct = quest.correctAnswer?.trim().toLowerCase() ?? '';

    if (selected == correct) {
      hapticService.selection();
      _isSlotSelected.value = false;
      _isDragPassed.value = true;
      _activeShardIndex.value = null;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      _isSlotSelected.value = false;
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _activeShardIndex.value = null;
      _dragOffset.value = Offset.zero;
      _misspelledWord.value = options[index];
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool nailedIt, {String? wrongWord}) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    if (wrongWord != null && wrongWord.isNotEmpty) {
      _misspelledWord.value = wrongWord;
    }

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  // ── Geometry helpers ──────────────────────────────────────────────────────

  bool _isNearSlot() {
    if (_activeShardIndex.value == null || _dragConstraints == null) {
      return false;
    }
    if (!mounted) return false;

    final slotBox = _slotKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = context.findRenderObject() as RenderBox?;
    if (slotBox == null || stackBox == null) return false;

    final slotPos = slotBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final stackCenter = stackBox.size.center(Offset.zero);
    final targetCenter = slotPos + slotBox.size.center(Offset.zero);
    final targetOffsetFromCenter = targetCenter - stackCenter;

    final c = _dragConstraints!;
    final currentPos = _getShardCurrentPosition(
      _activeShardIndex.value!,
      c.maxHeight,
      c.maxWidth,
    );

    final snapRadius = AcademicWordShard.resolveWidth(c.maxWidth) * 0.55;
    return (currentPos - targetOffsetFromCenter).distance < snapRadius;
  }

  Offset _getShardCurrentPosition(
    int index,
    double maxHeight,
    double maxWidth,
  ) {
    return _getShardInitialPosition(index, maxHeight, maxWidth) +
        _dragOffset.value;
  }

  Offset _getShardInitialPosition(
    int index,
    double maxHeight,
    double maxWidth,
  ) {
    final isUltraCompact = maxHeight < AcademicWordLayout.ultraCompactHeight;
    final isCompact =
        !isUltraCompact && maxHeight < AcademicWordLayout.compactHeight;

    final double vStep = isUltraCompact
        ? (maxHeight * 0.13).clamp(36.0, 50.0)
        : isCompact
        ? (55.h).clamp(44.0, 60.0)
        : (90.h).clamp(60.0, 100.0);

    final double hStep = (maxWidth * 0.42).clamp(100.0, 170.0);

    final double startY = isUltraCompact
        ? maxHeight * 0.26
        : isCompact
        ? (95.h).clamp(70.0, 110.0)
        : (160.h).clamp(110.0, 180.0);

    final row = index ~/ 2;
    final col = index % 2;

    return Offset(col == 0 ? -hStep / 2 : hStep / 2, startY + (row * vStep));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted widget: game body (LayoutBuilder + Stack)
// ─────────────────────────────────────────────────────────────────────────────

typedef _ShardTapCallback = void Function(int index);
typedef _DragStartCallback =
    void Function(int index, BoxConstraints constraints);
typedef _DragUpdateCallback =
    void Function(int index, DragUpdateDetails details);
typedef _DragEndCallback = void Function(int index);
typedef _InitialPositionCallback =
    Offset Function(int index, double maxHeight, double maxWidth);

class _AcademicWordGameBody extends StatelessWidget {
  final VocabularyQuest quest;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFirstStagePassed;
  final String? misspelledWord;
  final bool isSlotSelected;
  final VoidCallback onSlotTap;
  final GlobalKey slotKey;
  final int? activeShardIndex;
  final Offset dragOffset;
  final Color themeColor;
  final _ShardTapCallback onShardTap;
  final _DragStartCallback onDragStart;
  final _DragUpdateCallback onDragUpdate;
  final _DragEndCallback onDragEnd;
  final _InitialPositionCallback getInitialPosition;

  const _AcademicWordGameBody({
    required this.quest,
    required this.isAnswered,
    required this.isCorrect,
    required this.isFirstStagePassed,
    required this.misspelledWord,
    required this.isSlotSelected,
    required this.onSlotTap,
    required this.slotKey,
    required this.activeShardIndex,
    required this.dragOffset,
    required this.themeColor,
    required this.onShardTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.getInitialPosition,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;
        final isUltraCompact =
            maxHeight < AcademicWordLayout.ultraCompactHeight;
        final isAnyCompact = maxHeight < AcademicWordLayout.compactHeight;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _buildBackground(isDark),
            _buildInstructionLabel(
              context: context,
              maxHeight: maxHeight,
              isUltraCompact: isUltraCompact,
              isAnyCompact: isAnyCompact,
            ),
            _buildThesisPaper(
              constraints: constraints,
              maxHeight: maxHeight,
              isUltraCompact: isUltraCompact,
              isAnyCompact: isAnyCompact,
            ),
            if (!isFirstStagePassed)
              ..._buildShards(
                constraints: constraints,
                maxHeight: maxHeight,
                maxWidth: maxWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: GridPainter(
            themeColor.withValues(alpha: isDark ? 0.05 : 0.03),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionLabel({
    required BuildContext context,
    required double maxHeight,
    required bool isUltraCompact,
    required bool isAnyCompact,
  }) {
    final topFraction = isUltraCompact
        ? 0.01
        : isAnyCompact
        ? 0.015
        : 0.04;
    return Positioned(
      top: maxHeight * topFraction,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          height: isAnyCompact ? (maxHeight * 0.07).clamp(28.0, 40.0) : null,
          child: FittedBox(
            fit: isAnyCompact ? BoxFit.scaleDown : BoxFit.none,
            child: AcademicWordInstruction(
              color: themeColor,
              label: InstructionHelper.getInstruction(quest),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThesisPaper({
    required BoxConstraints constraints,
    required double maxHeight,
    required bool isUltraCompact,
    required bool isAnyCompact,
  }) {
    final topFraction = isUltraCompact
        ? 0.08
        : isAnyCompact
        ? 0.10
        : 0.14;
    return Positioned(
      top: maxHeight * topFraction,
      left: 0,
      right: 0,
      child: SizedBox(
        height: isAnyCompact ? maxHeight * 0.36 : null,
        child: FittedBox(
          fit: isAnyCompact ? BoxFit.scaleDown : BoxFit.none,
          alignment: Alignment.topCenter,
          child: AcademicWordThesisPaper(
            passage: quest.passage ?? '',
            color: themeColor,
            slotKey: slotKey,
            isAnswered: isAnswered,
            isCorrect: isCorrect,
            correctAnswer: quest.correctAnswer,
            userSpelledWord: misspelledWord,
            isSlotSelected: isSlotSelected,
            onSlotTap: onSlotTap,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildShards({
    required BoxConstraints constraints,
    required double maxHeight,
    required double maxWidth,
  }) {
    final options = quest.options;
    if (options == null || options.isEmpty) return const [];

    return List.generate(options.length, (i) {
      return AcademicWordShard(
        index: i,
        text: options[i],
        color: themeColor,
        isDragging: activeShardIndex == i,
        offset: dragOffset,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        onTap: () => onShardTap(i),
        onDragStart: (_) => onDragStart(i, constraints),
        onDragUpdate: (d) => onDragUpdate(i, d),
        onDragEnd: (_) => onDragEnd(i),
        initialPosition: getInitialPosition(i, maxHeight, maxWidth),
      );
    });
  }
}





