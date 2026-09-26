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
            constraints: BoxConstraints(maxWidth: 0.7.sw),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                o.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
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
                  child: buttonWidget,
                ),
                childWhenDragging: Opacity(opacity: 0.5, child: buttonWidget),
                child: buttonWidget,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
