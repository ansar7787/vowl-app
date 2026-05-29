import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PunctuationStickerSheet extends StatelessWidget {
  final List<String> marks;
  final Color primaryColor;

  const PunctuationStickerSheet({
    super.key,
    required this.marks,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24.w,
      runSpacing: 24.h,
      children: marks.map((m) => _buildSticker(m)).toList(),
    );
  }

  Widget _buildSticker(String mark) {
    return Draggable<String>(
      data: mark,
      feedback: _buildTactileSticker(mark, isDragging: true),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _buildTactileSticker(mark),
      ),
      child: _buildTactileSticker(mark),
    );
  }

  Widget _buildTactileSticker(String mark, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 54.r,
        height: 54.r,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryColor.withValues(alpha: 0.1)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: isDragging ? 20 : 8,
              offset: isDragging ? const Offset(0, 10) : const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            mark,
            style: GoogleFonts.outfit(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .rotate(begin: -0.05, end: 0.05, duration: 2.seconds);
  }
}
