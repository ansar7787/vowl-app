import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompleteSentenceBallistaAmmo extends StatelessWidget {
  final List<String> options;
  final Color color;
  final bool isDark;
  final ValueChanged<String> onFire;

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
      label: 'Word options. Tap or drag to fire a word at the target.',
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: options.map((o) {
          final buttonWidget = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 0.8.sw),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                o,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );

          return Semantics(
            label: 'Fire word: $o',
            button: true,
            child: GestureDetector(
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
