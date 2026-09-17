import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VocabularyBodyArea extends StatelessWidget {
  final Widget child;
  final bool isAnswered;
  final bool useScrolling;
  final bool disablePadding;

  /// Reserved bottom space for the feedback card overlay.
  /// Measured from the tallest GameFeedbackCard variant
  /// (correct answer box + explanation + mind map + continue button).
  static final double _feedbackReservedHeight = 220.h;

  const VocabularyBodyArea({
    super.key,
    required this.child,
    required this.isAnswered,
    required this.useScrolling,
    required this.disablePadding,
  });

  EdgeInsets _buildPadding(BuildContext context) {
    if (disablePadding) return EdgeInsets.zero;
    return EdgeInsets.only(
      left: 24.w,
      right: 24.w,
      top: 40.h,
      // Reserve space for the feedback card when answered; otherwise add
      // the keyboard inset so the content is never obscured.
      bottom:
          (isAnswered ? _feedbackReservedHeight : 40.h) +
          MediaQuery.of(context).viewInsets.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = _buildPadding(context);

    if (useScrolling) {
      return LayoutBuilder(
        key: const ValueKey('vocab_layout_scroller'),
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth,
              ),
              child: Padding(padding: padding, child: child),
            ),
          );
        },
      );
    }

    return Padding(padding: padding, child: child);
  }
}
