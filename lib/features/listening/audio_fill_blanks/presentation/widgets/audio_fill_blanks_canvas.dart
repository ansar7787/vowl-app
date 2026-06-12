import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Number of ink blobs shown before the text is revealed.
const int _kBlobCount = 5;

/// Diameter of each ink blob in logical pixels (r-scaled).
const double _kBlobSize = 60.0;

/// Divisor used to normalise the raw pan-delta into a reveal increment.
/// Lower = more sensitive; higher = requires longer smear.
const double _kSmearSensitivity = 160.0;

class AudioFillBlanksCanvas extends StatelessWidget {
  final String text;
  final double revealProgress;
  final void Function(double delta) onSmear;
  final Color primaryColor;
  final bool isDark;

  const AudioFillBlanksCanvas({
    super.key,
    required this.text,
    required this.revealProgress,
    required this.onSmear,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ink canvas. Drag across the surface to reveal the transcription.',
      // Provide a tap-based alternative so users who cannot perform a pan
      // gesture can still access the content (e.g. switch-access users).
      onTap: () => onSmear(0.5),
      onTapHint: 'partially reveal transcription',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          // Normalise horizontal + vertical movement so diagonal smearing
          // feels natural and consistent with straight strokes.
          final delta =
              (details.delta.dx.abs() + details.delta.dy.abs()) /
              _kSmearSensitivity;
          onSmear(delta);
        },
        child: GlassTile(
          padding: EdgeInsets.all(32.r),
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Revealed text ─────────────────────────────────────────────
              // PERF FIX: animate alpha directly on the text colour instead of
              // wrapping in Opacity (avoids a compositing layer per frame).
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  color: (isDark ? Colors.white70 : Colors.black87).withValues(
                    alpha: revealProgress.clamp(0.0, 1.0),
                  ),
                ),
              ),

              // ── Ink blobs (shown while hidden) ────────────────────────────
              if (revealProgress < 1.0) ..._buildBlobs(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBlobs(BuildContext context) {
    final alpha = (0.8 - revealProgress).clamp(0.0, 1.0);
    final blobColor = isDark
        ? Colors.indigo[900]!.withValues(alpha: alpha)
        : Colors.black87.withValues(alpha: alpha);

    return List.generate(_kBlobCount, (i) {
      // RESPONSIVENESS FIX: use Alignment instead of fixed left-offsets.
      // Maps blob index to a fraction in [-1, 1] so blobs always fit inside
      // the canvas regardless of device width.
      //
      //  i = 0 → x = -0.8  (10 % from left)
      //  i = 1 → x = -0.4  (30 %)
      //  i = 2 → x =  0.0  (centre)
      //  i = 3 → x =  0.4  (70 %)
      //  i = 4 → x =  0.8  (90 %)
      final xAlignment = (2.0 * (i + 0.5) / _kBlobCount) - 1.0;

      return Align(
        alignment: Alignment(xAlignment, 0),
        child: ExcludeSemantics(
          // Each blob is decorative — the parent Semantics node already
          // describes the canvas interaction for screen readers.
          child: RepaintBoundary(
            child: _InkBlob(color: blobColor, index: i),
          ),
        ),
      );
    });
  }
}

// =============================================================================
// _InkBlob
//
// Single pulsing blob. Extracted so RepaintBoundary can be applied per-blob
// and the animation stagger is encapsulated here.
// =============================================================================

class _InkBlob extends StatelessWidget {
  final Color color;
  final int index;

  const _InkBlob({required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: _kBlobSize.r,
          height: _kBlobSize.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.2, 1.2),
          duration: 2.seconds,
          // Stagger each blob slightly so they don't all pulse in sync,
          // creating a more organic ink-drip feel.
          delay: Duration(milliseconds: index * 200),
          curve: Curves.easeInOut,
        );
  }
}
