import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

/// Target sentence wall widget with an embedded drop target zone for missing word tokens.
class CompleteSentenceTargetWall extends StatelessWidget {
  /// Prompt sentence template containing blanks (`______`).
  final String text;

  /// Currently dropped or typed word token inserted into the blank.
  final String? injected;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  // The wall only reports which word was dragged onto it.
  // The screen is responsible for comparing it against correctAnswer.
  /// Callback receiving the word dropped onto the target wall.
  final ValueChanged<String> onFire;

  /// Creates a [CompleteSentenceTargetWall] target surface.
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
      fontSize: 18.5.sp,
      color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: 0.2,
    );
    final highlightStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 18.5.sp,
      color: color,
      fontWeight: FontWeight.w700,
      height: 1.55,
      letterSpacing: 0.2,
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
          ? 'Completed sentence: $fullText'
          : 'Sentence with blank: $fullText. Choose the missing word.',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 26.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.05 : 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: TechPatternOverlay(opacity: 0.04)),
            DragTarget<String>(
              key: const Key('complete_sentence_target_wall_drop_zone'),
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
                    padding: isHovered
                        ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: isHovered
                          ? color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          MediaQuery.of(context).textScaler.scale(1).clamp(0.85, 1.25),
                        ),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        softWrap: true,
                        text: TextSpan(children: spans),
                      ),
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
