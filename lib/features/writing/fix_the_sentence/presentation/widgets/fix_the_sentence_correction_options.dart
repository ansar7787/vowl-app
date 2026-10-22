import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FixTheSentenceCorrectionOptions extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color color;
  final bool isDark;
  final Function(String, String) onSelect;

  const FixTheSentenceCorrectionOptions({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        return ScaleButton(
          key: Key('fix_the_sentence_option_$o'),
          onTap: () => onSelect(o, correct),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 64.w,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                o,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
