import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame to render before checking auth state,
    // ensuring the GoRouter context is fully ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNavigation();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkNavigation() {
    if (_hasNavigated) return;

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.unknown) {
      // Auth is still resolving; BlocListener will catch the transition.
      return;
    }

    _hasNavigated = true;
    // GoRouter redirect logic determines whether to land on Home or Login.
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Localised branding aura
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

              // Centre logo
              Center(
                child: RepaintBoundary(
                  child: _SplashLogo(primaryColor: primaryColor),
                ),
              ),

              // Footer branding
              Positioned(
                bottom: 64.h,
                left: 0,
                right: 0,
                child: _SplashFooter(
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets — kept in file because they are splash-exclusive
// ---------------------------------------------------------------------------

class _SplashLogo extends StatelessWidget {
  final Color primaryColor;
  const _SplashLogo({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.r,
      height: 180.r,
      decoration: BoxDecoration(
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
        child: Semantics(
          label: 'Vowl Mascot Logo',
          image: true,
          child: Image.asset(
            'assets/images/vowl_logo.webp',
            height: 130.r,
            width: 130.r,
            fit: BoxFit.contain,
          ),
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
    return Semantics(
      label: 'Vowl App — Your Complete English Quest',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'vowl',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFA8E063),
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
          SizedBox(height: 6.h),
          Text(
            'Your Complete English Quest',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white30 : Colors.black26,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}
