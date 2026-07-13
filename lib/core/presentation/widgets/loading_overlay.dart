import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Premium glassmorphic full-screen loading overlay with cycling status text.
///
/// Announces itself to screen readers via [Semantics] so accessibility tools
/// correctly report the loading state. All status strings are resolved through
/// [context.tr] for full i18n support.
class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  int _statusIndex = 0;
  Timer? _timer;

  // Translation keys — resolved in build() via context.tr() for full i18n.
  static const List<String> _statusKeys = [
    'loading.status_encrypting',
    'loading.status_syncing',
    'loading.status_finalizing',
    'loading.status_securing',
    'loading.status_optimizing',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _startRotation();
  }

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startRotation();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _stopRotation();
    }
  }

  void _startRotation() {
    _statusIndex = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusKeys.length;
        });
      }
    });
  }

  void _stopRotation() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRotation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Semantics(
            // Inform screen readers that content is loading.
            liveRegion: true,
            label: context.tr('loading.synchronizing_title', fallback: 'Synchronizing...'),
            child: AbsorbPointer(
              child: Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 300)),
                ],
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ColoredBox(
                      color:
                          (isDark
                                  ? const Color(0xFF020617)
                                  : const Color(0xFFF8FAFC))
                              .withValues(alpha: 0.85),
                      child: SizedBox.expand(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Spinner + pulsing logo
                              RepaintBoundary(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                          width: 120.r,
                                          height: 120.r,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  const Color(
                                                    0xFF2563EB,
                                                  ).withValues(alpha: 0.5),
                                                ),
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .rotate(duration: 2000.ms),
                                    Container(
                                          width: 80.r,
                                          height: 80.r,
                                          padding: EdgeInsets.all(12.r),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                          ),
                                          child: Image.asset(
                                            'assets/images/vowl_logo.webp',
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .scale(
                                          duration: 1000.ms,
                                          begin: const Offset(1.0, 1.0),
                                          end: const Offset(1.1, 1.1),
                                          curve: Curves.easeInOut,
                                        ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 48.h),

                              // Main loading label
                              RepaintBoundary(
                                child:
                                    Text(
                                          (widget.message ??
                                                  context.tr(
                                                    'loading.synchronizing_title', fallback: 'Synchronizing...',
                                                  ))
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                            letterSpacing: 4.0,
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .fadeIn(duration: 1000.ms)
                                        .shimmer(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withValues(alpha: 0.3),
                                        ),
                              ),

                              SizedBox(height: 12.h),

                              // Dynamic status sub-text
                              RepaintBoundary(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(
                                    context.tr(_statusKeys[_statusIndex]),
                                    key: ValueKey(_statusIndex),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF64748B))
                                              .withValues(alpha: 0.4),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
