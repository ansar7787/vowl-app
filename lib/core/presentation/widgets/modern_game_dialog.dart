import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Premium glassmorphic dialog panel for success briefings, exit confirmations,
/// and life-rescue actions. Rendering-tick animations are isolated behind
/// [RepaintBoundary] to prevent full-dialog repaints.
class ModernGameDialog extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final VoidCallback? onSecondaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onAdAction;
  final String? adButtonText;
  final bool isSuccess;
  final bool isRescueLife;
  final bool isExitConfirmation;
  final Widget? customIcon;

  const ModernGameDialog({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onButtonPressed,
    this.onSecondaryPressed,
    this.secondaryButtonText,
    this.onAdAction,
    this.adButtonText,
    this.isSuccess = true,
    this.isRescueLife = false,
    this.isExitConfirmation = false,
    this.customIcon,
    this.starsListener, // Optional ValueNotifier for reactive stars
  });

  final ValueNotifier<int>? starsListener;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isSuccess
        ? const Color(0xFF10B981)
        : const Color(0xFFF43F5E);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassTile(
        borderRadius: BorderRadius.circular(28.r),
        padding: EdgeInsets.zero,
        blur: 20,
        glassOpacity: isDark ? 0.1 : 0.6,
        child: Padding(
          padding: EdgeInsets.all(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon / mascot ─────────────────────────────────────────
              RepaintBoundary(
                child:
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color:
                            (customIcon != null
                                    ? const Color(0xFFF59E0B)
                                    : primaryColor)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          customIcon ??
                          (isSuccess
                              ? _VictoryMascot(size: 80.r)
                              : Icon(
                                  Icons.heart_broken_rounded,
                                  color: primaryColor,
                                  size: 48.r,
                                )),
                    ).animate().scale(
                      delay: 200.ms,
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
              ),

              SizedBox(height: 24.h),

              // ── Title ─────────────────────────────────────────────────
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),

              if (starsListener != null) ...[
                SizedBox(height: 16.h),
                ValueListenableBuilder<int>(
                  valueListenable: starsListener!,
                  builder: (context, stars, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isEarned = index < stars;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Static grey background placeholder
                              Icon(
                                Icons.star_rounded,
                                size: index == 1 ? 50.r : 40.r,
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                              // 2. Golden star that sequentially scales in if earned
                              if (isEarned)
                                  Icon(
                                    Icons.star_rounded,
                                    size: index == 1 ? 50.r : 40.r,
                                    color: const Color(0xFFFFD700),
                                  )
                                      .animate(key: ValueKey(stars))
                                      .scale(
                                        begin: const Offset(0, 0),
                                        end: const Offset(1, 1),
                                        duration: 400.ms,
                                        curve: Curves.elasticOut,
                                        delay: (500 + index * 150).ms,
                                      )
                                      .then()
                                      .shimmer(
                                        duration: 800.ms,
                                        color: Colors.white54,
                                      ),
                              ],
                            ),
                          );
                        }),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2);
                  },
                ),
              ],

              SizedBox(height: 12.h),

              // ── Description ───────────────────────────────────────────
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),

              SizedBox(height: 32.h),

              // ── Ad / action button (optional) ─────────────────────────
              if (onAdAction != null) ...[
                RepaintBoundary(
                      child: Semantics(
                        button: true,
                        label: adButtonText ?? 'Triple rewards',
                        child: ScaleButton(
                          onTap: onAdAction!,
                          child: Container(
                            width: double.infinity,
                            height: 56.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              gradient: LinearGradient(
                                colors: _adButtonColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isRescueLife
                                              ? Colors.blue
                                              : const Color(0xFFFFA500))
                                          .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isExitConfirmation
                                          ? Icons.logout_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: _adButtonContentColor,
                                      size: 20.r,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      adButtonText ?? 'TRIPLE REWARDS (3X)',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: _adButtonContentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(
                      onPlay: (c) =>
                          (isRescueLife || isExitConfirmation) ? c : c.repeat(),
                    )
                    .shimmer(
                      duration: 2.seconds,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                SizedBox(height: 16.h),
              ],

              // ── Primary button ────────────────────────────────────────
              Semantics(
                button: true,
                label: buttonText,
                child: ScaleButton(
                  onTap: onButtonPressed,
                  child: Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: isRescueLife
                          ? (isDark ? Colors.white12 : Colors.grey[200])
                          : primaryColor,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isRescueLife
                              ? (isDark ? Colors.white54 : Colors.black54)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Secondary button (optional) ───────────────────────────
              if (onSecondaryPressed != null) ...[
                SizedBox(height: 12.h),
                Semantics(
                  button: true,
                  label: secondaryButtonText ?? context.tr('common.cancel'),
                  child: TextButton(
                    onPressed: onSecondaryPressed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      minimumSize: Size(48.w, 48.h),
                    ),
                    child: Text(
                      secondaryButtonText ??
                          context.tr('common.cancel').toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: isSuccess
                            ? (isDark ? Colors.white54 : Colors.black54)
                            : const Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  List<Color> get _adButtonColors {
    if (isExitConfirmation) {
      return const [Color(0xFF64748B), Color(0xFF475569)];
    }
    if (isRescueLife) {
      return const [Color(0xFF2563EB), Color(0xFF1E3A8A)];
    }
    return const [Color(0xFFFFD700), Color(0xFFFFA500)];
  }

  Color get _adButtonContentColor =>
      (isRescueLife || isExitConfirmation) ? Colors.white : Colors.black87;
}

// ---------------------------------------------------------------------------
// Private victory mascot
// ---------------------------------------------------------------------------

class _VictoryMascot extends StatelessWidget {
  final double size;
  const _VictoryMascot({required this.size});

  @override
  Widget build(BuildContext context) {
    return VowlMascot(
      size: size,
      state: VowlMascotState.happy,
      useFloatingAnimation: true,
    );
  }
}
