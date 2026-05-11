import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/holographic_card.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoginCubit>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _passwordKey = GlobalKey<FormFieldState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  int _emailShake = 0;
  int _passwordShake = 0;

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state.isSuccess) {
              context.read<AuthBloc>().add(const AuthReloadUser());
              context.go(AppRouter.homeRoute);
            }
            if (state.errorMessage != null) {
              final isWarning = state.errorMessage!.contains('canceled');
              _showSnackBar(
                context,
                state.errorMessage!,
                isWarning ? Colors.orange : Colors.red,
              );
            }
            if (state.successMessage != null) {
              _showSnackBar(context, state.successMessage!, Colors.blue);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) {
            Haptics.vibrate(HapticsType.success);
            _showSnackBar(context, state.message!, Colors.blue);
          },
        ),
      ],
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          final contrastColor = MeshGradientBackground.getContrastColor(
            context,
          );
          final secondaryColor = contrastColor.withValues(alpha: 0.6);

          // Password Strength Aura Logic
          Color? auraColor;
          if (_passwordFocus.hasFocus && state.password.isNotEmpty) {
            if (state.password.length < 6) {
              auraColor = Colors.red;
            } else if (state.password.length < 10) {
              auraColor = Colors.blue;
            } else {
              auraColor = Colors.green;
            }
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isMidnight = context.watch<ThemeCubit>().state.isMidnight;

          final bgColor = isMidnight
              ? const Color(0xFF000000)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

          return LoadingOverlay(
            isLoading: state.isSubmitting || state.isSuccess,
            message: 'Preparing your adventure',
            child: Scaffold(
              backgroundColor: bgColor,
              resizeToAvoidBottomInset: false, // Keep background static
              body: Stack(
                children: [
                  MeshGradientBackground(auraColor: auraColor),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final keyboardOpen =
                            MediaQuery.of(context).viewInsets.bottom > 0;
                        return SingleChildScrollView(
                          physics: keyboardOpen
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 20.h,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 10.h,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Brand Row (Mascot + Title)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        VowlBotAuthCompanion(
                                          emailFocus: _emailFocus,
                                          passwordFocus: _passwordFocus,
                                          size: 60,
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
                                                color: const Color(0xFF2563EB),
                                                letterSpacing: -1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Login to continue your adventure',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ShakeableWrapper(
                                            shakeCount: _emailShake,
                                            child: _EmailInput(
                                              fieldKey: _emailKey,
                                              focusNode: _emailFocus,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          ShakeableWrapper(
                                            shakeCount: _passwordShake,
                                            child: _PasswordInput(
                                              fieldKey: _passwordKey,
                                              formKey: _formKey,
                                              focusNode: _passwordFocus,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => context.go(
                                                AppRouter.forgotPasswordRoute,
                                              ),
                                              child: Text(
                                                'Forgot Password?',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          _LoginButton(
                                            formKey: _formKey,
                                            onValidationError: () {
                                              Haptics.vibrate(
                                                HapticsType.error,
                                              );
                                              if (!(_emailKey.currentState
                                                      ?.validate() ??
                                                  true)) {
                                                setState(() => _emailShake++);
                                              }
                                              if (!(_passwordKey.currentState
                                                      ?.validate() ??
                                                  true)) {
                                                setState(
                                                  () => _passwordShake++,
                                                );
                                              }
                                            },
                                          ),
                                          SizedBox(height: 16.h),
                                          _GoogleLoginButton(),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 32.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: GoogleFonts.outfit(
                                            color: secondaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.go(AppRouter.signupRoute),
                                          child: Text(
                                            'Sign Up',
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
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.all(24.r),
      ),
    );
  }
}

class _EmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  const _EmailInput({this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextFormField(
          key: fieldKey,
          focusNode: focusNode,
          onChanged: (email) => context.read<LoginCubit>().emailChanged(email),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: MeshGradientBackground.getContrastColor(context),
          ),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(
              color: MeshGradientBackground.getContrastColor(
                context,
              ).withValues(alpha: 0.5),
            ),
            errorStyle: GoogleFonts.outfit(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: MeshGradientBackground.getContrastColor(
                context,
              ).withValues(alpha: 0.5),
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
        );
      },
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final GlobalKey<FormState> formKey;
  final FocusNode? focusNode;
  const _PasswordInput({this.fieldKey, required this.formKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordVisible != current.isPasswordVisible,
      builder: (context, state) {
        return TextFormField(
          key: fieldKey,
          focusNode: focusNode,
          onChanged: (password) =>
              context.read<LoginCubit>().passwordChanged(password),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          obscureText: !state.isPasswordVisible,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            color: MeshGradientBackground.getContrastColor(context),
          ),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(
              color: MeshGradientBackground.getContrastColor(
                context,
              ).withValues(alpha: 0.5),
            ),
            errorStyle: GoogleFonts.outfit(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: MeshGradientBackground.getContrastColor(
                context,
              ).withValues(alpha: 0.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: MeshGradientBackground.getContrastColor(
                  context,
                ).withValues(alpha: 0.5),
              ),
              onPressed: () =>
                  context.read<LoginCubit>().togglePasswordVisibility(),
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
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onValidationError;

  const _LoginButton({required this.formKey, required this.onValidationError});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        return ElevatedButton(
          onPressed: state.isSubmitting
              ? null
              : () {
                  if (formKey.currentState?.validate() ?? false) {
                    context.read<LoginCubit>().logInWithCredentials();
                  } else {
                    onValidationError();
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
              : const Text('Login'),
        );
      },
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return OutlinedButton(
          onPressed: state.isSubmitting
              ? null
              : () => context.read<LoginCubit>().logInWithGoogle(),
          style: OutlinedButton.styleFrom(
            foregroundColor: MeshGradientBackground.getContrastColor(context),
            side: BorderSide(
              color: MeshGradientBackground.getContrastColor(
                context,
              ).withValues(alpha: 0.2),
            ),
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: state.isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.g_mobiledata, size: 32),
                    SizedBox(width: 8.w),
                    Text(
                      'Sign in with Google',
                      style: GoogleFonts.outfit(fontSize: 16.sp),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class ShakeableWrapper extends StatelessWidget {
  final int shakeCount;
  final Widget child;

  const ShakeableWrapper({
    super.key,
    required this.shakeCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(shakeCount),
      effects: shakeCount > 0
          ? [
              ShakeEffect(hz: 10, offset: const Offset(6, 0), duration: 400.ms),
              TintEffect(
                color: Colors.red.withValues(alpha: 0.05),
                duration: 400.ms,
              ),
            ]
          : [],
      child: child,
    );
  }
}
