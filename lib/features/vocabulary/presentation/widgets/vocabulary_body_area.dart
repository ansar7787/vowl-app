import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Wraps the game child widget in either a scrollable or static layout.
/// Handles keyboard inset padding automatically.
class VocabularyBodyArea extends StatelessWidget {
  final Widget child;
  final bool isAnswered;
  final bool useScrolling;
  final bool disablePadding;

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
      bottom:
          (isAnswered ? 200.h : 40.h) +
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
