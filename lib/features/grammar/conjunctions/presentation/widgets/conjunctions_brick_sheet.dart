import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ConjunctionsBrickSheet extends StatelessWidget {
  final List<String> options;
  final String? placedBrick;
  final Color primaryColor;
  final bool isDark;

  final bool isCompact;

  const ConjunctionsBrickSheet({
    super.key,
    required this.options,
    required this.placedBrick,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: isCompact ? 10.w : 16.w,
      runSpacing: isCompact ? 10.h : 16.h,
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
          ? SizedBox(
              width: isCompact ? 60.w : 80.w,
              height: isCompact ? 35.h : 50.h,
            )
          : _buildTactileBrick(text),
    );
  }

  Widget _buildTactileBrick(String text, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14.w : 20.w,
          vertical: isCompact ? 6.h : 12.h,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(isCompact ? 8.r : 12.r),
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
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: isCompact ? 12.sp : 16.sp,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
