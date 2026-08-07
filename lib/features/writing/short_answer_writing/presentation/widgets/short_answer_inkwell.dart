import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShortAnswerInkwell extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnswered;
  final int wordCount;
  final double inkLevel;
  final Color color;
  final bool isDark;

  const ShortAnswerInkwell({
    super.key,
    required this.controller,
    required this.isAnswered,
    required this.wordCount,
    required this.inkLevel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isAnswered
              ? color.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 2,
        ),
        boxShadow: isAnswered
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18.r, color: color),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "YOUR RESPONSE",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          color: color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: wordCount >= 10
                      ? (isDark
                            ? Colors.greenAccent.withValues(alpha: 0.1)
                            : const Color(0xFF16A34A).withValues(alpha: 0.1))
                      : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  "$wordCount / 10 WORDS MIN",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.sp,
                    color: wordCount >= 10
                        ? (isDark
                              ? Colors.greenAccent
                              : const Color(0xFF16A34A))
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: controller,
            maxLines: 5,
            enabled: !isAnswered,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: "Type your analytical response here...",
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white30 : Colors.black38,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
            ),
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              AnimatedContainer(
                duration: 300.milliseconds,
                width: MediaQuery.of(context).size.width * inkLevel * 0.8,
                height: 4.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
