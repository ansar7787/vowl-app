import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class CompleteSentenceTargetWall extends StatelessWidget {
  final String text;
  final String? injected;
  final Color color;
  final bool isDark;

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
    // Split the sentence by the blank to style it dynamically
    final parts = text.split(RegExp(r'_+'));
    final normalStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 22.sp,
      color: isDark ? Colors.white70 : Colors.black87,
      fontWeight: FontWeight.w600,
      height: 1.5,
    );
    final highlightStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 22.sp,
      color: color,
      fontWeight: FontWeight.w800,
      height: 1.5,
    );

    final List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: normalStyle));
      if (i < parts.length - 1) {
        spans.add(TextSpan(text: injected ?? '______', style: highlightStyle));
      }
    }

    final fullText = text.replaceAll(RegExp(r'_+'), injected ?? '______');

    return Semantics(
      label: injected != null
          ? 'Target sentence with answer filled: $fullText'
          : 'Target sentence with blank: $fullText. Fire the correct word.',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.05 : 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
            DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                HapticFeedback.selectionClick();
                return true;
              },
              onAcceptWithDetails: (details) {
                onFire(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: isHovered ? EdgeInsets.all(8.r) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: isHovered
                          ? color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: spans),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
