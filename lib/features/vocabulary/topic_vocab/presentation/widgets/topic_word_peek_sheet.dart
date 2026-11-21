import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';

/// Bottom sheet dialog providing quick contextual definitions and pronunciation
/// when a learner long-presses a word tile in the matrix.
class TopicWordPeekSheet extends StatelessWidget {
  final String word;
  final String? definition;
  final String? categoryHint;
  final Color accentColor;

  const TopicWordPeekSheet({
    super.key,
    required this.word,
    this.definition,
    this.categoryHint,
    required this.accentColor,
  });

  /// Displays the peek sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required String word,
    String? definition,
    String? categoryHint,
    required Color accentColor,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TopicWordPeekSheet(
        word: word,
        definition: definition,
        categoryHint: categoryHint,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewPadding.bottom > 0
        ? mediaQuery.viewPadding.bottom
        : mediaQuery.padding.bottom;
    final bottomPadding = 20.h + bottomInset;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20.r,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Word Header + Pronunciation
          Row(
            children: [
              Expanded(
                child: AutoSizeText(
                  word,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              TtsSpeakerButtonWidget(
                text: word,
                color: accentColor,
                size: 32.r,
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Category hint chip if available
          if (categoryHint != null && categoryHint!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_rounded, size: 14.r, color: accentColor),
                  SizedBox(width: 6.w),
                  Text(
                    'Theme: $categoryHint',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Definition / Usage note
          if (definition != null && definition!.isNotEmpty) ...[
            Text(
              definition!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Dismiss Button
          SizedBox(
            width: double.infinity,
            child: ScaleButton(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
