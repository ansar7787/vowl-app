import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/writing/summarize_story_writing/domain/models/describe_frame_slot.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.black, 
        border: Border.symmetric(
          horizontal: BorderSide(color: color.withValues(alpha: 0.3), width: 4)
        )
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: List.generate(8, (i) => Container(
              width: 8.w, height: 8.h, 
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle)
            ))
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: slots.map((slot) => DragTarget<String>(
              onAcceptWithDetails: (details) => onDropFrame(slot.index, details.data),
              builder: (context, candidateData, rejectedData) {
                final text = slot.sentence;
                return GestureDetector(
                  onTap: () => onRemoveFrame(slot.index),
                  child: Container(
                    width: 100.w, height: 90.h,
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: text != null ? color.withValues(alpha: 0.15) : Colors.white10,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: text != null ? color : (candidateData.isNotEmpty ? color.withValues(alpha: 0.5) : Colors.white24),
                        width: 2
                      ),
                    ),
                    child: Center(
                      child: Text(
                        text ?? "[SLOT ${slot.index + 1}]",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: text != null ? Colors.white : Colors.white30,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold
                        )
                      )
                    ),
                  ).animate(target: text != null ? 1 : 0).scale().fadeIn(),
                );
              },
            )).toList(),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: List.generate(8, (i) => Container(
              width: 8.w, height: 8.h, 
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle)
            ))
          ),
        ],
      ),
    );
  }
}
