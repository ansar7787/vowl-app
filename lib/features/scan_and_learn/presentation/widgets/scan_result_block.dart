import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ScanResultBlock extends StatelessWidget {
  final TextBlock block;
  final int index;
  final String? translatedText;
  final bool isTranslating;
  final void Function(int, String) onTranslate;

  const ScanResultBlock({
    super.key,
    required this.block,
    required this.index,
    required this.translatedText,
    required this.isTranslating,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIndigo = const Color(0xFF6366F1);
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1);
    final bgColor = isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r), // Sharper, document-like corners
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (translatedText != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: primaryIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: primaryIndigo.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.g_translate_rounded, color: primaryIndigo, size: 18.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          translatedText!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            color: isDark ? const Color(0xFF818CF8) : primaryIndigo,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isTranslating) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  height: 3.h, 
                  width: double.infinity, 
                  child: LinearProgressIndicator(color: primaryIndigo),
                ),
              ] else ...[
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: ScaleButton(
                    onTap: () => onTranslate(index, block.text),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: primaryIndigo.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.g_translate_rounded, color: primaryIndigo, size: 16.r),
                          SizedBox(width: 6.w),
                          Text(
                            context.tr('translation.translate', fallback: 'Translate'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
