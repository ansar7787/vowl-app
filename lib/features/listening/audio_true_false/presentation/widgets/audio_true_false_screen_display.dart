import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color1a1a1a = Color(0xFF1A1A1A);
}

class AudioTrueFalseScreenDisplay extends StatelessWidget {
  final String statement;
  final Color color;
  final String? emoji;

  const AudioTrueFalseScreenDisplay({
    super.key,
    required this.statement,
    required this.color,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('audio_true_false_screen_display_container'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 110.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? _LocalPalette.color1a1a1a : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.25)
              : color.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji != null && emoji!.isNotEmpty) ...[
            Text(
              emoji!,
              key: const Key('audio_true_false_emoji'),
              style: TextStyle(fontSize: 38.sp),
            ),
            SizedBox(height: 12.h),
          ],
          Text(
            statement,
            key: const Key('audio_true_false_statement'),
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.2,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
