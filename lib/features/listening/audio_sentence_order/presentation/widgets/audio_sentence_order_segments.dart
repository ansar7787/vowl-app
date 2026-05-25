import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioSentenceOrderSegments extends StatelessWidget {
  final List<String> segments;
  final List<String> slots;
  final Color color;
  final bool isAnswered;
  final Function(String, int) onSnap;

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
        style: GoogleFonts.outfit(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isFeedback ? Colors.white : color,
        ),
      ),
    );
  }
}
