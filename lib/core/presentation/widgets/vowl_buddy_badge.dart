import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';

/// Reusable circular badge displaying the user's active companion buddy
/// and equipped accessory inside an elegant translucent circle.
///
/// Designed to DRY up buddy pin rendering across the app (e.g. [HomeHeroHeader],
/// [DailyMotivationCard], etc.), ensuring identical sizing, visual styling,
/// and slot-aware accessory placement.
class VowlBuddyBadge extends StatelessWidget {
  /// Diameter of the circular badge container. Defaults to `24.r`.
  final double? size;

  /// Size of the mascot inside the circular container. Defaults to `18.r`.
  final double? mascotSize;

  /// Explicit mascot key. If omitted, falls back to `AuthBloc.user.vowlMascot`.
  final String? mascotId;

  /// Explicit accessory key. If omitted, falls back to `AuthBloc.user.vowlEquippedAccessory`.
  final String? accessoryId;

  /// Optional tap callback. When provided, wraps the badge in a [ScaleButton].
  final VoidCallback? onTap;

  /// Whether to play a gentle breathing scale animation. Defaults to false.
  final bool animate;

  /// Optional custom background color for the circular badge.
  final Color? backgroundColor;

  /// Optional custom gradient for the circular badge.
  final Gradient? gradient;

  /// Optional border surrounding the badge (e.g. when docked atop an avatar).
  final BoxBorder? border;

  /// Optional shadow for elevation separation.
  final List<BoxShadow>? boxShadow;

  /// Whether running in Kids Mode. Defaults to false.
  final bool isKidsMode;

  /// Creates a [VowlBuddyBadge].
  const VowlBuddyBadge({
    super.key,
    this.size,
    this.mascotSize,
    this.mascotId,
    this.accessoryId,
    this.onTap,
    this.animate = false,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.boxShadow,
    this.isKidsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final badgeDiameter = size ?? 24.r;
    final innerMascotSize = mascotSize ?? 18.r;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    // Premium Enamel / Glass Gradient (eliminates muddy dark-mode hole & washed-out light mode)
    final Gradient defaultGradient = isMidnight
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          )
        : (isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.95),
                  const Color(0xFF0F172A).withValues(alpha: 0.95),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8FAFC)],
              ));

    // Refined hairline border that catches light instead of pitch-black harshness
    final BoxBorder defaultBorder = Border.all(
      color: isMidnight
          ? Colors.white.withValues(alpha: 0.24)
          : (isDark
              ? Colors.white.withValues(alpha: 0.22)
              : AppColors.indigo500.withValues(alpha: 0.22)),
      width: 1.2.r,
    );

    // Luminous brand elevation shadow
    final List<BoxShadow> defaultShadow = [
      BoxShadow(
        color: isDark
            ? AppColors.indigo500.withValues(alpha: 0.28)
            : AppColors.indigo500.withValues(alpha: 0.14),
        blurRadius: 6,
        offset: const Offset(0, 1.5),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];

    final badgeDecoration = BoxDecoration(
      shape: BoxShape.circle,
      color: (gradient != null || backgroundColor != null) ? backgroundColor : null,
      gradient: backgroundColor != null ? null : (gradient ?? defaultGradient),
      border: border ?? defaultBorder,
      boxShadow: boxShadow ?? defaultShadow,
    );

    // Safely check if AuthBloc is present in context to build full VowlMascot
    final hasAuthBloc =
        context.findAncestorWidgetOfExactType<BlocProvider<AuthBloc>>() !=
            null ||
        context.findAncestorWidgetOfExactType<MultiBlocProvider>() != null;

    Widget mascotContent;
    if (hasAuthBloc) {
      mascotContent = VowlMascot(
        size: innerMascotSize,
        mascotId: mascotId,
        accessoryId: accessoryId,
        isKidsMode: isKidsMode,
        state: VowlMascotState.happy,
        useFloatingAnimation: false,
      );
    } else {
      // Standalone/fallback rendering for isolated widget tests without AuthBloc
      final effectiveMascotId =
          mascotId ?? (isKidsMode ? 'owly' : 'vowl_prime');
      final isVowly = effectiveMascotId == 'vowly';
      final emoji = isKidsMode
          ? (KidsAssets.mascotMap[effectiveMascotId] ?? '🦉')
          : VowlAssets.getMascotEmoji(effectiveMascotId);
      final effectiveAccessory = accessoryId;

      Widget baseWidget = isVowly
          ? Image.asset(
              VowlAssets.vowlyHappy,
              width: innerMascotSize,
              height: innerMascotSize,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Text(
                '🦉',
                style: TextStyle(
                  fontSize: innerMascotSize * 0.6,
                  height: 1.0,
                ),
              ),
            )
          : Text(
              emoji,
              style: TextStyle(
                fontSize: innerMascotSize * 0.6,
                height: 1.0,
              ),
            );

      if (effectiveAccessory != null && effectiveAccessory.isNotEmpty) {
        final accessoryEmoji = isKidsMode
            ? (KidsAssets.accessoryMap[effectiveAccessory] ?? '✨')
            : VowlAssets.getAccessoryEmoji(effectiveAccessory);
        final slot = isKidsMode
            ? AccessorySlot.charm
            : VowlAssets.getAccessorySlot(effectiveAccessory);

        Widget overlay;
        switch (slot) {
          case AccessorySlot.head:
            overlay = Positioned(
              top: -innerMascotSize * 0.16,
              child: Text(
                accessoryEmoji,
                style: TextStyle(
                  fontSize: innerMascotSize * 0.42,
                  height: 1.0,
                ),
              ),
            );
            break;
          case AccessorySlot.neck:
            overlay = Positioned(
              bottom: -innerMascotSize * 0.08,
              child: Text(
                accessoryEmoji,
                style: TextStyle(
                  fontSize: innerMascotSize * 0.38,
                  height: 1.0,
                ),
              ),
            );
            break;
          case AccessorySlot.aura:
            overlay = Positioned(
              top: -innerMascotSize * 0.08,
              right: -innerMascotSize * 0.04,
              child: Text(
                accessoryEmoji,
                style: TextStyle(
                  fontSize: innerMascotSize * 0.3,
                  height: 1.0,
                ),
              ),
            );
            break;
          case AccessorySlot.charm:
            overlay = Positioned(
              bottom: innerMascotSize * 0.02,
              right: -innerMascotSize * 0.04,
              child: Text(
                accessoryEmoji,
                style: TextStyle(
                  fontSize: innerMascotSize * 0.34,
                  height: 1.0,
                ),
              ),
            );
            break;
        }

        mascotContent = Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [baseWidget, overlay],
        );
      } else {
        mascotContent = baseWidget;
      }
    }

    Widget badge = Container(
      width: badgeDiameter,
      height: badgeDiameter,
      decoration: badgeDecoration,
      child: Center(child: mascotContent),
    );

    if (animate && !reduceMotion) {
      badge = badge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.08, 1.08),
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    if (onTap != null) {
      return ScaleButton(
        onTap: onTap!,
        child: badge,
      );
    }

    return badge;
  }
}

