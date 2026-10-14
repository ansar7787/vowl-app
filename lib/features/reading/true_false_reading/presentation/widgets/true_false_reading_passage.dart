import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrueFalseReadingPassage extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;
  final VoidCallback? onPlayAudio;

  const TrueFalseReadingPassage({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Passage: $passage.${onPlayAudio != null ? " Double tap audio button to listen." : ""}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.05 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onPlayAudio != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 16.r,
                        color: color.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'PASSAGE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    key: const ValueKey('passage_audio_button'),
                    onTap: onPlayAudio,
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 20.r,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
            Text(
              passage,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
