import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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

    final hPad = isTablet ? 32.w : 16.w;
    final maxW = isTablet ? min(w * 0.70, 440.0) : min(w - (hPad * 2), 400.0);
    final double cardW = maxW;

    final topSpacing = isSmallHeight ? 4.h : 8.h;
    final instructionToCard = isSmallHeight ? 8.h : 12.h;
    final cardToActions = isSmallHeight ? 10.h : 14.h;
    final actionsToBottom = isSmallHeight ? 6.h : 10.h;

    // Remaining height allocated to card with chrome deduction
    final totalSpacing =
        topSpacing + instructionToCard + cardToActions + actionsToBottom;
    final chromeHeight = totalSpacing + (isSmallHeight ? 96.h : 116.h);
    final availableH = h - chromeHeight;

    final double cardH = isLandscape
        ? min(h * 0.82, 380.0)
        : availableH.clamp(270.0, 460.0);

    return _CardLayout._(
      horizontalPadding: hPad,
      cardWidth: cardW,
      cardHeight: cardH,
      swipeThreshold: max(80.0, min(140.0, cardW * 0.35)),
      topSpacing: topSpacing,
      instructionToCard: instructionToCard,
      cardToActions: cardToActions,
      actionsToBottom: actionsToBottom,
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
                          builder: (context, flipped, _) =>
                              FlashcardActionButtons(
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

  String _formatInstruction(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Tap card to check meaning';
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 2) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    final instructionText = isFlipped
        ? context.tr(
            'instructions.flashcards.swipe_instruction',
            fallback: 'Swipe left to review, right if you got it',
          )
        : _formatInstruction(InstructionHelper.getInstruction(quest));

    final bannerContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: 300.ms,
        child: KeyedSubtree(
          key: ValueKey<bool>(isFlipped),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isFlipped ? Icons.swipe_rounded : Icons.touch_app_rounded,
                size: 16.r,
                color: primaryColor,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  instructionText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 380.w),
      child: reduceMotion
          ? bannerContent
          : bannerContent
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.2, end: 0),
    );
  }
}
