import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class VowelWordCard extends StatelessWidget {
  final String word;
  final String? ipa;
  final bool isDark;
  final bool isMidnight;
  final ThemeResult theme;
  final VoidCallback onPlay;

  const VowelWordCard({
    super.key,
    required this.word,
    this.ipa,
    required this.isDark,
    this.isMidnight = false,
    required this.theme,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ipa != null && ipa!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    "[ $ipa ]",
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.primaryColor.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              _renderHighlightedWord(word, theme),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        ScaleButton(
          onTap: onPlay,
          child: Icon(
            Icons.volume_up_rounded,
            color: theme.primaryColor,
            size: 24.r,
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _renderHighlightedWord(String word, ThemeResult theme) {
    // Basic vowel highlighting logic
    final vowels = RegExp(r'[aeiouAEIOU]+');
    final parts = word.split(vowels);
    final matches = vowels.allMatches(word).toList();

    List<TextSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i].toUpperCase()));
      if (i < matches.length) {
        spans.add(
          TextSpan(
            text: matches[i].group(0)!.toUpperCase(),
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 2,
        ),
        children: spans,
      ),
    );
  }
}
