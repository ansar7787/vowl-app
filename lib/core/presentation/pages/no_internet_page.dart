import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Premium glassmorphic offline page with accessible retry interaction.
///
/// RTL-safe: all directional values are set via [Directionality]-aware
/// widgets. All user-visible strings are resolved via [context.tr()].
class NoInternetPage extends StatefulWidget {
  final Future<void> Function() onRetry;

  const NoInternetPage({super.key, required this.onRetry});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> {
  bool _isChecking = false;
  double _buttonScale = 1.0;

  Future<void> _handleRetry() async {
    if (_isChecking) return;
    await Haptics.vibrate(HapticsType.selection);
    setState(() => _isChecking = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // ── Background glow accents ─────────────────────────────────
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: -100.h,
                  right: -50.w,
                  child: _GlowBlob(
                    color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
                    size: 400.r,
                  ),
                ),
                Positioned(
                  bottom: -150.h,
                  left: -100.w,
                  child: _GlowBlob(
                    color: Colors.purple.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    size: 500.r,
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ────────────────────────────────────────────
          SafeArea(
            // FIX (RESPONSIVENESS/ACCESSIBILITY): a fixed Column centered
            // directly in the viewport overflows at large accessibility
            // text-scale factors (up to 3.0x) or with longer translations
            // of these strings, on small phones (320x568). LayoutBuilder +
            // SingleChildScrollView + ConstrainedBox(minHeight) preserves
            // the exact current centered look whenever content fits, and
            // only scrolls (instead of overflowing) when it doesn't.
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RepaintBoundary(
                          child: _IconPortal(isDark: isDark)
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOutBack,
                              ),
                        ),

                        SizedBox(height: 48.h),

                        Text(
                              context.tr('connectivity.title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .moveY(begin: 10, end: 0),

                        SizedBox(height: 16.h),

                        Text(
                          context.tr('connectivity.subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                        SizedBox(height: 60.h),

                        _RetryButton(
                              isDark: isDark,
                              isChecking: _isChecking,
                              buttonScale: _buttonScale,
                              onPointerDown: () =>
                                  setState(() => _buttonScale = 0.96),
                              onPointerUp: () =>
                                  setState(() => _buttonScale = 1.0),
                              onTap: _handleRetry,
                            )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 600.ms)
                            .moveY(begin: 20, end: 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _IconPortal extends StatelessWidget {
  final bool isDark;
  const _IconPortal({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing rings
        ...List.generate(3, (i) {
          return Container(
                width: (160 + i * 40).r,
                height: (160 + i * 40).r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.04 * (3 - i)),
                    width: 1.5,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: (2000 + i * 500).ms,
                curve: Curves.easeInOut,
              )
              .fadeOut();
        }),

        // Core frosted glass disk
        Semantics(
          label: context.tr(
            'store.no_internet_indicator',
            fallback: 'No internet connection indicator',
          ),
          image: true,
          child:
              Container(
                    width: 140.r,
                    height: 140.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.blue.withValues(alpha: 0.12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(
                            alpha: isDark ? 0.1 : 0.05,
                          ),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.wifiOff,
                        size: 56.r,
                        color: Colors.blue[400],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 3000.ms,
                    color: Colors.blue.withValues(alpha: 0.15),
                  ),
        ),
      ],
    );
  }
}

class _RetryButton extends StatelessWidget {
  final bool isDark;
  final bool isChecking;
  final double buttonScale;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onTap;

  const _RetryButton({
    required this.isDark,
    required this.isChecking,
    required this.buttonScale,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isChecking,
      label: context.tr('connectivity.retry_label'),
      child: Listener(
        onPointerDown: (_) => onPointerDown(),
        onPointerUp: (_) => onPointerUp(),
        onPointerCancel: (_) => onPointerUp(),
        child: GestureDetector(
          onTap: isChecking ? null : onTap,
          child: AnimatedScale(
            scale: buttonScale,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              height: 64.h,
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 48.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  colors: isChecking
                      ? [
                          Colors.blue.withValues(alpha: 0.5),
                          Colors.blue.withValues(alpha: 0.3),
                        ]
                      : const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Stack(
                  children: [
                    if (!isChecking)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: isChecking
                          ? SizedBox(
                              width: 24.r,
                              height: 24.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.refreshCcw,
                                  color: Colors.white,
                                  size: 20.r,
                                ),
                                SizedBox(width: 12.w),
                                Flexible(
                                  child: Text(
                                    context.tr('connectivity.retry_button'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size / 2,
              spreadRadius: size / 4,
            ),
          ],
        ),
      ),
    );
  }
}
