import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// Glass card displaying the question sentence or cloze prompt with blanks.
class AudioMultipleChoiceQuestion extends StatelessWidget {
  /// Question text to display.
  final String text;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates an [AudioMultipleChoiceQuestion] card.
  const AudioMultipleChoiceQuestion({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      borderRadius: BorderRadius.circular(16.r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.4,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
