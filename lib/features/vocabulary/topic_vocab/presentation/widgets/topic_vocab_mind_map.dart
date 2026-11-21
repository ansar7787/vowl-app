import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Semantic breakdown card displaying lexical links and meanings for topic clusters.
class TopicVocabMindMap extends StatelessWidget {
  /// List of related topical terms with definitions or collocations.
  final List<String> relatedWords;

  /// Theme accent color.
  final Color color;

  const TopicVocabMindMap({
    super.key,
    required this.relatedWords,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded, color: color, size: 18.r),
              SizedBox(width: 8.w),
              AutoSizeText(
                context.tr(
                  'instructions.topicVocab.topic_dictionary',
                  fallback: 'Word Meanings',
                ),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: relatedWords.map((word) {
              final match = RegExp(
                r'^(.*?)(?:[:\-])(.*)$',
              ).firstMatch(word);
              final key = match != null ? match.group(1)?.trim() : word;
              final value = match != null ? match.group(2)?.trim() : '';

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, color: color, size: 12.r),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: key,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            if (value != null && value.isNotEmpty)
                              TextSpan(
                                text: ' - $value',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return card;
    }

    return card
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }
}
