import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final List<String> _statuses = [
    'Encrypting session',
    'Syncing progress',
    'Finalizing quest data',
    'Securing environment',
    'Optimizing assets',
  ];

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
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
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statuses.length;
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
          AbsorbPointer(
            child: Animate(
              effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: (isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC))
                        .withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Isolate the heavy spinning animations with a RepaintBoundary
                          RepaintBoundary(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Rotating brand-colored ring
                                SizedBox(
                                  width: 120.r,
                                  height: 120.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF2563EB).withValues(alpha: 0.5),
                                    ),
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat())
                                 .rotate(duration: 2000.ms),
                                
                                // Pulsing Logo
                                Container(
                                  width: 80.r,
                                  height: 80.r,
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  child: Image.asset(
                                    'assets/images/vowl_logo.webp',
                                    fit: BoxFit.contain,
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
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

                          // High-End Loading Text
                          RepaintBoundary(
                            child: Text(
                              (widget.message ?? 'SYNCHRONIZING').toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: 4.0,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .fadeIn(duration: 1000.ms)
                             .shimmer(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                          ),

                          SizedBox(height: 12.h),

                          // Dynamic Sub-status (Real World Standard)
                          RepaintBoundary(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _statuses[_statusIndex],
                                key: ValueKey(_statusIndex),
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: (isDark ? Colors.white : const Color(0xFF64748B)).withValues(alpha: 0.4),
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
      ],
    );
  }
}
