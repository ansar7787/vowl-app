import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadAndAnswerFloatingPassage extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  final VoidCallback? onPlayAudio;

  const ReadAndAnswerFloatingPassage({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reading passage: $text. ${onPlayAudio != null ? "Double tap audio button to listen." : ""}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
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
                  Semantics(
                    label: 'Listen to passage',
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('read_and_answer_tts_passage_button'),
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: onPlayAudio,
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                color: color,
                                size: 18.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'LISTEN',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17.sp,
                height: 1.65,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.slate800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
