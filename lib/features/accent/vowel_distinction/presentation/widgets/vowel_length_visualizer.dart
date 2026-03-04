import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';

class VowelLengthVisualizer extends StatelessWidget {
  final AccentQuest quest;
  final ThemeResult theme;

  const VowelLengthVisualizer({
    super.key,
    required this.quest,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    bool isFirstLong = quest.ipa1?.contains('ː') ?? false;
    bool isSecondLong = quest.ipa2?.contains('ː') ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLengthBar(quest.word1 ?? "", isFirstLong, theme),
        SizedBox(width: 40.w),
        _buildLengthBar(quest.word2 ?? "", isSecondLong, theme),
      ],
    );
  }

  Widget _buildLengthBar(String word, bool isLong, ThemeResult theme) {
    return Column(
      children: [
        Text(
          word.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: isLong ? 60.w : 20.w,
          height: 8.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(4.r),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
