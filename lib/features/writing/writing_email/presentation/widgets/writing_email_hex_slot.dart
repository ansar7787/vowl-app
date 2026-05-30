import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WritingEmailHexSlot extends StatelessWidget {
  final String slotKey;
  final String? slotValue;
  final Color color;
  final bool isDark;
  final Function(String, String) onSlot;
  final Function(String) onClearSlot;

  const WritingEmailHexSlot({
    super.key,
    required this.slotKey,
    required this.slotValue,
    required this.color,
    required this.isDark,
    required this.onSlot,
    required this.onClearSlot,
  });

  @override
  Widget build(BuildContext context) {
    bool hasData = slotValue != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onSlot(slotKey, details.data),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        
        return GestureDetector(
          onTap: () => onClearSlot(slotKey),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: highlight ? Colors.greenAccent : (hasData ? color : color.withValues(alpha: 0.2)), 
                width: 2
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.25 : 0.08), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r)
                  ),
                  child: Text(
                    slotKey, 
                    style: GoogleFonts.shareTechMono(
                      color: color, 
                      fontSize: 9.sp, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    slotValue ?? "--- PULL NEURAL SEGMENT HERE ---", 
                    style: GoogleFonts.shareTechMono(
                      color: hasData 
                        ? (isDark ? Colors.white70 : Colors.black87) 
                        : (isDark ? Colors.white24 : Colors.black26),
                      fontSize: 11.sp,
                      fontWeight: hasData ? FontWeight.bold : FontWeight.normal
                    )
                  )
                ),
                if (hasData)
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18.r)
                    .animate().scale().fadeIn(),
              ],
            ),
          ),
        );
      },
    );
  }
}
