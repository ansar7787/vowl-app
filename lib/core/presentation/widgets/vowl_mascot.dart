import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';

enum VowlMascotState { neutral, happy, worried, thinking, studying, sleeping }

// ---------------------------------------------------------------------------
// Selector data class — targeted BlocSelector payload, rebuilt only when
// mascot-relevant user fields change (level, mascot, accessory).
// ---------------------------------------------------------------------------

@immutable
class _MascotUserData extends Equatable {
  final int level;
  final String? vowlMascot;
  final String? kidsMascot;
  final String? vowlAccessory;
  final String? kidsAccessory;

  const _MascotUserData({
    required this.level,
    this.vowlMascot,
    this.kidsMascot,
    this.vowlAccessory,
    this.kidsAccessory,
  });

  @override
  List<Object?> get props => [
    level,
    vowlMascot,
    kidsMascot,
    vowlAccessory,
    kidsAccessory,
  ];
}

/// Interactive companion avatar showing Owly / emoji mascot with progressive
/// aura states, equipped visual accessories, and state expressions.
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

  /// Returns the VoxBot image asset path for the current [state].
  /// Returns an empty string if [mascotId] is not explicitly 'vox_bot'.
  String _getAssetPath() {
    if (mascotId != 'vox_bot') return '';
    return switch (state) {
      VowlMascotState.happy => 'assets/images/mascot/voxbot_happy.webp',
      VowlMascotState.worried => 'assets/images/mascot/voxbot_worried.webp',
      VowlMascotState.thinking ||
      VowlMascotState.studying => 'assets/images/mascot/voxbot_thinking.webp',
      _ => 'assets/images/mascot/voxbot_neutral.webp',
    };
  }

  @override
  Widget build(BuildContext context) {
    // HIGH FIX: BlocSelector rebuilds ONLY when mascot-relevant user data
    // changes. Previously BlocBuilder rebuilt on every AuthState change.
    return BlocSelector<AuthBloc, AuthState, _MascotUserData>(
      selector: (s) => _MascotUserData(
        level: s.user?.level ?? 1,
        vowlMascot: s.user?.vowlMascot,
        kidsMascot: s.user?.kidsMascot,
        vowlAccessory: s.user?.vowlEquippedAccessory,
        kidsAccessory: s.user?.kidsEquippedAccessory,
      ),
      builder: (context, userData) {
        final effectiveMascotId =
            mascotId ??
            (isKidsMode
                ? (userData.kidsMascot ?? 'owly')
                : (userData.vowlMascot ?? 'vowl_prime'));

        final isVoxBot = effectiveMascotId == 'vox_bot';
        final botSize = size ?? 120.r;

        final mascotMap = isKidsMode
            ? KidsAssets.mascotMap
            : VowlAssets.mascotMap;
        final accessoryMap = isKidsMode
            ? KidsAssets.accessoryMap
            : VowlAssets.accessoryMap;

        final buddyEmoji = mascotMap[effectiveMascotId] ?? '🦉';

        // ── Aura colour ───────────────────────────────────────────────────
        Color auraColor =
            VowlAssets.itemColors[effectiveMascotId] ?? Colors.blueAccent;
        if (isKidsMode) {
          auraColor = switch (effectiveMascotId) {
            'owly' => Colors.brown[300]!,
            'foxie' => Colors.orangeAccent,
            'dino' => Colors.greenAccent,
            'mascot_unicorn' => const Color(0xFFF472B6),
            'mascot_robot' => const Color(0xFF60A5FA),
            'mascot_lion' => const Color(0xFFFBBF24),
            _ => auraColor,
          };
        }

        // ── Base bot widget ───────────────────────────────────────────────
        Widget bot = isVoxBot
            ? Image.asset(
                _getAssetPath(),
                width: botSize,
                height: botSize,
                fit: BoxFit.contain,
                color: state == VowlMascotState.sleeping
                    ? Colors.black.withValues(alpha: 0.3)
                    : null,
                colorBlendMode: state == VowlMascotState.sleeping
                    ? BlendMode.dstIn
                    : null,
                // FIX (CRASH SAFETY): a missing or corrupt VoxBot asset
                // would previously propagate up to the app's
                // GlobalErrorBoundary, replacing the ENTIRE screen with a
                // full "system anomaly" error page over what's ultimately
                // a cosmetic avatar image. Falling back to the same
                // emoji rendering used for every other mascot keeps a
                // failure contained to just this small widget.
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    buddyEmoji,
                    style: TextStyle(fontSize: botSize * 0.6),
                  ),
                ),
              )
            : Container(
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

        // ── Level-based aura (≥50) ────────────────────────────────────────
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
                          color:
                              (level >= 100
                                      ? Colors.amberAccent
                                      : Colors.blueAccent)
                                  .withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 2.seconds,
                  ),
              bot,
            ],
          );
        }

        // ── Accessory overlay ─────────────────────────────────────────────
        final effectiveAccessory =
            accessoryId ??
            (isKidsMode ? userData.kidsAccessory : userData.vowlAccessory);

        if (effectiveAccessory != null &&
            accessoryMap.containsKey(effectiveAccessory)) {
          final emoji = accessoryMap[effectiveAccessory]!;
          bot = Stack(
            alignment: Alignment.center,
            // FIX (VISUAL CORRECTNESS): Stack's default clipBehavior is
            // Clip.hardEdge, which clips any Positioned child that extends
            // outside the Stack's own bounds. The crown badge below is
            // deliberately positioned above the Stack (top: -botSize*0.1,
            // i.e. y < 0) to hover above the avatar - with the default
            // clip, that portion would be cut off. Clip.none lets it
            // render fully, with no effect on any other child here (none
            // of the others extend past the Stack's bounds).
            clipBehavior: Clip.none,
            children: [
              bot,
              Positioned(
                top: botSize * 0.1,
                right: botSize * 0.1,
                child: Text(emoji, style: TextStyle(fontSize: botSize * 0.35)),
              ),
              if (level >= 100)
                Positioned(
                  top: -botSize * 0.1,
                  child: Text('👑', style: TextStyle(fontSize: botSize * 0.3)),
                ),
            ],
          );
        } else if (level >= 100) {
          bot = Stack(
            alignment: Alignment.center,
            // FIX (VISUAL CORRECTNESS): same reason as above.
            clipBehavior: Clip.none,
            children: [
              bot,
              Positioned(
                top: -botSize * 0.1,
                child: Text('👑', style: TextStyle(fontSize: botSize * 0.3)),
              ),
            ],
          );
        }

        // ── Static (no floating) ──────────────────────────────────────────
        if (!useFloatingAnimation) {
          return RepaintBoundary(child: bot);
        }

        // ── Floating + state animations ───────────────────────────────────
        var animatedBot = bot
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: state == VowlMascotState.sleeping ? -2 : -5,
              end: state == VowlMascotState.sleeping ? 2 : 5,
              duration: state == VowlMascotState.sleeping ? 4000.ms : 2000.ms,
              curve: Curves.easeInOutQuad,
            );

        if (state == VowlMascotState.happy) {
          animatedBot = animatedBot
              .shake(hz: 4, curve: Curves.easeInOutCubic)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 400.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
                duration: 400.ms,
              );
        }

        if (state == VowlMascotState.worried) {
          animatedBot = animatedBot
              .shake(hz: 8, curve: Curves.easeInOut)
              .tint(color: Colors.blue.withValues(alpha: 0.2));
        }

        if (state == VowlMascotState.sleeping) {
          animatedBot = animatedBot.blur(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
          );
        }

        if (state == VowlMascotState.thinking) {
          animatedBot = animatedBot.rotate(
            begin: -0.1,
            end: 0.1,
            duration: 2.seconds,
            curve: Curves.easeInOut,
          );
        }

        // ── State emoji overlays ──────────────────────────────────────────
        final stateEmoji = switch (state) {
          VowlMascotState.thinking => '💡',
          VowlMascotState.studying => '📚',
          VowlMascotState.worried => '😰',
          _ => null,
        };

        if (stateEmoji != null) {
          return RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              children: [
                animatedBot,
                Positioned(
                      bottom: botSize * 0.1,
                      right: 0,
                      child: Text(
                        stateEmoji,
                        style: TextStyle(fontSize: botSize * 0.2),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -10),
              ],
            ),
          );
        }

        return RepaintBoundary(child: animatedBot);
      },
    );
  }
}
