import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Precomputes responsive layout constraints and spacing metrics for flashcards.
class FlashcardCardLayout {
  final double cardWidth;
  final double cardHeight;
  final double swipeThreshold;
  final double horizontalPadding;
  final double topSpacing;
  final double instructionToCard;
  final double cardToActions;
  final double actionsToBottom;

  const FlashcardCardLayout._({
    required this.cardWidth,
    required this.cardHeight,
    required this.swipeThreshold,
    required this.horizontalPadding,
    required this.topSpacing,
    required this.instructionToCard,
    required this.cardToActions,
    required this.actionsToBottom,
  });

  /// Derives responsive card dimensions from the enclosing [BoxConstraints].
  factory FlashcardCardLayout.compute(BoxConstraints c) {
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

    return FlashcardCardLayout._(
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
