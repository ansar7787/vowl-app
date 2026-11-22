import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_learn_quest.dart';

/// Interactive word item card for the Learn phase blueprint tree.
/// Displays word, phonetics, definition, natural collocation, TTS audio playback,
/// and 1-click on-device AI translation into the learner's native language.
class TopicWordItemCard extends StatefulWidget {
  final TopicWordDetail word;
  final Color accentColor;
  final bool isDark;

  const TopicWordItemCard({
    super.key,
    required this.word,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<TopicWordItemCard> createState() => _TopicWordItemCardState();
}

class _TopicWordItemCardState extends State<TopicWordItemCard> {
  String? _translatedDefinition;
  String? _translatedCollocation;
  bool _showTranslated = false;

  String _buildTranslatableContent() {
    final w = widget.word;
    if (w.collocation.isNotEmpty) {
      return '${w.definition}\n---\n${w.collocation}';
    }
    return w.definition.isNotEmpty ? w.definition : w.word;
  }

  void _handleTranslationComplete(String fullText) {
    if (!mounted) return;
    final parts = fullText.split(RegExp(r'\n?---\n?'));
    setState(() {
      _translatedDefinition = parts.isNotEmpty && parts[0].isNotEmpty
          ? parts[0].trim()
          : fullText.trim();
      _translatedCollocation = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1].trim()
          : null;
      _showTranslated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    final isDark = widget.isDark;
    final accent = widget.accentColor;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Word, IPA + Actions (TTS Speaker & Translate)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        w.word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (w.ipa.isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      Text(
                        w.ipa,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TtsSpeakerButtonWidget(
                text: w.word,
                color: accent,
                size: 26.r,
              ),
              SizedBox(width: 4.w),
              TranslateButtonWidget(
                originalText: _buildTranslatableContent(),
                onTranslationComplete: _handleTranslationComplete,
              ),
            ],
          ),

          // English Definition
          if (w.definition.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              w.definition,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],

          // 1-Click AI Offline Native Translation Banner
          if (_showTranslated && _translatedDefinition != null) ...[
            SizedBox(height: 5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 13.r,
                    color: AppColors.emerald500,
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      _translatedDefinition!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.emerald400 : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Natural Usage Collocation
          if (w.collocation.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 7.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 11.r,
                    color: accent,
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      _showTranslated && _translatedCollocation != null
                          ? '${w.collocation} (${_translatedCollocation!})'
                          : w.collocation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
