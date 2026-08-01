import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompleteSentenceBallistaAmmo extends StatelessWidget {
  final List<String> options;
  final Color color;
  final bool isDark;
  final ValueChanged<Offset> onBridgeStart; // FIX: was Function(Offset)
  final ValueChanged<Offset> onBridgeUpdate; // FIX: was Function(Offset)
  final ValueChanged<String>
  onFire; // FIX: was Function(String, String), correct removed

  const CompleteSentenceBallistaAmmo({
    super.key,
    required this.options,
    required this.color,
    required this.isDark,
    required this.onBridgeStart,
    required this.onBridgeUpdate,
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
          return Semantics(
            label: 'Fire word: $o',
            button: true,
            child: GestureDetector(
              // FIX: tap-to-fire added — pan gesture was the only interaction,
              // making this inaccessible without precise drag capability.
              onTap: () => onFire(o),
              onPanStart: (details) => onBridgeStart(details.globalPosition),
              onPanUpdate: (details) => onBridgeUpdate(details.globalPosition),
              // FIX: only reports selected word — screen handles correct comparison.
              onPanEnd: (_) => onFire(o),
              child: ConstrainedBox(
                // FIX: cap width so long option text doesn't overflow Wrap
                // on 320px phones or in landscape split-screen.
                constraints: BoxConstraints(maxWidth: 0.7.sw),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 12.h,
                  ),
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
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
