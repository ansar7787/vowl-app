import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';

enum VowlMascotState {
  neutral,
  happy,
  worried,
  thinking,
  studying,
  sleeping,
}

class VowlMascot extends StatelessWidget {
  final VowlMascotState state;
  final double? size;
  final bool useFloatingAnimation;
  final String? accessoryId;
  final String? mascotId;
  final int level;
  final bool isKidsMode;

  const VowlMascot({
    super.key,
    this.state = VowlMascotState.neutral,
    this.size,
    this.useFloatingAnimation = true,
    this.accessoryId,
    this.mascotId,
    this.level = 1,
    this.isKidsMode = false,
  });

  bool get _isVoxBot => mascotId == null || mascotId == 'vox_bot';

  String _getAssetPath() {
    if (!_isVoxBot) return ""; // We use Emoji for other mascots
    switch (state) {
      case VowlMascotState.happy:
        return 'assets/images/mascot/voxbot_happy.webp';
      case VowlMascotState.worried:
        return 'assets/images/mascot/voxbot_worried.webp';
      case VowlMascotState.thinking:
        return 'assets/images/mascot/voxbot_thinking.webp';
      case VowlMascotState.studying:
        return 'assets/images/mascot/voxbot_thinking.webp';
      case VowlMascotState.sleeping:
        return 'assets/images/mascot/voxbot_neutral.webp';
      case VowlMascotState.neutral:
        return 'assets/images/mascot/voxbot_neutral.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final String effectiveMascotId = mascotId ?? 
            (isKidsMode ? (user?.kidsMascot ?? 'owly') : (user?.vowlMascot ?? 'vowl_prime'));
        
        final isVoxBot = effectiveMascotId == 'vox_bot';

        final botSize = size ?? 120.r;
        
        // DYNAMIC MAP SELECTION
        final mascotMap = isKidsMode ? KidsAssets.mascotMap : VowlAssets.mascotMap;
        final accessoryMap = isKidsMode ? KidsAssets.accessoryMap : VowlAssets.accessoryMap;
        final colorMap = VowlAssets.itemColors; // We use VowlAssets for global item colors

        final buddyEmoji = mascotMap[effectiveMascotId] ?? (isKidsMode ? "🦉" : "🦉");
        
        // TAILORED AURA COLORS
        Color auraColor = colorMap[effectiveMascotId] ?? Colors.blueAccent;
        if (isKidsMode) {
          if (effectiveMascotId == 'owly') auraColor = Colors.brown[300]!;
          if (effectiveMascotId == 'foxie') auraColor = Colors.orangeAccent;
          if (effectiveMascotId == 'dino') auraColor = Colors.greenAccent;
          if (effectiveMascotId == 'mascot_unicorn') auraColor = const Color(0xFFF472B6);
          if (effectiveMascotId == 'mascot_robot') auraColor = const Color(0xFF60A5FA);
          if (effectiveMascotId == 'mascot_lion') auraColor = const Color(0xFFFBBF24);
        }

        Widget bot;
        if (isVoxBot && effectiveMascotId != 'vowl_prime') {
          bot = Image.asset(
            _getAssetPath(),
            width: botSize,
            height: botSize,
            fit: BoxFit.contain,
            color: state == VowlMascotState.sleeping
                ? Colors.black.withValues(alpha: 0.3)
                : null,
            colorBlendMode:
                state == VowlMascotState.sleeping ? BlendMode.dstIn : null,
          );
        } else {
          bot = Container(
            width: botSize,
            height: botSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  auraColor.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Text(
                buddyEmoji,
                style: TextStyle(
                  fontSize: botSize * 0.6,
                  shadows: [
                    Shadow(
                      color: auraColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Apply Level-based Auras (Growth)
        if (level >= 50) {
          bot = Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: botSize * 0.9,
                height: botSize * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (level >= 100 ? Colors.amberAccent : Colors.blueAccent).withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
              bot,
            ],
          );
        }

        // Overlay Accessory if present
        final effectiveAccessory = accessoryId ?? (isKidsMode ? authState.user?.kidsEquippedAccessory : authState.user?.vowlEquippedAccessory);
        if (effectiveAccessory != null && accessoryMap.containsKey(effectiveAccessory)) {
          final emoji = accessoryMap[effectiveAccessory]!;
          bot = Stack(
            alignment: Alignment.center,
            children: [
              bot,
              Positioned(
                top: botSize * 0.1,
                right: botSize * 0.1,
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: botSize * 0.35),
                ),
              ),
              if (level >= 100)
                Positioned(
                  top: -botSize * 0.1,
                  child: Text(
                    '👑',
                    style: TextStyle(fontSize: botSize * 0.3),
                  ),
                ),
            ],
          );
        } else if (level >= 100) {
          bot = Stack(
            alignment: Alignment.center,
            children: [
              bot,
              Positioned(
                top: -botSize * 0.1,
                child: Text(
                  '👑',
                  style: TextStyle(fontSize: botSize * 0.3),
                ),
              ),
            ],
          );
        }

        if (!useFloatingAnimation) return bot;

        var animatedBot = bot
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(
              begin: state == VowlMascotState.sleeping ? -2 : -5,
              end: state == VowlMascotState.sleeping ? 2 : 5,
              duration: state == VowlMascotState.sleeping ? 4000.ms : 2000.ms,
              curve: Curves.easeInOutQuad,
            );

        if (state == VowlMascotState.happy) {
          animatedBot = animatedBot
              .shake(hz: 4, curve: Curves.easeInOutCubic)
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 400.ms)
              .then()
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 400.ms);
        }

        if (state == VowlMascotState.worried) {
          animatedBot = animatedBot
              .shake(hz: 8, curve: Curves.easeInOut)
              .tint(color: Colors.blue.withValues(alpha: 0.2));
        }

        if (state == VowlMascotState.sleeping) {
          animatedBot = animatedBot.blur(begin: const Offset(0, 0), end: const Offset(1, 1));
        }

        if (state == VowlMascotState.thinking) {
          animatedBot = animatedBot.rotate(begin: -0.1, end: 0.1, duration: 2.seconds, curve: Curves.easeInOut);
        }

        // Add state-specific emoji overlays for more expression
        String? stateEmoji;
        if (state == VowlMascotState.thinking) stateEmoji = '💡';
        if (state == VowlMascotState.studying) stateEmoji = '📚';
        if (state == VowlMascotState.worried) stateEmoji = '😰';

        if (stateEmoji != null) {
          return Stack(
            alignment: Alignment.center,
            children: [
              animatedBot,
              Positioned(
                bottom: botSize * 0.1,
                right: 0,
                child: Text(stateEmoji, style: TextStyle(fontSize: botSize * 0.2)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -10),
            ],
          );
        }

        return RepaintBoundary(child: animatedBot);
      },
    );
  }
}
