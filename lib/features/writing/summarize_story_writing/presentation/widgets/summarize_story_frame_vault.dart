import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/summarize_story_frame_slot.dart';

/// Card list vault containing candidate summary sentences available for selection.
class SummarizeStoryFrameVault extends StatelessWidget {
  /// Complete list of candidate summary sentences.
  final List<String> options;

  /// Current collection of frame slots, used to filter out already-placed items.
  final List<SummarizeStoryFrameSlot> slots;

  /// Theme accent color applied to cards and shadows.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Optional callback invoked when a candidate sentence is tapped.
  final void Function(String text)? onTapOption;

  /// Creates a [SummarizeStoryFrameVault] widget.
  const SummarizeStoryFrameVault({
    super.key,
    required this.options,
    required this.slots,
    required this.color,
    required this.isDark,
    this.onTapOption,
  });

  @override
  Widget build(BuildContext context) {
    final slottedSentences = slots
        .map((s) => s.sentence)
        .whereType<String>()
        .toSet();
    final availableOptions = options
        .where((o) => !slottedSentences.contains(o))
        .toList();

    return Column(
      children: availableOptions.map((o) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Draggable<String>(
            data: o,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 40.w,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  o,
                  textAlign: TextAlign.start,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildOptionCard(o, context),
            ),
            child: GestureDetector(
              key: Key('summarize_story_option_$o'),
              onTap: () => onTapOption?.call(o),
              child: _buildOptionCard(o, context),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionCard(String text, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.start,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}
