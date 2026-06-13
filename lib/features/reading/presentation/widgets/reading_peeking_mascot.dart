import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';

/// The small mascot that peeks from the top-left of the content area,
/// with an animated speech bubble showing context-sensitive messages.
///
/// All animations respect the system "reduce motion" accessibility setting.
/// The speech bubble is a live ARIA region — screen readers announce its
/// content whenever [message] changes.
class ReadingPeekingMascot extends StatelessWidget {
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;
  final bool isGameComplete;
  final bool isGameOver;
  final String mascotId;
  final String mascotName;

  const ReadingPeekingMascot({
    super.key,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.isGameComplete,
    required this.isGameOver,
    required this.mascotId,
    required this.mascotName,
  });



  @override
  Widget build(BuildContext context) {
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'reading',
      mascotId: mascotId,
      isComplete: isGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );
    
    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: isGameComplete,
      isGameOver: isGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );
    
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: Colors.orangeAccent,
        ),
      ),
    );

    if (!reduceMotion) {
      bubble = bubble
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 2.seconds,
          );
    }

    Widget mascot = VowlMascot(
      state: mascotState,
      size: 45.r,
      mascotId: mascotId,
    );

    if (!reduceMotion) {
      mascot = mascot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 5, duration: 1500.ms, curve: Curves.easeInOut);
    }

    Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bubble, mascot],
    );

    if (!reduceMotion) {
      column = column.animate().fadeIn().slideX(begin: -0.1, end: 0);
    }

    return Semantics(
      // liveRegion causes screen readers to announce the message whenever
      // it changes — the player hears feedback without touching the phone.
      liveRegion: true,
      label: message,
      // excludeSemantics prevents the child sub-tree from producing
      // additional (redundant) screen reader announcements.
      excludeSemantics: true,
      child: column,
    );
  }
}
