import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/describe_frame_slot.dart';

class SummarizeStoryFilmStrip extends StatelessWidget {
  final List<DescribeFrameSlot> slots;
  final Color color;
  final bool isDark;
  final Function(int, String) onDropFrame;
  final Function(int) onRemoveFrame;

  const SummarizeStoryFilmStrip({
    super.key,
    required this.slots,
    required this.color,
    required this.isDark,
    required this.onDropFrame,
    required this.onRemoveFrame,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: slots.map((slot) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    "${slot.index + 1}",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: DragTarget<String>(
                  onAcceptWithDetails: (details) =>
                      onDropFrame(slot.index, details.data),
                  builder: (context, candidateData, rejectedData) {
                    final text = slot.sentence;
                    final isHovering = candidateData.isNotEmpty;

                    return GestureDetector(
                      onTap: () => onRemoveFrame(slot.index),
                      child:
                          Container(
                                constraints: BoxConstraints(minHeight: 60.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: text != null
                                      ? color.withValues(alpha: 0.15)
                                      : (isHovering
                                            ? color.withValues(alpha: 0.05)
                                            : (isDark
                                                  ? Colors.black12
                                                  : Colors.black.withValues(
                                                      alpha: 0.02,
                                                    ))),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: text != null
                                        ? color
                                        : (isHovering
                                              ? color.withValues(alpha: 0.5)
                                              : (isDark
                                                    ? Colors.white24
                                                    : Colors.black12)),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    text ?? "Drop event here...",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: text != null
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.white30
                                                : Colors.black38),
                                    ),
                                  ),
                                ),
                              )
                              .animate(target: text != null ? 1 : 0)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.02, 1.02),
                              )
                              .tint(color: color.withValues(alpha: 0.1)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
