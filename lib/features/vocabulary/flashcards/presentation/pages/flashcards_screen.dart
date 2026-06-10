import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_action_buttons.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/pages/vocabulary_base_layout.dart';

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

    if (_isRetrying) {
      setState(() => _isRetrying = false);
    }

    final oldOffset = _dragOffset;

    setState(() {
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, 0);
      _dragAngle = _dragOffset.dx / 500;

      if ((_dragOffset.dx - oldOffset.dx).abs() > 0 &&
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
              _isHintActive = false;
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
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = state is VocabularyLoaded
            ? state.currentQuest
            : _lastQuest;

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
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final isLandscape = width > height;
                    final isTablet = width >= 600;
                    final isSmallHeight = height < 640;

                    final horizontalPadding = isTablet ? 24.w : 12.w;

                    final cardMaxWidth = isTablet
                        ? min(width * 0.60, 440.0)
                        : min(width - (horizontalPadding * 2), 372.0);

                    final cardWidth = cardMaxWidth.clamp(
                      250.0,
                      width - (horizontalPadding * 2),
                    );

                    final cardHeight = isLandscape
                        ? (height * 0.60).clamp(220.0, 360.0)
                        : isTablet
                        ? (height * 0.50).clamp(290.0, 460.0)
                        : (height * 0.60).clamp(250.0, 440.0);

                    final swipeThreshold = max(
                      90.0,
                      min(150.0, cardWidth * 0.38),
                    );

                    final topSpacing = isSmallHeight ? 18.h : 12.h;
                    final instructionToCard = isSmallHeight ? 22.h : 28.h;
                    final cardToActions = isSmallHeight ? 22.h : 28.h;
                    final actionsToBottom = isSmallHeight ? 10.h : 14.h;

                    return SafeArea(
                      bottom: true,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: height),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: topSpacing),
                              _buildInstruction(theme.primaryColor),
                              SizedBox(height: instructionToCard),
                              Center(
                                child: _buildCardStack(
                                  quest,
                                  theme.primaryColor,
                                  isDark,
                                  cardWidth,
                                  cardHeight,
                                  swipeThreshold,
                                ),
                              ),
                              SizedBox(height: cardToActions),
                              FlashcardActionButtons(
                                isFlipped: _isFlipped,
                                isTransitioning: _isAnswered || _isRetrying,
                                theme: theme,
                                isDark: isDark,
                                onAgain: () => _submitAnswer(false),
                                onGotIt: () => _submitAnswer(true),
                              ),
                              SizedBox(height: actionsToBottom),
                            ],
                          ),
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 430.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.20)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            Icon(Icons.swipe_rounded, size: 14.r, color: primaryColor),
            Text(
              'SWIPE RIGHT TO MASTER, LEFT TO REVIEW',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildCardStack(
    dynamic quest,
    Color color,
    bool isDark,
    double width,
    double height,
    double swipeThreshold,
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
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(details, swipeThreshold),
      onTap: () {
        _hapticService.light();
        setState(() => _isFlipped = !_isFlipped);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 10),
            child: Container(
              width: width * 0.96,
              height: height,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedContainer(
              duration: (_isAnswered || _isRetrying) ? 400.ms : Duration.zero,
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()
                ..setTranslationRaw(_dragOffset.dx, _dragOffset.dy, 0.0)
                ..rotateZ(_dragAngle),
              child: TweenAnimationBuilder<double>(
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
