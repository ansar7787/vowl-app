import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

/// Bottom sheet dialog providing quick contextual definitions, pronunciation,
/// and 1-click offline AI translation when a learner long-presses a word tile in the matrix.
class TopicWordPeekSheet extends StatefulWidget {
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
  State<TopicWordPeekSheet> createState() => _TopicWordPeekSheetState();
}

class _TopicWordPeekSheetState extends State<TopicWordPeekSheet> {
  String? _translatedText;
  bool _showTranslated = false;

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
          color: widget.accentColor.withValues(alpha: 0.25),
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

          // Word Header + Pronunciation + Translate Button
          Row(
            children: [
              Expanded(
                child: AutoSizeText(
                  widget.word,
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
              TranslateButtonWidget(
                originalText:
                    widget.definition != null && widget.definition!.isNotEmpty
                    ? '${widget.word}: ${widget.definition}'
                    : widget.word,
                onTranslationComplete: (translated) {
                  if (mounted) {
                    setState(() {
                      _translatedText = translated;
                      _showTranslated = true;
                    });
                  }
                },
              ),
              SizedBox(width: 6.w),
              TtsSpeakerButtonWidget(
                text: widget.word,
                color: widget.accentColor,
                size: 32.r,
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Category hint chip if available
          if (widget.categoryHint != null &&
              widget.categoryHint!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hub_rounded,
                    size: 14.r,
                    color: widget.accentColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Theme: ${widget.categoryHint}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Definition / Usage note
          if (widget.definition != null && widget.definition!.isNotEmpty) ...[
            Text(
              widget.definition!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // 1-Click AI Offline Translated Output Card
          if (_showTranslated && _translatedText != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(
                  alpha: isDark ? 0.14 : 0.08,
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 15.r,
                    color: AppColors.emerald500,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _translatedText!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
