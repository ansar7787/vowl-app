import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'reading_peeking_mascot.dart';

/// The main scrollable / non-scrollable content area that hosts the question
/// widget, with the peeking mascot overlaid in the top-left corner.
///
/// Performance:
/// - The mascot is wrapped in a [RepaintBoundary] so its looping animation
///   never triggers a repaint of the question content behind it.
/// - Keyboard insets use [MediaQuery.viewInsetsOf] (not [MediaQuery.of]) so
///   this widget only rebuilds when the software keyboard opens/closes.
///
/// Accessibility:
/// - [AbsorbPointer] blocks touch input when [isAnswered] is true, but the
///   semantic tree remains intact so screen readers can still navigate the
///   question content after answering.
/// - The opacity animation duration is set to zero when the system
///   "reduce motion" flag is active.
class ReadingContentArea extends StatelessWidget {
  final Widget child;
  final bool isAnswered;
  final bool useScrolling;
  final bool disablePadding;
  final int lives;
  final bool? isCorrect;
  final bool isGameComplete;
  final bool isGameOver;
  final String mascotId;
  final String mascotName;

  const ReadingContentArea({
    super.key,
    required this.child,
    required this.isAnswered,
    required this.useScrolling,
    required this.disablePadding,
    required this.lives,
    required this.isCorrect,
    required this.isGameComplete,
    required this.isGameOver,
    required this.mascotId,
    required this.mascotName,
  });

  /// Padding for the scrollable / non-scrollable child.
  ///
  /// [MediaQuery.viewInsetsOf] ensures rebuilds only happen when keyboard
  /// insets change — not on orientation, text-scale, or display-feature changes.
  ///
  /// When [disablePadding] is true, only the keyboard bottom-inset is applied
  /// so content is never obscured by the software keyboard.
  EdgeInsets _contentPadding(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (disablePadding) return EdgeInsets.only(bottom: keyboardInset);
    return EdgeInsets.only(
      left: 24.w,
      right: 24.w,
      top: 20.h,
      bottom: (isAnswered ? 200.h : 40.h) + keyboardInset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Question content — dimmed while feedback card is visible.
          AnimatedOpacity(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 400),
            opacity: isAnswered ? 0.6 : 1.0,
            // AbsorbPointer blocks taps but preserves semantic tree so
            // screen readers can still read the question.
            child: AbsorbPointer(
              absorbing: isAnswered,
              child: _buildChildContent(context),
            ),
          ),

          // Peeking mascot — isolated repaint boundary so its looping
          // animation never invalidates the question content layer.
          Positioned(
            top: -20.h,
            right: 20.w,
            child: RepaintBoundary(
              child: ReadingPeekingMascot(
                lives: lives,
                isCorrect: isCorrect,
                isAnswered: isAnswered,
                isGameComplete: isGameComplete,
                isGameOver: isGameOver,
                mascotId: mascotId,
                mascotName: mascotName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildContent(BuildContext context) {
    if (useScrolling) {
      // LayoutBuilder gives us the available height so we can set a
      // minHeight constraint on the scroll content — prevents the content
      // from collapsing on screens taller than the content itself.
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(padding: _contentPadding(context), child: child),
          ),
        ),
      );
    }

    return Padding(padding: _contentPadding(context), child: child);
  }
}
