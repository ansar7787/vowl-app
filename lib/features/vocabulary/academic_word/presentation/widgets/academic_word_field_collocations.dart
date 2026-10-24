import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Card displaying academic domain metadata, associated field collocations, and contextual usage sentences.
class AcademicWordFieldCollocations extends StatelessWidget {
  /// The scholarly or disciplinary domain (e.g., Biology, Philosophy).
  final String? academicField;

  /// High-frequency lexical collocations paired with the target academic word.
  final List<String>? collocations;

  /// Example sentence demonstrating context and register.
  final String? contextSentence;

  /// Dominant accent color for icons, borders, and badges.
  final Color color;

  /// Creates an [AcademicWordFieldCollocations] widget.
  const AcademicWordFieldCollocations({
    super.key,
    this.academicField,
    this.collocations,
    this.contextSentence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      key: const Key('academic_word_field_collocations_card'),
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (academicField != null) ...[
            Row(
              key: const Key('academic_word_field_row'),
              children: [
                Icon(Icons.school_rounded, color: color, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: AutoSizeText(
                    "ACADEMIC FIELD: ${academicField!.toUpperCase()}",
                    key: const Key('academic_word_field_text'),
                    maxLines: 2,
                    minFontSize: 10,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (collocations != null && collocations!.isNotEmpty) ...[
            if (academicField != null) SizedBox(height: 12.h),
            Text(
              "Common Collocations:",
              key: const Key('academic_word_collocations_label'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              key: const Key('academic_word_collocations_wrap'),
              spacing: 8.w,
              runSpacing: 8.h,
              children: collocations!.asMap().entries.map((entry) {
                final index = entry.key;
                final colloc = entry.value;
                return Container(
                  key: Key('academic_word_collocation_chip_$index'),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    colloc,
                    key: Key('academic_word_collocation_text_$index'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (contextSentence != null) ...[
            if (academicField != null ||
                (collocations != null && collocations!.isNotEmpty))
              SizedBox(height: 16.h),
            Row(
              key: const Key('academic_word_context_sentence_row'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, color: color, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    contextSentence!,
                    key: const Key('academic_word_context_sentence_text'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.black87,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (VowlMotion.lowAnimationModeOverride.value) {
      return card;
    }

    return card
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
