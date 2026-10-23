import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

class ConjunctionsBrickSheet extends StatelessWidget {
  final List<String> options;
  final String? placedBrick;
  final Color primaryColor;
  final bool isDark;
  final bool isCompact;
  final bool isAnswered;
  final Function(String)? onBrickTapped;

  const ConjunctionsBrickSheet({
    super.key,
    required this.options,
    required this.placedBrick,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
    this.isAnswered = false,
    this.onBrickTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: isCompact ? 10.w : 14.w,
      runSpacing: isCompact ? 10.h : 12.h,
      alignment: WrapAlignment.center,
      children: options.map((opt) => _buildBrick(opt)).toList(),
    );
  }

  Widget _buildBrick(String text) {
    final isPlaced = placedBrick == text;
    final canInteract = !isPlaced && !isAnswered;
    return GestureDetector(
      key: ValueKey('conjunction_brick_$text'),
      onTap: (canInteract && onBrickTapped != null)
          ? () => onBrickTapped!(text)
          : null,
      child: Draggable<String>(
        maxSimultaneousDrags: canInteract ? 1 : 0,
        data: text,
        feedback: _buildTactileBrick(text, isDragging: true),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: _buildTactileBrick(text),
        ),
        child: isPlaced
            ? SizedBox(
                width: isCompact ? 64.w : 78.w,
                height: isCompact ? 38.h : 44.h,
              )
            : _buildTactileBrick(text),
      ),
    );
  }

  Widget _buildTactileBrick(String text, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16.w : 20.w,
          vertical: isCompact ? 8.h : 11.h,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222B) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDragging ? 0.2 : 0.06),
              blurRadius: isDragging ? 12 : 6,
              offset: isDragging ? const Offset(0, 6) : const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: primaryColor.withValues(alpha: isDragging ? 0.7 : 0.25),
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCompact ? 13.5.sp : 15.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.slate900,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
