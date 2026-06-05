import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SentenceBuilderJigsawPiece extends StatelessWidget {
  final String text;
  final bool isAssembled;
  final VoidCallback? onTap;
  final Color color;
  final bool isDark;
  final bool isDragging;

  const SentenceBuilderJigsawPiece({
    super.key,
    required this.text,
    required this.isAssembled,
    this.onTap,
    required this.color,
    required this.isDark,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isAssembled 
              ? color.withValues(alpha: 0.25) 
              : (isDark ? Colors.black45 : Colors.white),
          border: Border.all(
            color: isAssembled 
                ? color 
                : (isDark ? Colors.white24 : Colors.black12), 
            width: 2
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.r),
            bottomLeft: Radius.circular(8.r),
            topRight: Radius.circular(20.r),
            bottomRight: Radius.circular(20.r),
          ),
          boxShadow: [
            if (isDragging || isAssembled) 
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text, 
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 14.sp, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : Colors.black87
              )
            ),
            if (!isAssembled) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.extension_rounded, 
                size: 14.r, 
                color: isDark ? Colors.white24 : Colors.black26
              ),
            ],
          ],
        ),
      ),
    ).animate(target: isAssembled ? 1 : 0).shimmer(duration: 1.seconds);
  }
}
