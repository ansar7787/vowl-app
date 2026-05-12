import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _timerFinished = true);
        _checkNavigation();
      }
    });
  }

  void _checkNavigation() {
    if (!_timerFinished) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.unknown) {
      // If auth is still resolving, we wait. The BlocListener will catch the change.
      debugPrint('SplashPage: Auth still unknown, waiting...');
      return;
    }

    debugPrint('SplashPage: Navigating with status: ${authState.status}');
    // Router redirect logic will handle where to go (Home or Login)
    context.go(AppRouter.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status != AuthStatus.unknown) {
          _checkNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // 1. Localized Branding Aura (Not full screen gradient)
            Center(
              child: Container(
                width: 300.r,
                height: 300.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.12 : 0.05),
                      backgroundColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 1.seconds),

            // 2. Center Logo
            Center(
              child: RepaintBoundary(
                child: _SplashLogo(primaryColor: primaryColor),
              ),
            ),

            // 3. Footer Branding (Stacked for maximum pop)
            Positioned(
              bottom: 64.h, // Increased for breathing space
              left: 0,
              right: 0,
              child: _SplashFooter(primaryColor: primaryColor, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  final Color primaryColor;
  const _SplashLogo({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.r, // Bold Pro Standard
      height: 180.r,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/vowl_logo.webp',
          height: 130.r, // Increased for mascot detail
          width: 130.r,
          fit: BoxFit.contain,
        ),
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn();
  }
}

class _SplashFooter extends StatelessWidget {
  final Color primaryColor;
  final bool isDark;
  const _SplashFooter({required this.primaryColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Branding Pop
        Text(
          'vowl',
          style: GoogleFonts.outfit(
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFA8E063), // Exact Launcher Matching Green
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: const Color(0xFFA8E063).withValues(alpha: 0.2),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
        SizedBox(height: 6.h), // Reduced from 14.h for tight professional branding
        // The Tagline
        Text(
          'Your Complete English Quest',
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white30 : Colors.black26,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }
}
