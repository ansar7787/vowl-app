import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_action_buttons.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_card_layout.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_instruction_banner.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';

/// Stateless presentation layer for the flashcard game.
///
/// Owns all layout and rendering; owns no game state. Every mutable value
/// is injected by parent and every user interaction is reported back through a callback.
class FlashcardGameBody extends StatelessWidget {
  /// The active vocabulary quest item.
  final VocabularyQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme is enabled.
  final bool isDark;

  // ── Card visual state (owned by parent) ──────────────────────────────────

  /// Notifier signaling whether the card face is flipped.
  final ValueNotifier<bool> isFlipped;

  /// Whether an answer has been submitted.
  final bool isAnswered;

  /// Whether this trial is currently in a retry state.
  final bool isRetrying;

  /// Whether a pedagogical hint peek is active.
  final bool isHintActive;

  /// Whether to suppress action buttons during transitions.
  final bool hideActions;

  /// High-frequency drag displacement offset.
  final ValueNotifier<Offset> dragOffset;

  /// High-frequency card tilt angle in radians.
  final ValueNotifier<double> dragAngle;

  // ── Interaction callbacks ─────────────────────────────────────────────────

  /// Callback executed during horizontal card drag movement.
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;

  /// Callback executed when horizontal card drag completes.
  final void Function(DragEndDetails details, double threshold)
  onHorizontalDragEnd;

  /// Callback executed when tapping the card to trigger a flip.
  final VoidCallback onCardTap;

  /// Callback executed when submitting mastery or review.
  final void Function(bool mastered) onSubmitAnswer;

  /// Creates a [FlashcardGameBody] widget.
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
        final layout = FlashcardCardLayout.compute(constraints);
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
                        builder: (context, flipped, _) =>
                            FlashcardInstructionBanner(
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
                          builder: (context, flipped, _) =>
                              FlashcardActionButtons(
                                isFlipped: flipped,
                                isTransitioning: isAnswered || isRetrying,
                                isDark: isDark,
                                onAgain: () => onSubmitAnswer(false),
                                onGotIt: () => onSubmitAnswer(true),
                                options: quest.options,
                                correctAnswer:
                                    quest.correctAnswer ?? quest.definition,
                                onOptionSelected: (isCorrect) =>
                                    onSubmitAnswer(isCorrect),
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
              '${quest.word ?? ""}. ${flipped ? context.tr('instructions.flashcards.definition_revealed', fallback: 'Check your answer') : context.tr('instructions.flashcards.tap_to_reveal', fallback: 'Tap card to flip')}',
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
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..setTranslationRaw(
                      dragOffset.value.dx,
                      dragOffset.value.dy,
                      0.0,
                    )
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
                    curve: Curves.easeInOutCubic,
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
