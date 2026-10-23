import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// The draggable word chip at the centre of the POS screen.
///
/// Constrained to [maxWidth] so words fit comfortably without overflowing.
/// Scaled dynamically via [FittedBox] so text never clips or shows ellipses.
class SpeechDraggableWord extends StatelessWidget {
  final String word;
  final Color primaryColor;
  final bool isDark;
  final bool isCompact;
  final bool isSelected;

  const SpeechDraggableWord({
    super.key,
    required this.word,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = isCompact ? 170.w : 220.w;

    return Semantics(
      key: const ValueKey('speech_draggable_word'),
      label: 'Drag or tap "$word" to match its part of speech',
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isCompact ? 14.r : 18.r),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isSelected ? 16.r : 10.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GlassTile(
              padding: isCompact
                  ? EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h)
                  : EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              borderRadius: BorderRadius.circular(isCompact ? 14.r : 18.r),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 17.sp : 20.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
