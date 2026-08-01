import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_scratch_overlay_painter.dart';

class FixTheSentenceDigitalBlackboard extends StatelessWidget {
  final String fullText;
  final String targetWord;
  final String? selectedReplacement;
  final bool isWiped;
  final List<Offset> erasePoints;
  final Function(Offset) onErase;
  final Color color;
  final bool isDark;

  const FixTheSentenceDigitalBlackboard({
    super.key,
    required this.fullText,
    required this.targetWord,
    required this.selectedReplacement,
    required this.isWiped,
    required this.erasePoints,
    required this.onErase,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final parts = fullText.split(targetWord);
    final String prefix = parts.isNotEmpty ? parts[0] : "";
    final String suffix = parts.length > 1 ? parts.sublist(1).join(targetWord) : "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
                children: [
                  if (prefix.isNotEmpty) TextSpan(text: prefix),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: isWiped
                        ? Builder(
                            builder: (context) {
                              final successColor = isDark
                                  ? Colors.greenAccent
                                  : const Color(0xFF16A34A);
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 8.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedReplacement != null
                                      ? successColor.withValues(alpha: 0.25)
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.black12),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: selectedReplacement != null
                                        ? successColor
                                        : (isDark
                                              ? Colors.white30
                                              : Colors.black26),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  selectedReplacement?.toUpperCase() ?? "____",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w900,
                                    color: selectedReplacement != null
                                        ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                        : (isDark
                                              ? Colors.white30
                                              : Colors.black38),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.w),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: color, width: 2),
                            ),
                            child: GestureDetector(
                              onPanUpdate: (details) =>
                                  onErase(details.localPosition),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    child: Text(
                                      targetWord.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.redAccent
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  if (erasePoints.isEmpty)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Center(
                                          child: Icon(
                                            Icons.swipe_rounded,
                                            size: 24.r,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          )
                                          .animate(onPlay: (c) => c.repeat())
                                          .moveX(begin: -15, end: 15, duration: 1.seconds, curve: Curves.easeInOutSine)
                                          .fadeIn(duration: 400.ms)
                                          .fadeOut(delay: 600.ms, duration: 400.ms),
                                        ),
                                      ),
                                    ),
                                  if (erasePoints.isNotEmpty)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter:
                                            FixTheSentenceScratchOverlayPainter(
                                              points: erasePoints,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  if (suffix.isNotEmpty) TextSpan(text: suffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
