import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';

class SCSentenceDisplay extends StatelessWidget {
  final AccentQuest quest;
  final ThemeResult theme;
  final bool isDark;
  final String currentSpokenWord;

  const SCSentenceDisplay({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
    this.currentSpokenWord = '',
  });

  Widget _buildKaraokeSentence() {
    final originalText = quest.sentence ?? quest.word ?? "Speak naturally";
    final words = originalText.split(' ');

    return Wrap(
      alignment: WrapAlignment.center,
      children: words.map((word) {
        final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final cleanSpoken = currentSpokenWord.toLowerCase().replaceAll(
          RegExp(r'[^\w]'),
          '',
        );
        final bool isCurrent =
            cleanWord == cleanSpoken && cleanSpoken.isNotEmpty;

        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.outfit(
            fontSize: isCurrent ? 30.sp : 26.sp,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w800,
            color: isCurrent
                ? theme.primaryColor
                : (isDark ? Colors.white : Colors.black87),
            height: 1.2,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(word),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(30.r),
      borderColor: theme.primaryColor.withValues(alpha: 0.3),
      child: Column(
        children: [
          // IPA Phontic Overlay (Shown when hint used)
          if (quest.phoneticHint != null && quest.phoneticHint!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                "[ ${quest.phoneticHint} ]",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1,
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2),

          // Basic Sentence with Karaoke Highlight
          _buildKaraokeSentence(),

          if (quest.stressPattern != null &&
              quest.stressPattern!.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "RHYTHM",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: theme.primaryColor.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _buildStressPatternText(
                    quest.stressPattern!,
                    theme.primaryColor,
                    isDark,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStressPatternText(
    String pattern,
    Color primaryColor,
    bool isDark,
  ) {
    // The pattern field contains caps for stressed words (e.g. "EARly BIRD CATCHes WORM")
    // We split by space to parse individual words and style uppercase letters.
    final words = pattern.split(' ');
    final isStressedWord = RegExp(
      r'[A-Z]{2,}',
    ); // Heuristic for fully stressed words

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: words.map((word) {
        final bool isFullyStressed = isStressedWord.hasMatch(word);

        List<TextSpan> spans = [];
        for (int i = 0; i < word.length; i++) {
          final char = word[i];
          final bool isUpper =
              char == char.toUpperCase() && RegExp(r'[A-Za-z]').hasMatch(char);

          spans.add(
            TextSpan(
              text: char,
              style: GoogleFonts.outfit(
                fontSize: isFullyStressed ? 20.sp : 18.sp,
                fontWeight: isUpper ? FontWeight.w900 : FontWeight.w500,
                color: isUpper
                    ? primaryColor
                    : (isDark ? Colors.white60 : Colors.black54),
                letterSpacing: isUpper ? 0.5 : 0,
                shadows: isUpper
                    ? [
                        Shadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }

        return Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: isFullyStressed
                  ? BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4.r),
                    )
                  : null,
              child: Text.rich(TextSpan(children: spans)),
            )
            .animate(target: isFullyStressed ? 1 : 0)
            .shimmer(
              duration: 2000.ms,
              color: primaryColor.withValues(alpha: 0.2),
            );
      }).toList(),
    );
  }
}
