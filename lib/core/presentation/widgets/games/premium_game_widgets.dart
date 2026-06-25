import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:vowl/core/utils/locale_service.dart';

class PremiumGameHeader extends StatelessWidget {
  final double progress;
  final int lives;
  final int? hintCount;
  final VoidCallback onHint;
  final VoidCallback onHintAd;
  final VoidCallback onClose;
  final bool isDark;
  final bool isMidnight;

  const PremiumGameHeader({
    super.key,
    required this.progress,
    required this.lives,
    this.hintCount,
    required this.onHint,
    required this.onHintAd,
    required this.onClose,
    this.isDark = false,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          _buildCloseButton(context),
          SizedBox(width: 16.w),
          Expanded(child: _buildProgressBar(context)),
          SizedBox(width: 16.w),
          _buildHeartCount(context),
          if (hintCount != null) ...[
            SizedBox(width: 12.w),
            _buildHintButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('common.close', fallback: 'Close'),
      child: GestureDetector(
        onTap: onClose,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Invisible floor guaranteeing the 48dp accessible touch target;
          // the visible glyph below keeps its original compact size.
          constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
          alignment: Alignment.center,
          child: ExcludeSemantics(
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isMidnight
                    ? Colors.white.withValues(alpha: 0.15)
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20.r,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Semantics(
      label: context.tr(
        'games.progress_label',
        args: [(progress.clamp(0.0, 1.0) * 100).round().toString()],
        fallback: '${(progress.clamp(0.0, 1.0) * 100).round()}% complete',
      ),
      child: ExcludeSemantics(
        // BUG FIX: this used to compute its fill width as
        // `(1.sw - 180.w) * progress` — a magic-number guess at how much
        // horizontal space the close button + heart count + (optional)
        // hint button take up. That guess silently went stale whenever
        // hints were disabled (no hint button, so more room was actually
        // available) or the heart count's digit width changed. This is
        // already wrapped in `Expanded` by the parent Row, which already
        // computes the *exact* remaining width correctly — LayoutBuilder
        // just reads that real value instead of re-guessing it.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 12.h,
                  width: trackWidth,
                  decoration: BoxDecoration(
                    color: isMidnight
                        ? Colors.white24
                        : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                AnimatedContainer(
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                  height: 12.h,
                  width: trackWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeartCount(BuildContext context) {
    return Semantics(
      label: context.tr(
        'games.lives_remaining',
        args: [lives.toString()],
        fallback: '$lives lives remaining',
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: const Color(0xFFF43F5E),
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              Text(
                lives.toString(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: const Color(0xFFF43F5E),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton(BuildContext context) {
    final bool hasHints = (hintCount ?? 0) > 0;
    final color = hasHints ? const Color(0xFFEAB308) : const Color(0xFF10B981);
    final label = hasHints
        ? context.tr(
            'games.use_hint',
            args: [(hintCount ?? 0).toString()],
            fallback: 'Use hint (${hintCount ?? 0} left)',
          )
        : context.tr(
            'games.watch_ad_for_hint',
            fallback: 'Watch an ad for a hint',
          );

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: hasHints ? onHint : onHintAd,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Same invisible-floor pattern as the close button: guarantees
          // 48dp without enlarging the visible badge+icon design.
          constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
          alignment: Alignment.center,
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    hasHints
                        ? Icons.lightbulb_rounded
                        : Icons.play_circle_fill_rounded,
                    color: color,
                    size: 18.r,
                  ),
                ),
                if (hasHints)
                  Positioned(
                    top: -4.r,
                    right: -4.r,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAB308),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        hintCount.toString(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumMicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  final Color primaryColor;

  const PremiumMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isListening
          ? context.tr('games.stop_recording', fallback: 'Stop recording')
          : context.tr('games.start_recording', fallback: 'Start recording'),
      child: GestureDetector(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isListening)
                Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      duration: 1000.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(),
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumAudioButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Color primaryColor;

  const PremiumAudioButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isPlaying
          ? context.tr('games.pause_audio', fallback: 'Pause audio')
          : context.tr('games.play_audio', fallback: 'Play audio'),
      child: GestureDetector(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isPlaying)
                Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      duration: 1000.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(),
              Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumHintOverlay extends StatelessWidget {
  final String hint;
  final VoidCallback onClose;

  const PremiumHintOverlay({
    super.key,
    required this.hint,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Announces this overlay as a self-contained modal region so screen
      // readers read the hint as one coherent block rather than treating it
      // as just more content behind whatever triggered it.
      container: true,
      liveRegion: true,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: const Color(0xFFEAB308),
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr('games.hint').toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFEAB308),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAB308),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: onClose,
                    child: Text(context.tr('games.got_it')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class PremiumWaveVisualizer extends StatefulWidget {
  final bool isListening;
  final Color primaryColor;

  const PremiumWaveVisualizer({
    super.key,
    required this.isListening,
    required this.primaryColor,
  });

  @override
  State<PremiumWaveVisualizer> createState() => _PremiumWaveVisualizerState();
}

class _PremiumWaveVisualizerState extends State<PremiumWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(double.infinity, 100.h),
            painter: _PremiumWavePainter(
              animationValue: _controller.value,
              isListening: widget.isListening,
              color: widget.primaryColor,
            ),
          ),
        );
      },
    );
  }
}

// RENAMED from the previously-public `WavePainter`: `harmonic_waves.dart`
// (also in this package) independently declares its own public class also
// named `WavePainter`. Two public classes with the same name in the same
// package compile fine until some third file ever imports both without
// disambiguation — at which point it's an "ambiguous import" error that's
// confusing to track down. This one is only ever used inside this same
// file, so privatizing it removes the collision risk entirely with zero
// behavior change.
class _PremiumWavePainter extends CustomPainter {
  final double animationValue;
  final bool isListening;
  final Color color;

  _PremiumWavePainter({
    required this.animationValue,
    required this.isListening,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final centerY = size.height / 2;
    final halfWidth = size.width / 2;
    if (halfWidth <= 0) return;

    // PERF: this paints on every animation frame (the AnimatedBuilder above
    // constructs a new painter with a changed `animationValue` every tick,
    // so `shouldRepaint` is true ~60x/sec while listening). Sampling every
    // pixel was costing two sine evaluations per pixel per frame — visually
    // indistinguishable from sampling every 3px once stroked with
    // anti-aliasing, but roughly a third of the per-frame CPU cost on
    // low-end devices.
    const sampleStep = 3.0;

    for (double i = 0; i <= size.width; i += sampleStep) {
      final x = i;
      final wave1 =
          15 *
          (isListening ? 1.0 : 0.2) *
          (1 - ((i - halfWidth).abs() / halfWidth)) *
          math.sin((i / 40) + (animationValue * 10));

      final wave2 =
          10 *
          (isListening ? 1.0 : 0.2) *
          (1 - ((i - halfWidth).abs() / halfWidth)) *
          math.sin((i / 30) - (animationValue * 15));

      if (i == 0) {
        path.moveTo(x, centerY + wave1 + wave2);
      } else {
        path.lineTo(x, centerY + wave1 + wave2);
      }
    }

    canvas.drawPath(path, paint);

    // Draw a second, thinner wave for depth
    final path2 = Path();
    paint.strokeWidth = 1.0;
    paint.color = color.withValues(alpha: 0.2);

    for (double i = 0; i <= size.width; i += sampleStep) {
      final x = i;
      final wave3 =
          8 *
          (isListening ? 1.0 : 0.2) *
          (1 - ((i - halfWidth).abs() / halfWidth)) *
          math.sin((i / 20) + (animationValue * 20));

      if (i == 0) {
        path2.moveTo(x, centerY + wave3);
      } else {
        path2.lineTo(x, centerY + wave3);
      }
    }
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isListening != isListening ||
        oldDelegate.color != color;
  }
}
