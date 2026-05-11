import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

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
    final result = await sl<AuthRepository>().reloadUser();
    result.fold(
      (failure) {
        if (!mounted) return;
        _showSnackBar('Check failed: ${failure.message}', Colors.red);
      },
      (_) {
        if (!mounted) return;
        context.read<AuthBloc>().add(AuthReloadUser());
      },
    );
  }

  void _startResendTimer() {
    setState(() {
      canResendEmail = false;
      _secondsRemaining = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    result.fold((failure) => _showSnackBar(failure.message, Colors.red), (_) {
      _showSnackBar('Verification email sent!', Colors.green);
      _startResendTimer();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.user?.isEmailVerified == true) {
          timer?.cancel();
          context.go(AppRouter.homeRoute);
        }
      },
      child: Builder(builder: (context) {
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
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.mark_email_unread_rounded,
                            size: 64.r,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          'Verify your email',
                          style: GoogleFonts.outfit(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'We have sent a verification email to your address. Please check your inbox and click the link to verify your account.',
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40.h),
                        ElevatedButton(
                          onPressed: canResendEmail
                              ? _sendVerificationEmail
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 56.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(
                            canResendEmail
                                ? 'Resend Email'
                                : 'Resend in $_secondsRemaining s',
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        OutlinedButton(
                          onPressed: _checkEmailVerified,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                            minimumSize: Size(double.infinity, 56.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(
                            "I've Verified",
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                          },
                          child: Text(
                            'Cancel & Logout',
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
