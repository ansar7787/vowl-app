import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Row of draggable word chips acting as ammo to fire into target sentence blanks.
class CompleteSentenceBallistaAmmo extends StatelessWidget {
  /// Available word option strings.
  final List<String> options;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback receiving the word chosen or dragged into the target.
  final ValueChanged<String> onFire;

  /// Creates a [CompleteSentenceBallistaAmmo] selector.
  const CompleteSentenceBallistaAmmo({
    super.key,
    required this.options,
    required this.color,
    required this.isDark,
    required this.onFire,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Word options. Tap or drag a word to complete the sentence.',
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: options.map((o) {
          final buttonWidget = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 0.85.sw, minWidth: 64.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.6 : 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                o,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: null,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );

          return Semantics(
            label: 'Option: $o',
            button: true,
            child: GestureDetector(
              key: ValueKey('ammo_$o'),
              onTap: () => onFire(o),
              child: Draggable<String>(
                data: o,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(scale: 1.05, child: buttonWidget),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: buttonWidget),
                child: buttonWidget,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
