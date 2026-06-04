import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/presentation/widgets/verify_email_widgets.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = false;
  int _secondsRemaining = 30;
  Timer? _resendTimer;
  bool _isLoggingOut = false;
  bool _isChecking = false; // Guard flag to prevent concurrent validation API requests

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
    _startResendTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    if (_isLoggingOut) return;
    if (!mounted) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) return;

    _isChecking = true;
    final result = await sl<AuthRepository>().reloadUser();
    
    _isChecking = false;
    if (!mounted) return;
    if (_isLoggingOut) return;
    
    final currentStatus = context.read<AuthBloc>().state.status;
    if (currentStatus != AuthStatus.authenticated) return;

    result.fold(
      (failure) {
        if (context.read<AuthBloc>().state.status == AuthStatus.authenticated && !_isLoggingOut) {
          _showSnackBar(
            'Verification check failed: ${AuthErrorHandler.getMessage(failure.message)}',
            CustomSnackBarType.error,
          );
        }
      },
      (_) {
        if (context.read<AuthBloc>().state.status == AuthStatus.authenticated && !_isLoggingOut) {
          context.read<AuthBloc>().add(const AuthReloadUser());
        }
      },
    );
  }

  void _startResendTimer() {
    setState(() {
      canResendEmail = false;
      _secondsRemaining = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _sendVerificationEmail() async {
    final result = await sl<AuthRepository>().sendEmailVerification();
    result.fold(
      (failure) => _showSnackBar(
        AuthErrorHandler.getMessage(failure.message),
        CustomSnackBarType.error,
      ),
      (_) {
        _showSnackBar(
          'Verification email sent! Please check your inbox.',
          CustomSnackBarType.success,
        );
        _startResendTimer();
      },
    );
  }

  void _showSnackBar(String message, CustomSnackBarType type) {
    CustomSnackBar.show(context: context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.user?.isEmailVerified == true) {
          timer?.cancel();
          final name = state.user?.displayName ?? 'Traveler';
          context.go('${AppRouter.hatchingRoute}?name=${Uri.encodeComponent(name)}');
        }
      },
      child: Builder(builder: (context) {
        final authStatus = context.watch<AuthBloc>().state.status;
        if (_isLoggingOut || authStatus == AuthStatus.loggingOut || authStatus == AuthStatus.unauthenticated) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
          final bgColor = isMidnight 
              ? const Color(0xFF000000) 
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
          
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
        
        final bgColor = isMidnight 
            ? const Color(0xFF000000) 
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              const MeshGradientBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: GlassTile(
                      padding: EdgeInsets.all(32.r),
                      borderRadius: BorderRadius.circular(40.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VerifyEmailIconHeader(),
                          SizedBox(height: 32.h),
                          const VerifyEmailStatusText(),
                          SizedBox(height: 40.h),
                          ResendEmailButton(
                            canResendEmail: canResendEmail,
                            secondsRemaining: _secondsRemaining,
                            onPressed: _sendVerificationEmail,
                          ),
                          SizedBox(height: 16.h),
                          VerifyConfirmationButton(
                            onPressed: _checkEmailVerified,
                          ),
                          SizedBox(height: 16.h),
                          VerifyLogoutButton(
                            onPressed: () {
                              setState(() {
                                _isLoggingOut = true;
                              });
                              timer?.cancel();
                              _resendTimer?.cancel();
                              context.read<AuthBloc>().add(const AuthLogoutRequested());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
