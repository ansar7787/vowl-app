import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Draggable word segment chips container for sentence ordering challenges.
class AudioSentenceOrderSegments extends StatelessWidget {
  /// Pool of available word segment tokens.
  final List<String> segments;

  /// Ordered target slots representing the current sentence state.
  final List<String> slots;

  /// Theme accent color.
  final Color color;

  /// Whether the challenge has already been answered.
  final bool isAnswered;

  /// Callback invoked when a segment is snapped into a target slot index.
  final Function(String, int) onSnap;

  /// Creates an [AudioSentenceOrderSegments] container.
  const AudioSentenceOrderSegments({
    super.key,
    required this.segments,
    required this.slots,
    required this.color,
    required this.isAnswered,
    required this.onSnap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: segments
          .map(
            (s) => Draggable<String>(
              data: s,
              feedback: Material(
                color: Colors.transparent,
                child: _buildSegmentChip(s, color, true),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildSegmentChip(s, color, false),
              ),
              child: GestureDetector(
                onTap: () {
                  if (isAnswered) return;
                  int firstEmptyIndex = slots.indexOf("");
                  if (firstEmptyIndex != -1) {
                    onSnap(s, firstEmptyIndex);
                  }
                },
                child: _buildSegmentChip(s, color, false),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSegmentChip(String text, Color color, bool isFeedback) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isFeedback ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isFeedback ? 0.4 : 0.1),
            blurRadius: isFeedback ? 10 : 5,
            offset: Offset(0, isFeedback ? 4 : 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isFeedback ? Colors.white : color,
        ),
      ),
    );
  }
}
