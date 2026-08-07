import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ml_services/entity_extraction_service.dart';

class EntityHighlightedText extends StatelessWidget {
  final String text;
  final List<EntityAnnotation> annotations;
  final TextStyle style;
  final bool isDark;

  const EntityHighlightedText({
    super.key,
    required this.text,
    required this.annotations,
    required this.style,
    required this.isDark,
  });

  void _showEntityTooltip(
    BuildContext context,
    EntityAnnotation annotation,
    Entity entity,
  ) {
    final extractedStr = text.substring(annotation.start, annotation.end);

    // Formatting the entity type for display (e.g. EntityType.dateTime -> "Date Time")
    String typeName = entity.type.name;
    typeName = typeName
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .trim();
    typeName = typeName[0].toUpperCase() + typeName.substring(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: di.sl<EntityExtractionService>().getColorForEntity(
                    entity.type,
                  ),
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  typeName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.05,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                extractedStr,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) {
      return Text(text, style: style);
    }

    // Sort annotations by start index just in case
    final sortedAnnotations = List<EntityAnnotation>.from(annotations)
      ..sort((a, b) => a.start.compareTo(b.start));

    List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (var annotation in sortedAnnotations) {
      if (annotation.start > currentIndex) {
        // Add normal text before the annotation
        spans.add(
          TextSpan(text: text.substring(currentIndex, annotation.start)),
        );
      }

      if (annotation.start >= currentIndex) {
        // Add highlighted text
        final entity = annotation.entities.isNotEmpty
            ? annotation.entities.first
            : null;
        final color = entity != null
            ? di.sl<EntityExtractionService>().getColorForEntity(entity.type)
            : Colors.blue;

        spans.add(
          TextSpan(
            text: text.substring(annotation.start, annotation.end),
            style: style.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: color.withValues(alpha: 0.5),
              decorationStyle: TextDecorationStyle.dashed,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (entity != null) {
                  _showEntityTooltip(context, annotation, entity);
                }
              },
          ),
        );
        currentIndex = annotation.end;
      }
    }

    if (currentIndex < text.length) {
      // Add remaining normal text
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
    );
  }
}
