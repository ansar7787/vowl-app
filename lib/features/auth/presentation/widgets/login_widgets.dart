import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';

// ---------------------------------------------------------------------------
// Email Input
// ---------------------------------------------------------------------------

class LoginEmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;

  const LoginEmailInput({super.key, this.fieldKey, this.focusNode});

  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Semantics(
          label: 'Email address',
          hint: 'Enter your email address',
          textField: true,
          child: TextFormField(
            key: fieldKey,
            focusNode: focusNode,
            onChanged: (email) =>
                context.read<LoginCubit>().emailChanged(email),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!_emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: contrastColor),
            decoration: InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(color: contrastColor.withValues(alpha: 0.5)),
              errorStyle: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
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
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Password Input
// ---------------------------------------------------------------------------

class LoginPasswordInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final GlobalKey<FormState> formKey;
  final FocusNode? focusNode;

  const LoginPasswordInput({
    super.key,
    this.fieldKey,
    required this.formKey,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordVisible != current.isPasswordVisible,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Semantics(
          label: 'Password',
          hint: 'Enter your password',
          textField: true,
          child: TextFormField(
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
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            style: TextStyle(color: contrastColor),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: contrastColor.withValues(alpha: 0.5)),
              errorStyle: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
              prefixIcon: Icon(
                Icons.lock_outlined,
                color: contrastColor.withValues(alpha: 0.5),
              ),
              suffixIcon: Semantics(
                label: state.isPasswordVisible
                    ? 'Hide password'
                    : 'Show password',
                button: true,
                child: IconButton(
                  icon: Icon(
                    state.isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: contrastColor.withValues(alpha: 0.5),
                  ),
                  onPressed: () =>
                      context.read<LoginCubit>().togglePasswordVisibility(),
                ),
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
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Login Button
// ---------------------------------------------------------------------------

class LoginButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onValidationError;

  const LoginButton({
    super.key,
    required this.formKey,
    required this.onValidationError,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        return Semantics(
          button: true,
          label: 'Log in',
          child: ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () {
                    if (formKey.currentState?.validate() ?? false) {
                      context.read<LoginCubit>().logInWithCredentials();
                    } else {
                      onValidationError();
                    }
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
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
                : Text(context.tr('auth.login')),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Google Login Button
// ---------------------------------------------------------------------------

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Semantics(
          button: true,
          label: 'Sign in with Google',
          child: OutlinedButton(
            onPressed: state.isSubmitting
                ? null
                : () => context.read<LoginCubit>().logInWithGoogle(),
            style: OutlinedButton.styleFrom(
              foregroundColor: contrastColor,
              side: BorderSide(color: contrastColor.withValues(alpha: 0.2)),
              minimumSize: const Size(double.infinity, 56),
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
                      SvgPicture.asset(
                        'assets/icons/google_logo.svg',
                        width: 24.w,
                        height: 24.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: Text(
                          context.tr('auth.sign_in_with_google'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
