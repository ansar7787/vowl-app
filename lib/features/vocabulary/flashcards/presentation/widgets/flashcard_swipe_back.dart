import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class FlashcardSwipeBack extends StatelessWidget {
  // FIX: was dynamic — now VocabularyQuest for full compile-time safety.
  final VocabularyQuest quest;
  final Color color;
  final bool isDark;
  final double width;
  final double height;
  final bool isHintActive;

  const FlashcardSwipeBack({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.width,
    required this.height,
    required this.isHintActive,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Definition: ${quest.definition ?? ""}. '
          '${quest.example != null ? "Example: ${quest.example}" : ""}',
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 280 || constraints.maxWidth < 280;
            final dividerInset = (constraints.maxWidth * 0.12).clamp(
              16.0,
              40.0,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48.r,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 8.h),
                    Text(
                      'DEFINITION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: compact ? 12.h : 16.h),
                    Text(
                      quest.definition ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: compact ? 17.sp : 19.sp,
                        color: isHintActive
                            ? color
                            : (isDark ? Colors.white : Colors.black87),
                        height: 1.4,
                        fontWeight: isHintActive
                            ? FontWeight.w900
                            : FontWeight.w500,
                        shadows: isHintActive
                            ? [
                                Shadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    SizedBox(height: compact ? 18.h : 28.h),
                    Divider(
                      color: color.withValues(alpha: 0.1),
                      thickness: 1,
                      indent: dividerInset,
                      endIndent: dividerInset,
                    ),
                    SizedBox(height: compact ? 16.h : 24.h),
                    Text(
                      'EXAMPLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      quest.example ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: compact ? 14.sp : 15.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                    if (quest.explanation != null &&
                        quest.explanation!.isNotEmpty) ...[
                      SizedBox(height: compact ? 18.h : 24.h),
                      Text(
                        'EXPLANATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        quest.explanation!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: compact ? 13.sp : 14.sp,
                          color: isDark ? Colors.white60 : Colors.black45,
                          height: 1.5,
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
