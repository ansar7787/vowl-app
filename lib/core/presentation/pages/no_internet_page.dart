import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A premium, highly immersive glassmorphic offline page.
/// 
/// Employs optimized animation layers, hardware-accelerated glows, and
/// interactive tactile micro-bounces to deliver a polished user experience.
class NoInternetPage extends StatefulWidget {
  final Future<void> Function() onRetry;

  const NoInternetPage({super.key, required this.onRetry});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> {
  bool _isChecking = false;
  double _buttonScale = 1.0; // Captures touch scaling for premium tactile feedback

  Future<void> _handleRetry() async {
    if (_isChecking) return;

    await Haptics.vibrate(HapticsType.selection);
    setState(() => _isChecking = true);

    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // ── Background Holographic Accents ──
          Positioned(
            top: -100.h,
            right: -50.w,
            child: _buildGlow(
              color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
              size: 400.r,
            ),
          ),
          Positioned(
            bottom: -150.h,
            left: -100.w,
            child: _buildGlow(
              color: Colors.purple.withValues(alpha: isDark ? 0.15 : 0.08),
              size: 500.r,
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Holographic Icon Portal
                    _buildIconPortal(isDark)
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                        ),

                    SizedBox(height: 48.h),

                    // Error Message title
                    Text(
                      'CONNECTION LOST',
                      style: GoogleFonts.outfit(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .moveY(begin: 10, end: 0),

                    SizedBox(height: 16.h),

                    Text(
                      'The signal has been interrupted.\nPlease re-establish the connection to continue.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                    SizedBox(height: 60.h),

                    // Operational Blade Button
                    _buildRetryButton(isDark)
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .moveY(begin: 20, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPortal(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing background rings
        ...List.generate(3, (index) {
          return Container(
            width: (160 + (index * 40)).r,
            height: (160 + (index * 40)).r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.04 * (3 - index)),
                width: 1.5,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: (2000 + (index * 500)).ms,
                curve: Curves.easeInOut,
              )
              .fadeOut();
        }),

        // Core Frosted Glass Disk (Hardware-optimized, replaces slow BackdropFilter)
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
                color: Colors.blue.withValues(alpha: isDark ? 0.1 : 0.05),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]
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
      ],
    );
  }

  Widget _buildRetryButton(bool isDark) {
    return Listener(
      onPointerDown: (_) => setState(() => _buttonScale = 0.96),
      onPointerUp: (_) => setState(() => _buttonScale = 1.0),
      onPointerCancel: (_) => setState(() => _buttonScale = 1.0),
      child: GestureDetector(
        onTap: _handleRetry,
        child: AnimatedScale(
          scale: _buttonScale,
          duration: 100.ms,
          curve: Curves.easeOut,
          child: Container(
            height: 64.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                colors: _isChecking
                    ? [
                        Colors.blue.withValues(alpha: 0.5),
                        Colors.blue.withValues(alpha: 0.3),
                      ]
                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
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
                  if (!_isChecking)
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
                    child: _isChecking
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
                            children: [
                              Icon(
                                LucideIcons.refreshCcw,
                                color: Colors.white,
                                size: 20.r,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'RETRY CONNECTION',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
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
    );
  }

  Widget _buildGlow({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
        ],
      ),
    );
  }
}
