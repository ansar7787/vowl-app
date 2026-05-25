import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GuessTitleLabelRack extends StatelessWidget {
  final List<String> labels;
  final String correct;
  final Color color;
  final bool isDark;
  final String? selectedTitle;
  final bool isAnswered;

  const GuessTitleLabelRack({
    super.key,
    required this.labels,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedTitle,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: List.generate(labels.length, (index) {
        final label = labels[index];
        final isSelected = selectedTitle == label;
        
        if (isAnswered && !isSelected) {
          return Opacity(
            opacity: 0.2,
            child: _buildLabelCard(label, color, isDark, enabled: false),
          );
        }
        
        return Draggable<String>(
          data: label,
          maxSimultaneousDrags: isAnswered ? 0 : 1,
          feedback: Material(
            color: Colors.transparent,
            child: _buildLabelCard(label, color, isDark, isFeedback: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _buildLabelCard(label, color, isDark),
          ),
          child: _buildLabelCard(label, color, isDark),
        );
      }),
    );
  }

  Widget _buildLabelCard(String label, Color color, bool isDark, {bool isFeedback = false, bool enabled = true}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12, 
            blurRadius: isFeedback ? 15 : 6, 
            offset: Offset(0, isFeedback ? 8 : 2),
          ),
        ],
        border: Border.all(
          color: isFeedback ? color : (isDark ? Colors.white10 : Colors.grey.shade300),
          width: 2,
        ),
      ),
      child: Text(
        label.toUpperCase(), 
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 12.sp, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
