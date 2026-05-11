import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/holographic_card.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SignUpCubit>(),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _passwordKey = GlobalKey<FormFieldState>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  int _nameShake = 0;
  int _emailShake = 0;
  int _passwordShake = 0;

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state.isSuccess) {
          final name = context.read<SignUpCubit>().state.name;
          context.read<AuthBloc>().add(const AuthReloadUser());
          context.go('${AppRouter.hatchingRoute}?name=$name');
        }
        if (state.errorMessage != null) {
          _showSnackBar(context, state.errorMessage!, Colors.red);
        }
      },
      child: BlocBuilder<SignUpCubit, SignUpState>(
        builder: (context, state) {
          final contrastColor = MeshGradientBackground.getContrastColor(context);
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
            message: 'Preparing your journey...',
            child: Scaffold(
              backgroundColor: bgColor,
              resizeToAvoidBottomInset: false, // Keep background static
              body: Stack(
                children: [
                  MeshGradientBackground(auraColor: auraColor),
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
                                          nameFocus: _nameFocus,
                                          nameValue: state.name,
                                          emailFocus: _emailFocus,
                                          passwordFocus: _passwordFocus,
                                          size: 60,
                                          isSignup: true,
                                        ),
                                        SizedBox(width: 10.w),
                                        Hero(
                                          tag: 'auth_title',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Text(
                                              'Vowl',
                                              style: GoogleFonts.outfit(
                                                fontSize: 48.sp,
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
                                        'Begin your journey to fluency',
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
                                              shakeCount: _nameShake,
                                              child: _NameInput(
                                                fieldKey: _nameKey,
                                                focusNode: _nameFocus,
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
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
                                                focusNode: _passwordFocus,
                                              ),
                                            ),
                                            SizedBox(height: 32.h),
                                            _SignUpButton(
                                              formKey: _formKey,
                                              onValidationError: () {
                                                Haptics.vibrate(HapticsType.error);
                                                if (!(_nameKey.currentState?.validate() ?? true)) {
                                                  setState(() => _nameShake++);
                                                }
                                                if (!(_emailKey.currentState?.validate() ?? true)) {
                                                  setState(() => _emailShake++);
                                                }
                                                if (!(_passwordKey.currentState?.validate() ?? true)) {
                                                  setState(() => _passwordShake++);
                                                }
                                              },
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
                                          "Already have an account? ",
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

class _NameInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  const _NameInput({this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) => previous.name != current.name,
      builder: (context, state) {
        return TextFormField(
          key: fieldKey,
          focusNode: focusNode,
          onChanged: (name) => context.read<SignUpCubit>().nameChanged(name),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          style: TextStyle(color: MeshGradientBackground.getContrastColor(context)),
          decoration: InputDecoration(
            hintText: 'Full Name',
            hintStyle: TextStyle(color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5)),
            errorStyle: const TextStyle(color: Colors.red),
            prefixIcon: Icon(
              Icons.person_outline,
              color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
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
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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

class _EmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  const _EmailInput({this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextFormField(
          key: fieldKey,
          focusNode: focusNode,
          onChanged: (email) => context.read<SignUpCubit>().emailChanged(email),
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
          style: TextStyle(color: MeshGradientBackground.getContrastColor(context)),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5)),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
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
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
  final FocusNode? focusNode;
  const _PasswordInput({this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordVisible != current.isPasswordVisible,
      builder: (context, state) {
        return TextFormField(
          key: fieldKey,
          focusNode: focusNode,
          onChanged: (password) =>
              context.read<SignUpCubit>().passwordChanged(password),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          textInputAction: TextInputAction.done,
          obscureText: !state.isPasswordVisible,
          style: TextStyle(color: MeshGradientBackground.getContrastColor(context)),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5)),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
              ),
              onPressed: () =>
                  context.read<SignUpCubit>().togglePasswordVisibility(),
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
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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

class _SignUpButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onValidationError;

  const _SignUpButton({required this.formKey, required this.onValidationError});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: state.isSubmitting
              ? null
              : () {
                  if (formKey.currentState?.validate() ?? false) {
                    context.read<SignUpCubit>().signUp();
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
              : const Text('Create Account'),
        );
      },
    );
  }
}
