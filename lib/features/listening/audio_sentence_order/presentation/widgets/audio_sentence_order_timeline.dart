import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Target drop slots timeline where word segment chips are arranged in sequence.
class AudioSentenceOrderTimeline extends StatelessWidget {
  /// Sequence of slot strings containing either word values or empty strings.
  final List<String> slots;

  /// Theme accent color.
  final Color color;

  /// Callback when a word segment is dropped into a slot index.
  final Function(String, int) onSnap;

  /// Callback when a word segment is tapped to remove it from a slot index.
  final Function(int) onUnsnap;

  /// Creates an [AudioSentenceOrderTimeline] drop target row.
  const AudioSentenceOrderTimeline({
    super.key,
    required this.slots,
    required this.color,
    required this.onSnap,
    required this.onUnsnap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: List.generate(
        slots.length,
        (index) => DragTarget<String>(
          onAcceptWithDetails: (details) => onSnap(details.data, index),
          builder: (context, candidateData, rejectedData) => GestureDetector(
            onTap: () => onUnsnap(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: slots[index].isEmpty
                    ? color.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: slots[index].isEmpty
                      ? color.withValues(alpha: 0.2)
                      : color,
                ),
              ),
              child: Text(
                slots[index].isEmpty ? "???" : slots[index],
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: slots[index].isEmpty
                      ? color.withValues(alpha: 0.4)
                      : color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
