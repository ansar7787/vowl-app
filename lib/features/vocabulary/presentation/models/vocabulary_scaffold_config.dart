import 'package:flutter/widgets.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

@immutable
class VocabularyScaffoldConfig {
  /// The vocabulary sub-type determining question format and theming.
  final GameSubtype gameType;

  /// Current level number (1-based).
  final int level;

  /// The game-specific interaction widget (MCQ answers, flip card, etc.).
  final Widget child;

  /// Whether the current question has been answered (locks interaction).
  final bool isAnswered;

  /// `true` if the last answer was correct, `false` if wrong, `null` if pending.
  final bool? isCorrect;

  /// Whether the mastery-loop retry limit has been reached for this question.
  final bool isFinalFailure;

  /// Called when the user taps Continue / Try Again in the feedback card.
  final VoidCallback onContinue;

  /// Called when the user taps the hint button.
  final VoidCallback onHint;

  /// Whether to render the confetti overlay (on correct completion).
  final bool showConfetti;

  /// Whether the body area should scroll (for tall content like typing inputs).
  final bool useScrolling;

  /// When `true`, body padding is removed (used by full-bleed game variants).
  final bool disablePadding;

  const VocabularyScaffoldConfig({
    required this.gameType,
    required this.level,
    required this.child,
    required this.isAnswered,
    this.isCorrect,
    this.isFinalFailure = false,
    required this.onContinue,
    required this.onHint,
    this.showConfetti = false,
    this.useScrolling = false,
    this.disablePadding = false,
  });
}
