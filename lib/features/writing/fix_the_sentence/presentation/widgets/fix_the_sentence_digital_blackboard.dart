import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_scratch_overlay_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colordc2626 = Color(0xFFDC2626);
}

class FixTheSentenceDigitalBlackboard extends StatelessWidget {
  final String fullText;
  final String targetWord;
  final String? selectedReplacement;
  final bool isWiped;
  final Listenable eraseListenable;
  final List<Offset> Function() getErasePoints;
  final Function(Offset) onErase;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const FixTheSentenceDigitalBlackboard({
    super.key,
    required this.fullText,
    required this.targetWord,
    required this.selectedReplacement,
    required this.isWiped,
    required this.eraseListenable,
    required this.getErasePoints,
    required this.onErase,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final String escapedTarget = RegExp.escape(targetWord);
    final RegExp wordRegExp = RegExp(
      r'(?<![a-zA-Z0-9_])' + escapedTarget + r'(?![a-zA-Z0-9_])',
      caseSensitive: false,
    );
    final Match? match = wordRegExp.firstMatch(fullText);

    String prefix = "";
    String suffix = "";
    String targetDisplay = targetWord;

    if (match != null) {
      prefix = fullText.substring(0, match.start);
      targetDisplay = fullText.substring(match.start, match.end);
      suffix = fullText.substring(match.end);
    } else {
      final parts = fullText.split(targetWord);
      prefix = parts.isNotEmpty ? parts[0] : "";
      suffix = parts.length > 1 ? parts.sublist(1).join(targetWord) : "";
    }

    final successColor = isDark ? tokens.gameCorrect : KidsColors.safeGreen;
    final errorColor = isDark ? tokens.gameIncorrect : _LocalPalette.colordc2626;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.04)),
          RichText(
            textAlign: TextAlign.center,
            softWrap: true,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1E293B),
                height: 1.6,
                letterSpacing: 0.2,
              ),
              children: [
                if (prefix.isNotEmpty) TextSpan(text: prefix),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 96.w,
                    ),
                    child: isWiped
                        ? Container(
                            key: const Key('fix_the_sentence_wiped_target'),
                            margin: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: selectedReplacement != null ? 10.w : 14.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: selectedReplacement != null
                                  ? successColor.withValues(alpha: isDark ? 0.22 : 0.14)
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: selectedReplacement != null
                                    ? successColor
                                    : (isDark ? Colors.white30 : Colors.black26),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              selectedReplacement ?? "____",
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: selectedReplacement != null
                                    ? (isDark ? Colors.white : successColor)
                                    : (isDark ? Colors.white54 : Colors.black45),
                              ),
                            ),
                          )
                        : Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: errorColor.withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: errorColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: GestureDetector(
                              key: const Key('fix_the_sentence_scratch_target'),
                              onTap: onTap,
                              onPanUpdate: (details) =>
                                  onErase(details.localPosition),
                              child: ListenableBuilder(
                                listenable: eraseListenable,
                                builder: (context, _) {
                                  final erasePoints = getErasePoints();
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 4.h,
                                        ),
                                        child: Text(
                                          targetDisplay,
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                            color: errorColor,
                                          ),
                                        ),
                                      ),
                                      if (erasePoints.isEmpty)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Center(
                                              child: Icon(
                                                Icons.swipe_rounded,
                                                size: 22.r,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              )
                                                  .animate(
                                                    onPlay: (c) {
                                                      if (!VowlMotion
                                                          .lowAnimationModeOverride
                                                          .value) {
                                                        c.repeat();
                                                      }
                                                    },
                                                  )
                                                  .moveX(
                                                    begin: -12,
                                                    end: 12,
                                                    duration: 1.seconds,
                                                    curve: Curves.easeInOutSine,
                                                  )
                                                  .fadeIn(duration: 300.ms)
                                                  .fadeOut(
                                                    delay: 500.ms,
                                                    duration: 300.ms,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      if (erasePoints.isNotEmpty)
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(7.r),
                                            child: CustomPaint(
                                              painter:
                                                  FixTheSentenceScratchOverlayPainter(
                                                    points: erasePoints,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ),
                if (suffix.isNotEmpty) TextSpan(text: suffix),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
