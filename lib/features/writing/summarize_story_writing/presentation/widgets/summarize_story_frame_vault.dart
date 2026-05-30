import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/writing/summarize_story_writing/domain/models/describe_frame_slot.dart';

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
    final availableOptions = options.where((o) => !slottedSentences.contains(o)).toList();

    return Container(
      constraints: BoxConstraints(minHeight: 60.h),
      child: Wrap(
        spacing: 10.w, runSpacing: 10.h,
        alignment: WrapAlignment.center,
        children: availableOptions.map((o) => Draggable<String>(
          data: o,
          feedback: Material(
            color: Colors.transparent, 
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), 
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20.r)), 
              child: Text(
                o, 
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)
              )
            )
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), 
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white, 
              borderRadius: BorderRadius.circular(20.r), 
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 6)
              ],
            ), 
            child: Text(
              o, 
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: isDark ? Colors.white : Colors.black87, 
                fontSize: 10.sp,
                fontWeight: FontWeight.bold
              )
            )
          ),
        )).toList(),
      ),
    );
  }
}
