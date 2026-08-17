import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum KidsAssetAnimation { none, hover, pulse, shake, bounce, scale }

class AnimatedKidsAsset extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final double size;
  final Color? color;
  final KidsAssetAnimation animation;
  final Duration? delay;

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
      child = Text(emoji!, style: TextStyle(fontSize: size));
    } else {
      child = Icon(icon!, size: size, color: color);
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
          curve: Curves.easeOutBack,
        );
        break;
      case KidsAssetAnimation.none:
        return child;
    }

    return animated;
  }
}
