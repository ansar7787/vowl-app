import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class CompleteSentenceTargetWall extends StatelessWidget {
  final String text;
  final String? injected;
  final Color color;
  final bool isDark;

  // FIX: was Function(String, String) — now ValueChanged<String>.
  // The wall only reports which word was dragged onto it.
  // The screen is responsible for comparing it against correctAnswer.
  final ValueChanged<String> onFire;

  const CompleteSentenceTargetWall({
    super.key,
    required this.text,
    this.injected,
    required this.color,
    required this.isDark,
    required this.onFire,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Match any number of consecutive underscores to ensure the blank line
    // is reliably replaced regardless of curriculum JSON variations.
    final displayText = text.replaceAll(
      RegExp(r'_+'),
      injected != null ? injected!.toUpperCase() : '____',
    );

    return Semantics(
      label: injected != null
          ? 'Target sentence with answer filled: $displayText'
          : 'Target sentence with blank: $displayText. Fire the correct word.',
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.05 : 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: // NOTE: DragTarget is preserved as a future integration point.
                  // Currently it cannot be triggered because the ammo widget uses
                  // GestureDetector.onPanEnd (not Draggable<String>), so no
                  // Draggable exists in the tree to satisfy this target.
                  // To activate: convert ammo to Draggable<String> in a future pass.
                  DragTarget<String>(
                    onAcceptWithDetails: (details) {
                      // FIX: was onFire(details.data, details.data) — both args were
                      // the same dragged word, making this always evaluate as correct.
                      // Now only reports the dragged word; screen compares to correct.
                      onFire(details.data);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Text(
                        displayText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.sp,
                          color: injected != null
                              ? color
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
