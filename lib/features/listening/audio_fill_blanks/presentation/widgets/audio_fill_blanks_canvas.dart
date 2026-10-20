import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Number of ink blobs shown before the text is revealed.
const int _kBlobCount = 5;

/// Diameter of each ink blob in logical pixels (r-scaled).
const double _kBlobSize = 52.0;

/// Divisor used to normalise the raw pan-delta into a reveal increment.
/// Lower = more sensitive; higher = requires longer smear.
const double _kSmearSensitivity = 160.0;

class AudioFillBlanksCanvas extends StatelessWidget {
  final String text;
  final double revealProgress;
  final void Function(double delta) onSmear;
  final Color primaryColor;
  final bool isDark;
  final String? imageUrl;
  final bool? isCorrectState;

  const AudioFillBlanksCanvas({
    super.key,
    required this.text,
    required this.revealProgress,
    required this.onSmear,
    required this.primaryColor,
    required this.isDark,
    this.imageUrl,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sentence card. Drag across the surface or tap to reveal the sentence.',
      onTap: () => onSmear(0.5),
      onTapHint: 'reveal sentence',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSmear(0.5),
        onPanUpdate: (details) {
          // Normalise horizontal + vertical movement so diagonal smearing
          // feels natural and consistent with straight strokes.
          final delta =
              (details.delta.dx.abs() + details.delta.dy.abs()) /
              _kSmearSensitivity;
          onSmear(delta);
        },
        child: GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Image reveal (shown on correct) ───────────────────────────
              if (imageUrl != null)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: isCorrectState == true ? 0.4 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Image.network(imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),

              // Ensure the canvas is at least as tall as the blobs and wide enough
              SizedBox(height: _kBlobSize.r, width: double.infinity),

              // ── Revealed text ─────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  text,
                  key: ValueKey<String>(text),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    letterSpacing: 0.3,
                    color: (isDark ? Colors.white : AppColors.slate900)
                        .withValues(
                          alpha: math.max(0.0, math.min(1.0, revealProgress)),
                        ),
                  ),
                ),
              ),

              // ── Ink blobs (shown while hidden) ────────────────────
              if (revealProgress < 1.0)
                Positioned.fill(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: _buildBlobs(context),
                  ),
                ),
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
      final xAlignment = (2.0 * (i + 0.5) / _kBlobCount) - 1.0;
      return Align(
        alignment: Alignment(xAlignment, 0),
        child: ExcludeSemantics(
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
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    Widget blob = Container(
      width: _kBlobSize.r,
      height: _kBlobSize.r,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );

    if (!reduceMotion) {
      blob = blob
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

    return blob;
  }
}
