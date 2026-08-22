import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_action_buttons.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';

// ─── Layout value object ──────────────────────────────────────────────────────

class _CardLayout {
  final double cardWidth;
  final double cardHeight;
  final double swipeThreshold;
  final double horizontalPadding;
  final double topSpacing;
  final double instructionToCard;
  final double cardToActions;
  final double actionsToBottom;

  const _CardLayout._({
    required this.cardWidth,
    required this.cardHeight,
    required this.swipeThreshold,
    required this.horizontalPadding,
    required this.topSpacing,
    required this.instructionToCard,
    required this.cardToActions,
    required this.actionsToBottom,
  });

  factory _CardLayout.compute(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    final isLandscape = w > h;
    final isTablet = w >= 600;
    final isSmallHeight = h < 640;

    final hPad = isTablet ? 24.w : 12.w;
    final maxW = isTablet ? min(w * 0.60, 440.0) : min(w - (hPad * 2), 372.0);
    final cardW = maxW.clamp(250.0, w - (hPad * 2));
    final cardH = isLandscape
        ? (h * 0.60).clamp(220.0, 360.0)
        : isTablet
        ? (h * 0.50).clamp(290.0, 460.0)
        : (h * 0.60).clamp(250.0, 440.0);

    return _CardLayout._(
      horizontalPadding: hPad,
      cardWidth: cardW,
      cardHeight: cardH,
      swipeThreshold: max(90.0, min(150.0, cardW * 0.38)),
      topSpacing: isSmallHeight ? 18.h : 12.h,
      instructionToCard: isSmallHeight ? 22.h : 28.h,
      cardToActions: isSmallHeight ? 22.h : 28.h,
      actionsToBottom: isSmallHeight ? 10.h : 14.h,
    );
  }
}

// ─── Game body ────────────────────────────────────────────────────────────────

/// Stateless presentation layer for the flashcard game.
///
/// Owns all layout and rendering; owns no game state.  Every mutable value
/// is injected by [_FlashcardsScreenState] and every user interaction is
/// reported back through a callback.
///
/// Keeping this widget stateless means [_FlashcardsScreenState] is the single
/// source of truth for [isFlipped], [dragOffset], etc., making state
/// transitions easy to test and reason about independently of the widget tree.
class FlashcardGameBody extends StatelessWidget {
  final VocabularyQuest quest;
  final Color primaryColor;
  final bool isDark;

  // ── Card visual state (owned by parent) ──────────────────────────────────
  final bool isFlipped;
  final bool isAnswered;
  final bool isRetrying;
  final bool isHintActive;
  final bool hideActions;
  final Offset dragOffset;
  final double dragAngle;

  // ── Interaction callbacks ─────────────────────────────────────────────────
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails details, double threshold)
  onHorizontalDragEnd;
  final VoidCallback onCardTap;
  final void Function(bool mastered) onSubmitAnswer;

  const FlashcardGameBody({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.isFlipped,
    required this.isAnswered,
    required this.isRetrying,
    required this.isHintActive,
    required this.hideActions,
    required this.dragOffset,
    required this.dragAngle,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.onCardTap,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _CardLayout.compute(constraints);
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: layout.topSpacing),
                      _InstructionBanner(primaryColor: primaryColor),
                      SizedBox(height: layout.instructionToCard),
                      Expanded(
                        child: Center(
                          child: _buildCardStack(
                            layout.cardWidth,
                            layout.cardHeight,
                            layout.swipeThreshold,
                          ),
                        ),
                      ),
                      SizedBox(height: layout.cardToActions),
                      if (!hideActions)
                        FlashcardActionButtons(
                          isFlipped: isFlipped,
                          isTransitioning: isAnswered || isRetrying,
                          isDark: isDark,
                          onAgain: () => onSubmitAnswer(false),
                          onGotIt: () => onSubmitAnswer(true),
                        ),
                      SizedBox(height: layout.actionsToBottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Card stack ────────────────────────────────────────────────────────────

  Widget _buildCardStack(double width, double height, double swipeThreshold) {
    return Semantics(
      label:
          'Flashcard: ${quest.word ?? ""}. '
          '${isFlipped ? "Definition revealed." : "Tap to reveal definition."}',
      child: GestureDetector(
        onHorizontalDragUpdate: isFlipped ? onHorizontalDragUpdate : null,
        onHorizontalDragEnd: isFlipped
            ? (d) => onHorizontalDragEnd(d, swipeThreshold)
            : null,
        onTap: onCardTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Shadow card beneath the draggable card ──────────────────
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
            // ── Draggable + flippable card ───────────────────────────────
            RepaintBoundary(
              child: AnimatedContainer(
                duration: (isAnswered || isRetrying) ? 400.ms : Duration.zero,
                curve: Curves.easeOutBack,
                transform: Matrix4.identity()
                  ..setTranslationRaw(dragOffset.dx, dragOffset.dy, 0.0)
                  ..rotateZ(dragAngle),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isFlipped ? 1 : 0),
                  duration: 400.ms,
                  curve: Curves.easeInOutBack,
                  builder: (context, value, _) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(value * pi),
                      alignment: Alignment.center,
                      child: value > 0.5
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: Alignment.center,
                              child: FlashcardSwipeBack(
                                quest: quest,
                                color: primaryColor,
                                isDark: isDark,
                                width: width,
                                height: height,
                                isHintActive: isHintActive,
                              ),
                            )
                          : FlashcardSwipeFront(
                              quest: quest,
                              color: primaryColor,
                              isDark: isDark,
                              width: width,
                              height: height,
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Instruction banner ───────────────────────────────────────────────────────

class _InstructionBanner extends StatelessWidget {
  final Color primaryColor;

  const _InstructionBanner({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
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
}
