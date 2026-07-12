import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioSentenceOrderTimeline extends StatelessWidget {
  final List<String> slots;
  final Color color;
  final Function(String, int) onSnap;
  final Function(int) onUnsnap;

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
                  fontFamily: 'RobotoMono',
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
