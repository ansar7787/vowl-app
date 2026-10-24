import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/track_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

/// Interactive tilt arena with physics-based sliding ball snapping toward Yes or No poles.
class YesNoSpeakingTiltArena extends StatelessWidget {
  /// Normalized tilt position value (-1.0 to 1.0).
  final double tiltValue;

  /// Whether the sphere has locked into a pole gate.
  final bool isSnapped;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Callback executed during interactive dragging of the tilt ball.
  final Function(DragUpdateDetails, double) onTiltDragged;

  /// Callback executed when the drag gesture ends.
  final VoidCallback onTiltDragEnd;

  /// Optional callback invoked when a specific gate (true for Yes, false for No) is selected directly.
  final ValueChanged<bool>? onGateSelected;

  /// Creates a [YesNoSpeakingTiltArena].
  const YesNoSpeakingTiltArena({
    super.key,
    required this.tiltValue,
    required this.isSnapped,
    required this.primaryColor,
    required this.isDark,
    required this.onTiltDragged,
    required this.onTiltDragEnd,
    this.onGateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final double trackWidth = 280.w;

    return Container(
      width: double.infinity,
      height: 140.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color07070f
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.slate200,
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Neon track custom painter
          Positioned.fill(
            child: CustomPaint(
              painter: TrackPainter(
                tiltValue: tiltValue,
                themeColor: primaryColor,
              ),
            ),
          ),

          // 2. Boundary gate zones
          Positioned(
            left: 20.w,
            child: _buildGateZone(
              "NO",
              tokens.gameIncorrect,
              tiltValue <= -0.85,
              onGateSelected != null ? () => onGateSelected!(false) : null,
            ),
          ),
          Positioned(
            right: 20.w,
            child: _buildGateZone(
              "YES",
              tokens.gameCorrect,
              tiltValue >= 0.85,
              onGateSelected != null ? () => onGateSelected!(true) : null,
            ),
          ),

          // 3. Central dragging glowing sphere
          Positioned(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  onTiltDragged(details, trackWidth),
              onHorizontalDragEnd: (_) => onTiltDragEnd(),
              child: Transform.translate(
                offset: Offset(tiltValue * (trackWidth / 2 - 40.w), 0),
                child: Semantics(
                  label: isSnapped
                      ? 'Selection locked'
                      : 'Slide sphere to Yes or No',
                  child: Container(
                    key: const Key('yes_no_speaking_sphere'),
                    width: 62.r,
                    height: 62.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          tiltValue < 0
                              ? tokens.gameIncorrect
                              : (tiltValue > 0
                                    ? tokens.gameCorrect
                                    : primaryColor),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (tiltValue < 0
                                      ? tokens.gameIncorrect
                                      : (tiltValue > 0
                                            ? tokens.gameCorrect
                                            : primaryColor))
                                  .withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSnapped ? Icons.lock_rounded : Icons.blur_on_rounded,
                      color: Colors.white,
                      size: 26.r,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateZone(
    String label,
    Color color,
    bool isActive,
    VoidCallback? onTap,
  ) {
    return ScaleButton(
      key: Key('yes_no_speaking_gate_${label.toLowerCase()}'),
      onTap: onTap ?? () {},
      child: Semantics(
        button: true,
        label: '$label gate',
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isActive ? Colors.white24 : color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
