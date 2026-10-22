import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color4285f4 = Color(0xFF4285F4);
  static const Color colore94335 = Color(0xFFE94335);
  static const Color colorBlueDark = Color(0xFF64B5F6);
  static const Color colorRedDark = Color(0xFFFF7A6E);
}

class DialectFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String word;
  final String britishPronunciation; // "SHED-yool"
  final String americanPronunciation; // "SKED-yool"
  final String? hint;
  final String? explanation;
  final String? dialectNote;
  final Function(String text, String locale) onPlayAudio;
  final bool isDark;
  final bool isMidnight;

  const DialectFeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.word,
    required this.britishPronunciation,
    required this.americanPronunciation,
    this.hint,
    this.explanation,
    this.dialectNote,
    required this.onPlayAudio,
    required this.isDark,
    required this.isMidnight,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final color = isCorrect ? tokens.gameCorrect : Colors.orangeAccent;

    final brColor = isDark
        ? _LocalPalette.colorRedDark
        : _LocalPalette.colore94335;
    final amColor = isDark
        ? _LocalPalette.colorBlueDark
        : _LocalPalette.color4285f4;

    Widget iconWidget = Icon(
      isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
      color: color,
      size: 28.r,
    );
    if (!reduceMotion) {
      iconWidget = iconWidget.animate().scale(delay: 150.ms);
    }

    Widget content = GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      borderColor: color.withValues(alpha: isDark ? 0.35 : 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: iconWidget,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect
                          ? context.tr('games.correct', fallback: 'Correct!')
                          : context.tr(
                              'games.lets_review',
                              fallback: "Let's Review",
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.tr(
                        'games.accent_comparison',
                        fallback: 'Accent Comparison',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Transcription Text Visualization
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // British Pronunciation Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: brColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: brColor.withValues(alpha: isDark ? 0.25 : 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${context.tr('games.british', fallback: 'British')}: ",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            britishPronunciation,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: brColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),

                // American Pronunciation Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: amColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: amColor.withValues(alpha: isDark ? 0.25 : 0.18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${context.tr('games.american', fallback: 'American')}: ",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            americanPronunciation,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: amColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (hint != null) ...[
                  SizedBox(height: 14.h),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // Dialect Audio Playback Buttons
          Row(
            children: [
              Expanded(
                child: _buildAudioButton(
                  key: const ValueKey('feedback_audio_british'),
                  title: context
                      .tr('games.british', fallback: 'British')
                      .toUpperCase(),
                  icon: Icons.record_voice_over_rounded,
                  textToPlay: word,
                  locale: "en-GB",
                  bgColor: brColor.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  textColor: brColor,
                  borderColor: brColor.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAudioButton(
                  key: const ValueKey('feedback_audio_american'),
                  title: context
                      .tr('games.american', fallback: 'American')
                      .toUpperCase(),
                  icon: Icons.record_voice_over_rounded,
                  textToPlay: word,
                  locale: "en-US",
                  bgColor: amColor.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  textColor: amColor,
                  borderColor: amColor.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                ),
              ),
            ],
          ),
          if (explanation != null) ...[
            SizedBox(height: 16.h),
            PedagogicalRuleBox(
              icon: Icons.lightbulb_outline_rounded,
              capsKey: 'games.explanation_caps',
              capsFallback: 'EXPLANATION',
              titleKey: 'games.explanation',
              titleFallback: 'Explanation',
              rule: explanation!,
              shadowColor: color,
              isDark: isDark,
            ),
          ],
          if (dialectNote != null) ...[
            SizedBox(height: 14.h),
            PedagogicalRuleBox(
              icon: Icons.public_rounded,
              capsKey: 'games.dialect_note_caps',
              capsFallback: 'DIALECT NOTE',
              titleKey: 'games.dialect_note',
              titleFallback: 'Dialect Note',
              rule: dialectNote!,
              shadowColor: color,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );

    if (!reduceMotion) {
      content = content.animate().fadeIn(duration: 350.ms).slideY(begin: 0.1);
    }

    return content;
  }

  Widget _buildAudioButton({
    Key? key,
    required String title,
    required IconData icon,
    required String textToPlay,
    required String locale,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return ElevatedButton.icon(
      key: key,
      onPressed: () => onPlayAudio(textToPlay, locale),
      icon: Icon(icon, size: 18.r, color: textColor),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: textColor,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
      ),
    );
  }
}
