import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/presentation/widgets/holographic_card.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoginCubit>(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _emailFocus = FocusNode();
  
  int _emailShake = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          _showSnackBar(context, state.successMessage!, Colors.blue);
        }
        if (state.errorMessage != null) {
          _showSnackBar(context, state.errorMessage!, Colors.red);
        }
      },
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          final contrastColor = MeshGradientBackground.getContrastColor(context);
          final secondaryColor = contrastColor.withValues(alpha: 0.6);
          
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
          
          final bgColor = isMidnight 
              ? const Color(0xFF000000) 
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

          return LoadingOverlay(
            isLoading: state.isSubmitting,
            message: 'Sending Recovery Link...',
            child: Scaffold(
              backgroundColor: bgColor,
              resizeToAvoidBottomInset: false, // Keep background static
              body: Stack(
                children: [
                  const MeshGradientBackground(auraColor: Colors.blue), // Recovery aura
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                        return SingleChildScrollView(
                          physics: keyboardOpen 
                              ? const BouncingScrollPhysics() 
                              : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Brand Row (Mascot + Title)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        VowlBotAuthCompanion(
                                          emailFocus: _emailFocus,
                                          size: 60,
                                          isForgotPassword: true,
                                        ),
                                        SizedBox(width: 8.w),
                                        Hero(
                                          tag: 'auth_title',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Text(
                                              'Vowl',
                                              style: GoogleFonts.outfit(
                                                fontSize: 44.sp,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF2563EB), // Vowl Blue
                                                letterSpacing: -1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Recover your account safely',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 32.h),
                                    HolographicCard(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Enter your email address below and we will send you a link to reset your password.',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14.sp,
                                              color: contrastColor.withValues(alpha: 0.8),
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 32.h),
                                          ShakeableWrapper(
                                            shakeCount: _emailShake,
                                            child: TextFormField(
                                              key: _emailKey,
                                              controller: _emailController,
                                              focusNode: _emailFocus,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your email';
                                                }
                                                if (!RegExp(
                                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                                ).hasMatch(value)) {
                                                  return 'Please enter a valid email';
                                                }
                                                return null;
                                              },
                                              style: TextStyle(color: contrastColor),
                                              decoration: InputDecoration(
                                                hintText: 'Email Address',
                                                hintStyle: TextStyle(color: contrastColor.withValues(alpha: 0.5)),
                                                errorStyle: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.sp),
                                                prefixIcon: Icon(
                                                  Icons.email_outlined,
                                                  color: contrastColor.withValues(alpha: 0.5),
                                                ),
                                                filled: true,
                                                fillColor: Theme.of(context).brightness == Brightness.dark 
                                                    ? const Color(0xFF1E293B) 
                                                    : const Color(0xFFF3F4F6),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  borderSide: BorderSide.none,
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFF2563EB),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                                ),
                                                focusedErrorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  borderSide: const BorderSide(color: Colors.red, width: 2.5),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(
                                                  vertical: 20.h,
                                                  horizontal: 20.w,
                                                ),
                                              ),
                                              keyboardType: TextInputType.emailAddress,
                                            ),
                                          ),
                                          SizedBox(height: 24.h),
                                          ElevatedButton(
                                            onPressed: state.isSubmitting
                                                ? null
                                                : () {
                                                    if (_formKey.currentState?.validate() ?? false) {
                                                      context.read<LoginCubit>().forgotPassword(
                                                            _emailController.text.trim(),
                                                          );
                                                    } else {
                                                      if (!(_emailKey.currentState?.validate() ?? true)) {
                                                        setState(() => _emailShake++);
                                                      }
                                                      Haptics.vibrate(HapticsType.error);
                                                    }
                                                  },
                                            child: state.isSubmitting
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text('Send Reset Link'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 32.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Remember your password? ",
                                          style: GoogleFonts.outfit(
                                            color: secondaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.go(AppRouter.loginRoute),
                                          child: Text(
                                            'Login',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2563EB),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        margin: EdgeInsets.all(24.r),
      ),
    );
  }
}
