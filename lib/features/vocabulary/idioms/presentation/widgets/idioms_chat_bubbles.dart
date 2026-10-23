import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pill-shaped system notification bubble displayed in the simulated chat conversation.
class IdiomsSystemMessage extends StatelessWidget {
  /// The informational system message text.
  final String text;

  /// Theme accent color for text, border, and background tint.
  final Color color;

  /// Optional leading icon preceding the message.
  final IconData? icon;

  /// Creates an [IdiomsSystemMessage] badge.
  const IdiomsSystemMessage({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    final message = Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.r, color: color),
              SizedBox(width: 6.w),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: color,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) return message;
    return message.animate().fadeIn(duration: 250.ms).slideY(begin: 0.15);
  }
}

/// Incoming chat message from the conversation partner presenting visual emoji clues for the idiom.
class IdiomsStrangerMessage extends StatelessWidget {
  /// Emoji sequence depicting the idiom.
  final String emojis;

  /// Theme accent color for bubble borders and shadows.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Creates an [IdiomsStrangerMessage] bubble.
  const IdiomsStrangerMessage({
    super.key,
    required this.emojis,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    final container = Container(
      constraints: BoxConstraints(maxWidth: 0.75.sw),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(4.r),
        ),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          emojis,
          style: TextStyle(fontSize: 36.sp, height: 1.2),
        ),
      ),
    );

    if (reduceMotion) return container;
    return container
        .animate()
        .slideX(begin: -0.08, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }
}

/// Text message from the dialogue partner providing a semantic hint or definition.
class IdiomsStrangerTextMessage extends StatelessWidget {
  /// Clue text content delivered by the partner.
  final String text;

  /// Theme accent color for icons and borders.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Creates an [IdiomsStrangerTextMessage] bubble.
  const IdiomsStrangerTextMessage({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    final cleanedText = text.replaceFirst(RegExp(r'^DEFINITION:\s*', caseSensitive: false), '');

    final container = Container(
      constraints: BoxConstraints(maxWidth: 0.75.sw),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
          bottomLeft: Radius.circular(4.r),
        ),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.lightbulb_rounded,
              size: 15.r,
              color: color,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              cleanedText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) return container;
    return container
        .animate(delay: 200.ms)
        .slideX(begin: -0.08, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }
}

/// Outgoing chat message bubble reflecting the user's selected idiom answer.
class IdiomsUserMessage extends StatelessWidget {
  /// The user's submitted idiom response.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Whether the user's answer was validated as correct, or `null` if pending.
  final bool? isCorrect;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Creates an [IdiomsUserMessage] bubble.
  const IdiomsUserMessage({
    super.key,
    required this.text,
    required this.color,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bgColor = isCorrect == true
        ? tokens.gameCorrect
        : (isCorrect == false ? tokens.gameIncorrect : color);

    final statusIcon = isCorrect != null
        ? Icon(
            isCorrect! ? Icons.verified_rounded : Icons.gpp_bad_rounded,
            color: isCorrect! ? tokens.gameCorrect : tokens.gameIncorrect,
            size: 18.r,
          )
        : null;

    final container = Container(
      constraints: BoxConstraints(maxWidth: 0.75.sw),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? bgColor.withValues(alpha: 0.15)
            : bgColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(4.r),
        ),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (statusIcon != null) ...[
            SizedBox(width: 8.w),
            reduceMotion
                ? statusIcon
                : statusIcon
                    .animate()
                    .scale(duration: 350.ms, curve: Curves.elasticOut),
          ],
        ],
      ),
    );

    if (reduceMotion) return container;
    return container
        .animate()
        .slideX(begin: 0.08, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }
}
