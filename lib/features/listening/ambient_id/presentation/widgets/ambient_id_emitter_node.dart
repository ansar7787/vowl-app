import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Interactive audio emitter button node for ambient sound replay.
///
/// Triggers text-to-speech or ambient audio sample playback when tapped by the user.
class AmbientIdEmitterNode extends StatelessWidget {
  /// Callback triggered when the emitter node is tapped.
  final VoidCallback onTap;

  /// Primary theme accent color.
  final Color color;

  /// Accessible label and caption text displayed below the node.
  final String? label;

  /// Creates an [AmbientIdEmitterNode] instance.
  const AmbientIdEmitterNode({
    super.key,
    required this.onTap,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: label ?? 'Play sound',
      button: true,
      child: ScaleButton(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 28.r,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              label ?? 'Tap to listen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
