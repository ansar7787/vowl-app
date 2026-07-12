import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_game_body.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';

class FlashcardsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const FlashcardsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.flashcards,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final HapticService _hapticService = di.sl<HapticService>();
  final SoundService _soundService = di.sl<SoundService>();

  // ── Theme — updated in didChangeDependencies so dark-mode changes apply
  late ThemeResult _theme;

  // ── Game state ────────────────────────────────────────────────────────────
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isFlipped = false;
  bool _isAnswered = false;
  bool _isRetrying = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  bool _isHintActive = false;
  VocabularyQuest? _lastQuest;

  /// Cancellable hint-auto-flip timer.
  Timer? _hintTimer;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _theme = LevelThemeHelper.getTheme(widget.gameType.name, isDark: isDark);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  // ── Drag ─────────────────────────────────────────────────────────────────

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    if (_isRetrying) setState(() => _isRetrying = false);
    final oldDx = _dragOffset.dx;
    setState(() {
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, 0);
      _dragAngle = _dragOffset.dx / 500;
      if ((_dragOffset.dx - oldDx).abs() > 0 &&
          (_dragOffset.dx.abs() % 20 < 2)) {
        _hapticService.selection();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double threshold) {
    if (_isAnswered) return;
    if (_dragOffset.dx.abs() > threshold) {
      _submitAnswer(_dragOffset.dx > 0);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
      });
    }
  }

  // ── Answer submission ─────────────────────────────────────────────────────

  void _submitAnswer(bool mastered) {
    if (_isAnswered) return;
    // Fire-and-forget: audio/haptic must not block the immediate card animation.
    if (mastered) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }
    setState(() {
      _isAnswered = true;
      _isCorrect = mastered;
      _dragOffset = Offset(mastered ? 1000 : -1000, 0);
    });
    context.read<VocabularyBloc>().add(SubmitAnswer(mastered));
  }

  // ── Hint ──────────────────────────────────────────────────────────────────

  void _onHintRequested() {
    if (_isFlipped) return;
    setState(() {
      _isFlipped = true;
      _isHintActive = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_isHintActive) return;
      setState(() {
        _isFlipped = false;
        _isHintActive = false;
      });
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: _onBlocState,
      builder: (context, state) {
        // Loading / unknown transient state
        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: _theme.primaryColor),
          );
        }

        // Error state — surfaces the message instead of hiding it in shimmer
        if (state is VocabularyError) {
          return _ErrorScaffold(
            message: state.message,
            primaryColor: _theme.primaryColor,
            onRetry: () => context.read<VocabularyBloc>().add(
              FetchVocabularyQuests(
                gameType: widget.gameType,
                level: widget.level,
              ),
            ),
          );
        }

        final VocabularyQuest? quest = state is VocabularyLoaded
            ? state.currentQuestOrNull
            : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<VocabularyBloc>().add(const NextQuestion()),
          useScrolling: false,
          onHint: _onHintRequested,
          child: quest == null
              ? GameShimmerLoading(primaryColor: _theme.primaryColor)
              : FlashcardGameBody(
                  quest: quest,
                  primaryColor: _theme.primaryColor,
                  isDark: isDark,
                  isFlipped: _isFlipped,
                  isAnswered: _isAnswered,
                  isRetrying: _isRetrying,
                  isHintActive: _isHintActive,
                  dragOffset: _dragOffset,
                  dragAngle: _dragAngle,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onCardTap: () {
                    _hapticService.light();
                    setState(() => _isFlipped = !_isFlipped);
                  },
                  onSubmitAnswer: _submitAnswer,
                ),
        );
      },
    );
  }

  // ── BLoC listener ─────────────────────────────────────────────────────────

  void _onBlocState(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
      final isNew = state.currentIndex != _lastProcessedIndex;
      final isRetry = state.lastAnswerCorrect == null && _isAnswered;
      if (isNew || isRetry) {
        _hintTimer?.cancel();
        setState(() {
          _lastQuest = state.currentQuestOrNull ?? _lastQuest;
          _lastProcessedIndex = state.currentIndex;
          _isAnswered = false;
          _isRetrying = isRetry;
          _isCorrect = null;
          _isFlipped = false;
          _isHintActive = false;
          _dragOffset = Offset.zero;
          _dragAngle = 0.0;
        });
      }
    } else if (state is VocabularyGameComplete) {
      if (_showConfetti) return;
      setState(() => _showConfetti = true);
      if (!context.mounted) return;
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        title: 'VOCAB MASTERY!',
        enableDoubleUp: true,
      );
    } else if (state is VocabularyGameOver) {
      GameDialogHelper.showGameOver(
        context,
        onRestore: () =>
            context.read<VocabularyBloc>().add(const RestoreLife()),
      );
    }
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final Color primaryColor;
  final VoidCallback onRetry;

  const _ErrorScaffold({
    required this.message,
    required this.primaryColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: primaryColor,
                size: 64.r,
              ),
              SizedBox(height: 16.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 24.h),
              TextButton(
                onPressed: onRetry,
                child: Text(context.tr('games.try_again').toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
