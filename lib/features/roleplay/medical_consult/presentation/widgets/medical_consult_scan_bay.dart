import 'package:vowl/core/theme/app_color_tokens.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_radar_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

class MedicalConsultScanBay extends StatelessWidget {
  final List<String> symptoms;
  final Color color;
  final bool isDark;
  final ValueNotifier<Offset> scanOffsetNotifier;
  final List<String> scannedGlitches;
  final Animation<double> sweepAnimation;
  final Function(DragUpdateDetails, List<String>) onScanUpdate;
  final VoidCallback onScanStart;
  final VoidCallback onScanEnd;
  final Function(String) onSymptomScannedDirectly;

  const MedicalConsultScanBay({
    super.key,
    required this.symptoms,
    required this.color,
    required this.isDark,
    required this.scanOffsetNotifier,
    required this.scannedGlitches,
    required this.sweepAnimation,
    required this.onScanUpdate,
    required this.onScanStart,
    required this.onScanEnd,
    required this.onSymptomScannedDirectly,
  });

  Offset _getAnatomicalOffset(String text, int index, int total) {
    final lower = text.toLowerCase();
    Offset baseOffset = Offset.zero;
    bool found = true;

    if (lower.contains("head") ||
        lower.contains("brain") ||
        lower.contains("headache") ||
        lower.contains("vision") ||
        lower.contains("ear") ||
        lower.contains("throat") ||
        lower.contains("dizzy") ||
        lower.contains("sinus") ||
        lower.contains("nose") ||
        lower.contains("migraine") ||
        lower.contains("concussion") ||
        lower.contains("sensor") ||
        lower.contains("sensory")) {
      baseOffset = Offset(0, -95.h);
    } else if (lower.contains("left limb") ||
        lower.contains("left arm") ||
        lower.contains("left hand") ||
        lower.contains("shoulder")) {
      baseOffset = Offset(-64.w, -25.h);
    } else if (lower.contains("right wing") ||
        lower.contains("right limb") ||
        lower.contains("right arm") ||
        lower.contains("right hand")) {
      baseOffset = Offset(64.w, -25.h);
    } else if (lower.contains("core") ||
        lower.contains("central") ||
        lower.contains("chest") ||
        lower.contains("heart") ||
        lower.contains("breath") ||
        lower.contains("palpitation") ||
        lower.contains("cough") ||
        lower.contains("rib")) {
      baseOffset = Offset(0, -25.h);
    } else if (lower.contains("stomach") ||
        lower.contains("abdomen") ||
        lower.contains("nausea") ||
        lower.contains("constipation") ||
        lower.contains("diarrhea") ||
        lower.contains("reflux") ||
        lower.contains("bloat") ||
        lower.contains("appetite") ||
        lower.contains("cramp")) {
      baseOffset = Offset(0, 30.h);
    } else if (lower.contains("back") || lower.contains("spine")) {
      baseOffset = Offset(30.w, 10.h);
    } else if (lower.contains("left leg") ||
        lower.contains("left foot") ||
        lower.contains("ankle") ||
        lower.contains("knee")) {
      baseOffset = Offset(-32.w, 90.h);
    } else if (lower.contains("right leg") ||
        lower.contains("right foot") ||
        lower.contains("joint")) {
      baseOffset = Offset(32.w, 90.h);
    } else {
      found = false;
    }

    double angle = (index / (total > 0 ? total : 1)) * 2 * 3.141592653589793;

    if (!found) {
      double radius = 120.h;
      baseOffset = Offset(radius * math.cos(angle), radius * math.sin(angle));
    } else {
      double jitterRadius = 18.w;
      baseOffset = Offset(
        baseOffset.dx + jitterRadius * math.cos(angle),
        baseOffset.dy + jitterRadius * math.sin(angle),
      );
    }

    return baseOffset;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      width: 1.sw,
      height: 330.h,
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color07070f
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Cybernetic scan matrix background grids
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36.r),
              child: AnimatedBuilder(
                animation: sweepAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BiometricRadarPainter(
                      animationValue: sweepAnimation.value,
                      themeColor: color,
                    ),
                  );
                },
              ),
            ),
          ),

          // Glowing wireframe patient body
          Center(
            child:
                Icon(
                      Icons.accessibility_new_rounded,
                      size: 260.r,
                      color: color.withValues(alpha: 0.1),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: 2.2.seconds,
                      color: color.withValues(alpha: 0.35),
                    ),
          ),

          // Render active symptom glitch circles dynamically mapped anatomically
          ...symptoms.asMap().entries.map((entry) {
            int index = entry.key;
            String s = entry.value;
            final Offset pos = _getAnatomicalOffset(s, index, symptoms.length);
            final bool isResolved = scannedGlitches.contains(s);

            return Positioned(
              left: (1.sw / 2) - 16.w + pos.dx,
              top: (330.h / 2) - 16.h + pos.dy,
              child: Semantics(
                label: "Scan anomaly: $s",
                hint: isResolved ? "Already scanned" : "Double tap to scan",
                button: true,
                child: GestureDetector(
                  onTap: () => onSymptomScannedDirectly(s),
                  child:
                      Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isResolved
                                  ? color.withValues(alpha: 0.2)
                                  : tokens.gameIncorrect.withValues(
                                      alpha: 0.08,
                                    ),
                              border: Border.all(
                                color: isResolved
                                    ? color
                                    : tokens.gameIncorrect.withValues(
                                        alpha: 0.7,
                                      ),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isResolved
                                              ? color
                                              : tokens.gameIncorrect)
                                          .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isResolved
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.warning_rounded,
                                color: isResolved
                                    ? color
                                    : tokens.gameIncorrect,
                                size: 14.r,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.15, 1.15),
                            duration: 1.5.seconds,
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            );
          }),

          // Interactive Drag-to-Scan lens
          Positioned(
            left: (1.sw / 2) - 50.w,
            top: (330.h / 2) - 50.h,
            child: ValueListenableBuilder<Offset>(
              valueListenable: scanOffsetNotifier,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: offset,
                  child: Listener(
                    onPointerDown: (_) => onScanStart(),
                    onPointerUp: (_) => onScanEnd(),
                    onPointerCancel: (_) => onScanEnd(),
                    child: GestureDetector(
                      onPanUpdate: (d) => onScanUpdate(d, symptoms),
                      child: Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3.0),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 15,
                            ),
                          ],
                          color: color.withValues(alpha: 0.05),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.center_focus_strong_rounded,
                            color: color,
                            size: 36.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
