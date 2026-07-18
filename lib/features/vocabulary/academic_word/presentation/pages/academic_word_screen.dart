import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/academic_word/academic_word_constants.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_painters.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_instruction.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_thesis_paper.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_shard.dart';

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

class _AcademicWordScreenState extends State<AcademicWordScreen> {
  final HapticService _hapticService = di.sl<HapticService>();
  final SoundService _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  Offset _dragOffset = Offset.zero;
  int? _activeShardIndex;
  BoxConstraints? _dragConstraints;

  final GlobalKey _slotKey = GlobalKey();

  // Use dynamic so this works regardless of the actual return type of
  // LevelThemeHelper.getTheme() in your codebase.
  late dynamic _cachedTheme;

  @override
  void initState() {
    super.initState();
    _cachedTheme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
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
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: _onStateChange,
      builder: _buildScreen,
    );
  }

  // ── Listener — ALL setState() calls live here only ────────────────────────

  void _onStateChange(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
      final isNewQuestion = state.currentIndex != _lastProcessedIndex;
      final isRetry = _isAnswered && state.lastAnswerCorrect == null;

      if (isNewQuestion || isRetry) {
        setState(() {
          _lastQuest = state.currentQuest;
          _lastProcessedIndex = state.currentIndex;
          _isAnswered = false;
          _isCorrect = null;
          _dragOffset = Offset.zero;
          _activeShardIndex = null;
        });
        return;
      }

      if (state.lastAnswerCorrect != null && !_isAnswered) {
        setState(() {
          _isAnswered = true;
          _isCorrect = state.lastAnswerCorrect;
        });
      }
    }

    if (state is VocabularyGameComplete) {
      setState(() => _showConfetti = true);
      if (!mounted) return;
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        title: AcademicWordStrings.completionTitle,
        enableDoubleUp: true,
      );
      // Reset confetti after 3 seconds so it does not replay on re-entry.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showConfetti = false);
      });
      return;
    }
  }

  // ── Builder — NO setState() here ─────────────────────────────────────────

  Widget _buildScreen(BuildContext context, VocabularyState state) {
    final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
    final loadedState = state is VocabularyLoaded ? state : null;

    if (state is VocabularyLoading ||
        (quest == null &&
            state is! VocabularyGameComplete &&
            state is! VocabularyError)) {
      return Scaffold(
        backgroundColor: AcademicWordColors.screenBackground,
        body: GameShimmerLoading(primaryColor: _cachedTheme.primaryColor),
      );
    }

    // Read from loadedState when available; fall back to cached instance
    // fields during state transitions (e.g. VocabularyLoading).
    final isAnswered = loadedState != null
        ? loadedState.lastAnswerCorrect != null
        : _isAnswered;
    final isCorrect = loadedState != null
        ? loadedState.lastAnswerCorrect
        : _isCorrect;

    return VocabularyBaseLayout(
      gameType: widget.gameType,
      level: widget.level,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      showConfetti: _showConfetti,
      onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
      onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
      useScrolling: false,
      disablePadding: true,
      child: quest == null
          ? const SizedBox.shrink()
          : _AcademicWordGameBody(
              quest: quest,
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              slotKey: _slotKey,
              activeShardIndex: _activeShardIndex,
              dragOffset: _dragOffset,
              themeColor: _cachedTheme.primaryColor,
              onShardTap: (i) => _attemptThrust(i, quest),
              onDragStart: _onShardDragStart,
              onDragUpdate: _onShardDragUpdate,
              onDragEnd: (i) => _onShardDragEnd(i, quest),
              getInitialPosition: _getShardInitialPosition,
            ),
    );
  }

  // ── Drag logic ────────────────────────────────────────────────────────────

  void _onShardDragStart(int index, BoxConstraints constraints) {
    if (_isAnswered) return;
    _dragConstraints = constraints;
    setState(() => _activeShardIndex = index);
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    if (_dragConstraints == null) return;

    final c = _dragConstraints!;
    final sw = AcademicWordShard.resolveWidth(c.maxWidth);
    final sh = AcademicWordShard.resolveHeight(c.maxHeight);
    final initial = _getShardInitialPosition(index, c.maxHeight, c.maxWidth);

    final minX = -(c.maxWidth / 2) + sw / 2 - initial.dx;
    final maxX = (c.maxWidth / 2) - sw / 2 - initial.dx;
    final minY = -(c.maxHeight / 2) + sh / 2 - initial.dy;
    final maxY = (c.maxHeight / 2) - sh / 2 - initial.dy;

    final newOffset = _dragOffset + details.delta;
    setState(() {
      _dragOffset = Offset(
        newOffset.dx.clamp(minX, maxX),
        newOffset.dy.clamp(minY, maxY),
      );
    });

    if (_isNearSlot()) _hapticService.selection();
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;
    if (_isNearSlot()) {
      _attemptThrust(index, quest);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  // ── Answer submission ─────────────────────────────────────────────────────

  void _attemptThrust(int index, VocabularyQuest quest) {
    final options = quest.options;
    if (options == null || index >= options.length) return;

    final selected = options[index].trim().toLowerCase();
    final correct = quest.correctAnswer?.trim().toLowerCase() ?? '';

    if (selected == correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _activeShardIndex = null;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _activeShardIndex = null;
        _dragOffset = Offset.zero;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  // ── Geometry helpers ──────────────────────────────────────────────────────

  bool _isNearSlot() {
    if (_activeShardIndex == null || _dragConstraints == null) return false;
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
      _activeShardIndex!,
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
    return _getShardInitialPosition(index, maxHeight, maxWidth) + _dragOffset;
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
              label: context.tr(
                'games.academic_word_instruction',
                fallback: "Drag the precise word into the passage.",
              ),
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
