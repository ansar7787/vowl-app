import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordLabSentence extends StatelessWidget {
  final dynamic quest;
  final ThemeResult theme;
  final bool isDark;
  final int? selectedOptionIndex;
  final bool hintUsed;
  final int hintCount;
  final VoidCallback onUseHint;

  const WordLabSentence({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    this.selectedOptionIndex,
    required this.hintUsed,
    required this.hintCount,
    required this.onUseHint,
  });

  @override
  Widget build(BuildContext context) {
    final sentence = quest.contextSentence ?? quest.sentence ?? "---";
    final parts = sentence.split(RegExp(r'_+'));

    return GlassTile(
      padding: EdgeInsets.all(14.r),
      borderRadius: BorderRadius.circular(24.r),
      borderColor: theme.primaryColor.withValues(alpha: 0.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, color: theme.primaryColor.withValues(alpha: 0.5), size: 14.r),
          SizedBox(height: 8.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.3,
              ),
              children: [
                if (parts.isNotEmpty) TextSpan(text: parts[0]),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: selectedOptionIndex != null ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      selectedOptionIndex != null ? quest.options![selectedOptionIndex!] : "      ",
                      style: GoogleFonts.shareTechMono(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
                if (parts.length > 1) TextSpan(text: parts[1]),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _buildHintButton(),
        ],
      ),
    );
  }

  Widget _buildHintButton() {
    final canUse = !hintUsed && hintCount > 0;
    return ScaleButton(
      onTap: canUse ? onUseHint : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: !canUse ? Colors.grey.withValues(alpha: 0.1) : theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: !canUse ? Colors.grey.withValues(alpha: 0.2) : theme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tips_and_updates_outlined, color: !canUse ? Colors.grey : theme.primaryColor, size: 14.r),
            SizedBox(width: 6.w),
            Text(
              hintUsed ? "ANALYZED" : (hintCount > 0 ? "ANALYZE ($hintCount)" : "NO DATA"),
              style: GoogleFonts.shareTechMono(fontSize: 9.sp, color: !canUse ? Colors.grey : theme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
