import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// The draggable word chip at the centre of the POS screen.
///
/// Constrained to [maxWidth] so very long words do not overflow the Stack.
/// Text is ellipsised as a last resort but target words should always be
/// short enough to fit at these sizes.
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
    // Cap width so unusually long words don't overflow the vortex Stack.
    final maxWidth = isCompact ? 180.w : 240.w;

    return Semantics(
      label: 'Drag "$word" into the correct vortex, or tap it to select',
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GlassTile(
            padding: isCompact
                ? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h)
                : EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
            borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 20.sp : 28.sp,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
