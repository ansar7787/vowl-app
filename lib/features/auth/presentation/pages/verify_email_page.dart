import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/widgets/verify_email_widgets.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

/// Email-verification gate displayed after account creation.
///
/// ### Architecture
/// All backend interactions are dispatched through [AuthBloc] events —
/// no direct repository or service-locator calls occur at this layer.
///
/// - Periodic verification check → [AuthReloadUser] event (every 3 s)
/// - Resend button → [AuthSendEmailVerificationRequested] event
/// - Navigation → triggered when [AuthState.user.isEmailVerified] becomes true
/// - Resend cooldown → triggered when [AuthState.message] ==
///   `'auth.email_verification_sent'`
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _verificationTimer;
  Timer? _resendCooldownTimer;

  final ValueNotifier<bool> _canResendEmail = ValueNotifier(false);
  final ValueNotifier<int> _secondsRemaining = ValueNotifier(30);
  final ValueNotifier<bool> _isLoggingOut = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _startVerificationPolling();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _resendCooldownTimer?.cancel();
    _canResendEmail.dispose();
    _secondsRemaining.dispose();
    _isLoggingOut.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Verification polling
  // ---------------------------------------------------------------------------

  void _startVerificationPolling() {
    _verificationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _triggerVerificationCheck(),
    );
  }

  void _triggerVerificationCheck() {
    if (_isLoggingOut.value || !mounted) return;
    final status = context.read<AuthBloc>().state.status;
    if (status != AuthStatus.authenticated) return;
    context.read<AuthBloc>().add(const AuthReloadUser());
  }

  // ---------------------------------------------------------------------------
  // Email resend
  // ---------------------------------------------------------------------------

  void _requestVerificationEmail() {
    context.read<AuthBloc>().add(const AuthSendEmailVerificationRequested());
  }

  void _startResendCooldown() {
    _canResendEmail.value = false;
    _secondsRemaining.value = 30;
    
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_secondsRemaining.value > 0) {
        _secondsRemaining.value--;
      } else {
        _canResendEmail.value = true;
        timer.cancel();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  void _showSnackBar(String message, CustomSnackBarType type) {
    if (!mounted) return;
    CustomSnackBar.show(context: context, message: message, type: type);
  }

  Color _bgColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.read<ThemeCubit>().state.isMidnight;
    return isMidnight
        ? const Color(0xFF000000)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user?.isEmailVerified != current.user?.isEmailVerified ||
          previous.status != current.status ||
          (previous.message != current.message && current.message != null),
      listener: (context, state) {
        // Navigation: email verified
        if (state.user?.isEmailVerified == true) {
          _verificationTimer?.cancel();
          // Do nothing. We rely on GoRouter's automatic redirect (refreshListenable)
          // which evaluates _redirect in app_router.dart when AuthBloc completes its
          // backend synchronization. This automatically routes new users to hatching.
          return;
        }

        // Verification email sent: restart resend cooldown and show snackbar.
        // Previously showed a hardcoded English sentence here instead of
        // translating the same 'auth.email_verification_sent' key every
        // other success path in AuthBloc already resolves through
        // context.tr() — this was the one message on this screen that
        // could never have been localized.
        if (state.message == 'auth.email_verification_sent') {
          _startResendCooldown();
          _showSnackBar(
            context.tr(
              'auth.email_verification_sent',
              fallback: 'Email verification sent!',
            ),
            CustomSnackBarType.success,
          );
          return;
        }

        // Other messages (errors) from the verification flow
        if (state.message != null &&
            state.message != 'auth.email_verification_sent') {
          _showSnackBar(
            context.tr(AuthErrorHandler.getKey(state.message!)),
            CustomSnackBarType.error,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          return ListenableBuilder(
            listenable: Listenable.merge([_isLoggingOut, _canResendEmail, _secondsRemaining]),
            builder: (context, _) {
              final bgColor = _bgColor(context);

              // Show loading while signing out
              if (_isLoggingOut.value ||
                  state.status == AuthStatus.loggingOut ||
                  state.status == AuthStatus.unauthenticated) {
                return Scaffold(
                  backgroundColor: bgColor,
                  body: const SafeArea(child: HomeShimmerLoading()),
                );
              }

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
                              canResendEmail: _canResendEmail.value,
                              secondsRemaining: _secondsRemaining.value,
                              onPressed: _requestVerificationEmail,
                            ),
                            SizedBox(height: 16.h),
                            VerifyConfirmationButton(
                              onPressed: _triggerVerificationCheck,
                            ),
                            SizedBox(height: 16.h),
                            VerifyLogoutButton(
                              onPressed: () {
                                _isLoggingOut.value = true;
                                _verificationTimer?.cancel();
                                _resendCooldownTimer?.cancel();
                                context.read<AuthBloc>().add(
                                  const AuthLogoutRequested(),
                                );
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
            },
          );
        },
      ),
    );
  }
}
