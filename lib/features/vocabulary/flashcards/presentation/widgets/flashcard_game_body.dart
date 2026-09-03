import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_action_buttons.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';
import 'package:vowl/core/utils/instruction_helper.dart';

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
    final maxW = isTablet ? min(w * 0.80, 600.0) : w - (hPad * 2);
    final double cardW = maxW;
    final double cardH = isLandscape ? h * 0.85 : h * 0.72;

    return _CardLayout._(
      horizontalPadding: hPad,
      cardWidth: cardW,
      cardHeight: cardH,
      swipeThreshold: max(90.0, min(150.0, cardW * 0.38)),
      topSpacing: isSmallHeight ? 4.h : 8.h,
      instructionToCard: isSmallHeight ? 8.h : 12.h,
      cardToActions: isSmallHeight ? 12.h : 16.h,
      actionsToBottom: isSmallHeight ? 8.h : 12.h,
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
  final ValueNotifier<bool> isFlipped;
  final bool isAnswered;
  final bool isRetrying;
  final bool isHintActive;
  final bool hideActions;
  final ValueNotifier<Offset> dragOffset;
  final ValueNotifier<double> dragAngle;

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
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: layout.topSpacing),
                      ValueListenableBuilder<bool>(
                        valueListenable: isFlipped,
                        builder: (context, flipped, _) => _InstructionBanner(
                          primaryColor: primaryColor,
                          isFlipped: flipped,
                          quest: quest,
                        ),
                      ),
                      SizedBox(height: layout.instructionToCard),
                      Flexible(
                        child: Center(
                          child: _buildCardStack(
                            context,
                            layout.cardWidth,
                            layout.cardHeight,
                            layout.swipeThreshold,
                          ),
                        ),
                      ),
                      SizedBox(height: layout.cardToActions),
                      if (!hideActions)
                        ValueListenableBuilder<bool>(
                          valueListenable: isFlipped,
                          builder: (context, flipped, _) => FlashcardActionButtons(
                            isFlipped: flipped,
                            isTransitioning: isAnswered || isRetrying,
                            isDark: isDark,
                            onAgain: () => onSubmitAnswer(false),
                            onGotIt: () => onSubmitAnswer(true),
                          ),
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

  Widget _buildCardStack(
    BuildContext context,
    double width,
    double height,
    double swipeThreshold,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: isFlipped,
      builder: (context, flipped, child) {
        return Semantics(
          label:
              '${quest.word ?? ""}. ${flipped ? context.tr('instructions.flashcards.definition_revealed', fallback: 'DEFINITION REVEALED') : context.tr('instructions.flashcards.tap_to_reveal', fallback: 'TAP TO REVEAL')}',
          child: GestureDetector(
            onHorizontalDragUpdate: flipped ? onHorizontalDragUpdate : null,
            onHorizontalDragEnd: flipped
                ? (d) => onHorizontalDragEnd(d, swipeThreshold)
                : null,
            onTap: onCardTap,
            child: child,
          ),
        );
      },
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
            child: ListenableBuilder(
              listenable: Listenable.merge([dragOffset, dragAngle]),
              builder: (context, child) {
                return AnimatedContainer(
                  duration: (isAnswered || isRetrying) ? 400.ms : Duration.zero,
                  curve: Curves.easeOutBack,
                  transform: Matrix4.identity()
                    ..setTranslationRaw(dragOffset.value.dx, dragOffset.value.dy, 0.0)
                    ..rotateZ(dragAngle.value),
                  child: child,
                );
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: isFlipped,
                builder: (context, flipped, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: flipped ? 1 : 0),
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

// ─── Instruction banner ───────────────────────────────────────────────────────

class _InstructionBanner extends StatelessWidget {
  final Color primaryColor;
  final bool isFlipped;
  final VocabularyQuest quest;

  const _InstructionBanner({
    required this.primaryColor,
    required this.isFlipped,
    required this.quest,
  });

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
        child: AnimatedSwitcher(
          duration: 300.ms,
          child: FittedBox(
            key: ValueKey<bool>(isFlipped),
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFlipped ? Icons.swipe_rounded : Icons.touch_app_rounded,
                  size: 14.r,
                  color: primaryColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  isFlipped
                      ? context.tr(
                          'instructions.flashcards.swipe_instruction',
                          fallback: 'SWIPE LEFT OR RIGHT',
                        )
                      : InstructionHelper.getInstruction(quest),
                  textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
    );
  }
}
