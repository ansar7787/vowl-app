import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';

class GameEvalButton extends StatefulWidget {
  const GameEvalButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<GameEvalButton> createState() => _GameEvalButtonState();
}

class _GameEvalButtonState extends State<GameEvalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _isPressed ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: widget.color, size: 24.sp),
                SizedBox(height: 4.h),
                AutoSizeText(
                  widget.title,
                  maxLines: 1,
                  minFontSize: 8,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
