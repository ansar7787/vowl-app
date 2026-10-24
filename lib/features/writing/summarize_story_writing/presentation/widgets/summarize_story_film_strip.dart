import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/summarize_story_frame_slot.dart';

/// Sequential filmstrip layout presenting numbered slots for narrative summary frames.
class SummarizeStoryFilmStrip extends StatelessWidget {
  /// List of summary frame slots defining the chronology.
  final List<SummarizeStoryFrameSlot> slots;

  /// Theme accent color applied to numbers and border indicators.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Callback invoked when a sentence is dropped into a specific slot index.
  final Function(int, String) onDropFrame;

  /// Callback invoked when a slotted sentence is removed from a slot index.
  final Function(int) onRemoveFrame;

  /// Creates a [SummarizeStoryFilmStrip] widget.
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
          padding: EdgeInsets.only(bottom: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    "${slot.index + 1}",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
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

                    final slotContainer = Container(
                      constraints: BoxConstraints(minHeight: 56.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: text != null
                            ? color.withValues(alpha: 0.12)
                            : (isHovering
                                  ? color.withValues(alpha: 0.06)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.02))),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: text != null
                              ? color
                              : (isHovering
                                    ? color.withValues(alpha: 0.5)
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.black12)),
                          width: 1.5,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          text ?? "Tap or drag an event here",
                          textAlign: TextAlign.start,
                          softWrap: true,
                          maxLines: null,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: text != null
                                ? (isDark ? Colors.white : AppColors.slate800)
                                : (isDark
                                      ? Colors.white38
                                      : AppColors.slate400),
                          ),
                        ),
                      ),
                    );

                    if (VowlMotion.lowAnimationModeOverride.value) {
                      return GestureDetector(
                        key: Key('summarize_story_slot_${slot.index}'),
                        onTap: () => onRemoveFrame(slot.index),
                        child: slotContainer,
                      );
                    }

                    return GestureDetector(
                      key: Key('summarize_story_slot_${slot.index}'),
                      onTap: () => onRemoveFrame(slot.index),
                      child: slotContainer
                          .animate(target: text != null ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.01, 1.01),
                          )
                          .tint(color: color.withValues(alpha: 0.06)),
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
