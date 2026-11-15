import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Standardized, non-intrusive peeking companion widget shared across all game categories.
///
/// Features a compact **Horizontal Companion Row** layout:
/// - Left: Compact speech bubble with rounded glass/card surface and category-accented typography.
/// - Right: Animated companion avatar (38dp standard), anchored on the right edge.
///
/// Production Ergonomics:
/// - The speech bubble auto-fades and collapses after 3 seconds so it never permanently
///   blocks or covers question instructions, prompts, or clues.
/// - Tapping the mascot toggles/re-activates the speech bubble with crisp haptic feedback.
/// - Generous 46x46dp thumb touch target ensures effortless tapping on all mobile devices.
/// - Whenever the message or emotional state changes, the speech bubble reactivates.
/// - When collapsed, the companion consumes only the avatar margin, freeing 100%
///   of the horizontal width for question reading.
class VowlPeekingCompanion extends StatefulWidget {
  /// Spoken message from the companion (without duplicate mascot emojis).
  final String message;

  /// Current emotional visual state (happy, thinking, worried, neutral).
  final VowlMascotState mascotState;

  /// The active user mascot identifier (e.g. `'vowl_prime'`).
  final String mascotId;

  /// Game category identifier for theme and color matching.
  final String category;

  /// Mascot visual size in logical pixels (default 38r).
  final double mascotSize;

  /// Optional override for the speech bubble text color.
  final Color? textColorOverride;

  /// Auto-dismiss duration for the speech bubble so it never permanently blocks question text.
  /// Defaults to 3 seconds. Set to null to keep speech bubble visible indefinitely.
  final Duration? autoDismissDuration;

  const VowlPeekingCompanion({
    super.key,
    required this.message,
    required this.mascotState,
    required this.mascotId,
    required this.category,
    this.mascotSize = 38.0,
    this.textColorOverride,
    this.autoDismissDuration = const Duration(seconds: 3),
  });

  @override
  State<VowlPeekingCompanion> createState() => _VowlPeekingCompanionState();
}

class _VowlPeekingCompanionState extends State<VowlPeekingCompanion>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  bool _isBubbleVisible = true;

  @override
  void initState() {
    super.initState();
    _startDismissTimer();
  }

  @override
  void didUpdateWidget(covariant VowlPeekingCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.mascotState != widget.mascotState) {
      _showBubbleTemporarily();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startDismissTimer() {
    if (widget.autoDismissDuration == null) return;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.autoDismissDuration!, () {
      if (mounted) {
        setState(() {
          _isBubbleVisible = false;
        });
      }
    });
  }

  void _showBubbleTemporarily() {
    setState(() {
      _isBubbleVisible = true;
    });
    _startDismissTimer();
  }

  void _onTapMascot() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    setState(() {
      _isBubbleVisible = !_isBubbleVisible;
    });

    if (_isBubbleVisible) {
      _startDismissTimer();
    } else {
      _dismissTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = CategoryColors.forCategory(widget.category);
    final resolvedTextColor = widget.textColorOverride ??
        (isDark
            ? (Color.lerp(catColor, Colors.white, 0.35) ?? Colors.white)
            : catColor);

    Widget bubble = AnimatedOpacity(
      opacity: _isBubbleVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        child: _isBubbleVisible
            ? GestureDetector(
                onTap: _onTapMascot,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 145.w),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  margin: EdgeInsets.only(right: 4.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.slate200,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.06,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: resolvedTextColor,
                      height: 1.25,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );

    Widget mascot = VowlMascot(
      state: widget.mascotState,
      size: widget.mascotSize.r,
      mascotId: widget.mascotId,
    );

    if (!reduceMotion) {
      mascot = mascot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 4, duration: 1500.ms, curve: Curves.easeInOut);
    }

    // Touch target for mascot avatar with generous 46x46dp hit area
    Widget mascotButton = GestureDetector(
      onTap: _onTapMascot,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 44.r,
          minHeight: 44.r,
        ),
        alignment: Alignment.center,
        child: mascot,
      ),
    );

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        bubble,
        mascotButton,
      ],
    );

    if (!reduceMotion) {
      row = row.animate().fadeIn(duration: 250.ms).slideX(begin: 0.08, end: 0);
    }

    return RepaintBoundary(
      child: Semantics(
        liveRegion: true,
        label: widget.message,
        excludeSemantics: true,
        child: row,
      ),
    );
  }
}
