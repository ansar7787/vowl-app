import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

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

    // INDUSTRY STANDARD: We hold the Android 12 Native Splash Screen over the UI
    // until we know exactly where the user is going. Once auth resolves, we drop
    // the native splash and immediately route them. No "double splash" effect!
    FlutterNativeSplash.remove();

    // GoRouter redirect logic determines whether to land on Home or Login.
    context.go(AppRouter.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          // Empty body — the Native Splash is completely covering this screen!
          body: const SizedBox.expand(),
        ),
      ),
    );
  }
}
