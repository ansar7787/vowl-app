import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FlashcardSwipeHints extends StatelessWidget {
  final Color color;

  const FlashcardSwipeHints({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildHintIcon(Icons.refresh_rounded, Colors.redAccent, "REVIEW"),
        _buildHintIcon(
          Icons.check_circle_rounded,
          Colors.greenAccent,
          "MASTER",
        ),
      ],
    );
  }

  Widget _buildHintIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 24.r),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).scale();
  }
}
