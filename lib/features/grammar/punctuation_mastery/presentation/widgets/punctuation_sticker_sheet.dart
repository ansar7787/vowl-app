import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Draggable sticker collection providing punctuation marks for sentence placement.
class PunctuationStickerSheet extends StatelessWidget {
  /// The collection of punctuation marks available to drag.
  final List<String> marks;

  /// The primary accent color for stickers and borders.
  final Color primaryColor;

  /// Creates a [PunctuationStickerSheet] widget.
  const PunctuationStickerSheet({
    super.key,
    required this.marks,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w,
      runSpacing: 14.h,
      children: marks.map((m) => _buildSticker(context, m)).toList(),
    );
  }

  Widget _buildSticker(BuildContext context, String mark) {
    return Draggable<String>(
      key: ValueKey('sticker_mark_$mark'),
      data: mark,
      feedback: _buildTactileSticker(context, mark, isDragging: true),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _buildTactileSticker(context, mark),
      ),
      child: _buildTactileSticker(context, mark),
    );
  }

  Widget _buildTactileSticker(
    BuildContext context,
    String mark, {
    bool isDragging = false,
  }) {
    final shouldAnimate = !VowlMotion.shouldReduceMotion(context);

    Widget sticker = Material(
      color: Colors.transparent,
      child: Container(
        width: 48.r,
        height: 48.r,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryColor.withValues(alpha: 0.1)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: isDragging ? 16 : 6,
              offset: isDragging ? const Offset(0, 8) : const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            mark,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );

    if (shouldAnimate) {
      sticker = sticker
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(begin: -0.05, end: 0.05, duration: 2.seconds);
    }

    return RepaintBoundary(child: sticker);
  }
}
