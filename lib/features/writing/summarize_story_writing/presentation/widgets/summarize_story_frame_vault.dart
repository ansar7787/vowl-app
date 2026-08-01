import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/models/describe_frame_slot.dart';

class SummarizeStoryFrameVault extends StatelessWidget {
  final List<String> options;
  final List<DescribeFrameSlot> slots;
  final Color color;
  final bool isDark;

  const SummarizeStoryFrameVault({
    super.key,
    required this.options,
    required this.slots,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final slottedSentences = slots.map((s) => s.sentence).toSet();
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
                width: MediaQuery.of(context).size.width - 48.w,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  o,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildOptionCard(o, context),
            ),
            child: _buildOptionCard(o, context),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionCard(String text, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
