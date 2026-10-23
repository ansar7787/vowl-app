import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// Glass tile presenting the challenge sentence containing missing or tested syntax.
class GrammarQuestSentence extends StatelessWidget {
  /// Sentence text to display.
  final String text;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether compact visual styling should be applied.
  final bool isCompact;

  /// Creates a [GrammarQuestSentence] widget.
  const GrammarQuestSentence({
    super.key,
    required this.text,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.w : 20.w,
        vertical: isCompact ? 14.h : 20.h,
      ),
      borderRadius: BorderRadius.circular(isCompact ? 16.r : 20.r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompact ? 16.sp : 18.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.45,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
