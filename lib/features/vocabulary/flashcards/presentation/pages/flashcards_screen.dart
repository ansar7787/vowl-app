import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'dart:math';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_hints.dart';

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
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

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

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    if (_isRetrying) setState(() => _isRetrying = false);

    final oldOffset = _dragOffset;
    setState(() {
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, 0);
      _dragAngle = _dragOffset.dx / 500;

      // Better haptic throttle: trigger only every 20 pixels of horizontal movement
      if ((_dragOffset.dx - oldOffset.dx).abs() > 0 &&
          (_dragOffset.dx.abs() % 20 < 2)) {
        _hapticService.selection();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isAnswered) return;
    if (_dragOffset.dx.abs() > 150) {
      _submitAnswer(_dragOffset.dx > 0);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
      });
    }
  }

  void _submitAnswer(bool mastered) {
    if (_isAnswered) return;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = state.lastAnswerCorrect == null && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isRetrying = isRetry;
              _isCorrect = null;
              _isFlipped = false;
              _dragOffset = Offset.zero;
              _dragAngle = 0.0;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          if (!_showConfetti) {
            final xp = state.xpEarned;
            final coins = state.coinsEarned;
            setState(() => _showConfetti = true);
            if (!context.mounted) return;
            GameDialogHelper.showCompletion(
              context,
              xp: xp,
              coins: coins,
              title: 'VOCAB MASTERY!',
              enableDoubleUp: true,
            );
          }
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

        if (state is VocabularyLoading || (state is! VocabularyGameComplete && state is! VocabularyLoaded && state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          useScrolling: false,
          onHint: () {
          if (!_isFlipped) {
            setState(() {
              _isFlipped = true;
              _isHintActive = true;
            });
            // Flip back after 4 seconds to maintain the "test" aspect
            Future.delayed(const Duration(seconds: 4), () {
              if (!context.mounted) return;
              if (_isHintActive) {
                setState(() {
                  _isFlipped = false;
                  _isHintActive = false;
                });
              }
            });
          }
        },
          child: quest == null
              ? GameShimmerLoading(primaryColor: theme.primaryColor)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate dynamic card height based on available space
                    // Subtracting some space for instruction and hints
                    final availableHeight = constraints.maxHeight;
                    final cardHeight = (availableHeight * 0.65)
                        .clamp(300.0, 450.0);
                    final cardWidth = (constraints.maxWidth * 0.85)
                        .clamp(280.0, 320.0);

                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(), // Keep swipe gestures clean
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 8.h),
                            _buildInstruction(theme.primaryColor),
                            SizedBox(height: 16.h),
                            _buildCardStack(
                              quest,
                              theme.primaryColor,
                              isDark,
                              cardWidth,
                              cardHeight * 0.95, // Slight reduction to safely fit
                            ),
                            SizedBox(height: 20.h),
                            FlashcardSwipeHints(color: theme.primaryColor),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              "SWIPE RIGHT TO MASTER, LEFT TO REVIEW",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildCardStack(
    dynamic quest,
    Color color,
    bool isDark,
    double width,
    double height,
  ) {
    final frontCard = FlashcardSwipeFront(
      quest: quest,
      color: color,
      isDark: isDark,
      width: width,
      height: height,
    );
    final backCard = FlashcardSwipeBack(
      quest: quest,
      color: color,
      isDark: isDark,
      width: width,
      height: height,
      isHintActive: _isHintActive,
    );

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTap: () {
        _hapticService.light();
        setState(() => _isFlipped = !_isFlipped);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom Card Decoration (Shadow/Stack effect)
          Transform.translate(
            offset: const Offset(0, 10),
            child: Container(
              width: width * 0.95,
              height: height,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),

          // Main Interactive Card
          RepaintBoundary(
            child: AnimatedContainer(
              duration: (_isAnswered || _isRetrying) ? 400.ms : 0.ms,
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()
                ..setTranslationRaw(_dragOffset.dx, _dragOffset.dy, 0.0)
                ..rotateZ(_dragAngle),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: _isFlipped ? 1 : 0),
                duration: 400.ms,
                curve: Curves.easeInOutBack,
                builder: (context, value, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(value * pi),
                    alignment: Alignment.center,
                    child: value > 0.5
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: backCard,
                          )
                        : frontCard,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
