import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ConjunctionsBrickSheet extends StatelessWidget {
  final List<String> options;
  final String? placedBrick;
  final Color primaryColor;
  final bool isDark;

  const ConjunctionsBrickSheet({
    super.key,
    required this.options,
    required this.placedBrick,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16.w,
      runSpacing: 16.h,
      alignment: WrapAlignment.center,
      children: options.map((opt) => _buildBrick(opt)).toList(),
    );
  }

  Widget _buildBrick(String text) {
    final isPlaced = placedBrick == text;
    return Draggable<String>(
      data: text,
      feedback: _buildTactileBrick(text, isDragging: true),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _buildTactileBrick(text),
      ),
      child: isPlaced
          ? const SizedBox(width: 80, height: 50)
          : _buildTactileBrick(text),
    );
  }

  Widget _buildTactileBrick(String text, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: isDragging ? 15 : 5,
              offset: isDragging ? const Offset(5, 5) : const Offset(2, 2),
            ),
          ],
          border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
