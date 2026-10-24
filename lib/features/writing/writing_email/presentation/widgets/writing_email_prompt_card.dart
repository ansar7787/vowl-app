import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card widget presenting the contextual scenario prompt for the email exercise.
class WritingEmailPromptCard extends StatelessWidget {
  /// The contextual scenario or recipient prompt for writing the email.
  final String text;

  /// Theme accent color applied to borders and subtle background tint.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [WritingEmailPromptCard] widget.
  const WritingEmailPromptCard({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.45,
        ),
      ),
    );
  }
}
