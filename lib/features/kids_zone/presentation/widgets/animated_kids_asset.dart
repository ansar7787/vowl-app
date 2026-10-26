import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Defines the animation motion pattern applied to an [AnimatedKidsAsset].
enum KidsAssetAnimation {
  /// No continuous animation applied.
  none,

  /// Gentle vertical hovering motion.
  hover,

  /// Subtle pulsating scale animation.
  pulse,

  /// Horizontal shaking animation.
  shake,

  /// Vertical bouncing animation.
  bounce,

  /// Scaling loop animation.
  scale,
}

/// Animated graphic asset presenting either an emoji or an icon with cheerful physics.
class AnimatedKidsAsset extends StatelessWidget {
  /// Optional emoji string to display.
  final String? emoji;

  /// Optional icon data to display.
  final IconData? icon;

  /// Visual size in logical pixels.
  final double size;

  /// Optional color tint applied to the icon.
  final Color? color;

  /// The animation pattern to execute.
  final KidsAssetAnimation animation;

  /// Optional initial delay before animation commences.
  final Duration? delay;

  /// Creates an [AnimatedKidsAsset] widget.
  const AnimatedKidsAsset({
    super.key,
    this.emoji,
    this.icon,
    required this.size,
    this.color,
    this.animation = KidsAssetAnimation.hover,
    this.delay,
  }) : assert(
         emoji != null || icon != null,
         'Must provide either an emoji or an icon',
       );

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (emoji != null) {
      child = Text(
        emoji!,
        style: TextStyle(
          fontSize: size,
          fontFamilyFallback: const [
            'Noto Color Emoji',
            'Apple Color Emoji',
            'Segoe UI Emoji',
          ],
        ),
      );
    } else {
      child = Icon(icon!, size: size, color: color);
    }

    if (animation == KidsAssetAnimation.none ||
        VowlMotion.shouldReduceMotion(context)) {
      return child;
    }

    var animated = child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      delay: delay ?? 0.ms,
    );

    switch (animation) {
      case KidsAssetAnimation.hover:
        animated = animated.moveY(
          begin: -5.h,
          end: 5.h,
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
        break;
      case KidsAssetAnimation.pulse:
        animated = animated.scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
        );
        break;
      case KidsAssetAnimation.shake:
        animated = animated.shake(
          hz: 4,
          offset: const Offset(2, 0),
          duration: 1.seconds,
        );
        break;
      case KidsAssetAnimation.bounce:
        animated = animated.moveY(
          begin: 0,
          end: -10.h,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
        break;
      case KidsAssetAnimation.scale:
        animated = animated.scale(
          begin: Offset.zero,
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
        break;
      case KidsAssetAnimation.none:
        break;
    }

    return animated;
  }
}
