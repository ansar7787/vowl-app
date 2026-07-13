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

  // Identical pattern also exists (independently — Dart's per-file privacy
  // means a private static field can't be shared) in signup_widgets.dart,
  // forgot_password_widgets.dart, and all three auth Cubits. Verified
  // byte-identical across all six.
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Semantics(
          label: context.tr('auth.email_field_label', fallback: 'Email', fallback: 'Email'),
          hint: context.tr('auth.email_field_hint_generic', fallback: 'Email Address', fallback: 'Email Address'),
          textField: true,
          child: TextFormField(
            key: fieldKey,
            focusNode: focusNode,
            onChanged: (email) =>
                context.read<LoginCubit>().emailChanged(email),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('auth.validation_email_required', fallback: 'Email is required', fallback: 'Email is required');
              }
              if (!_emailRegex.hasMatch(value.trim())) {
                return context.tr('auth.validation_email_invalid', fallback: 'Invalid email address', fallback: 'Invalid email address');
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: contrastColor),
            decoration: InputDecoration(
              hintText: context.tr('auth.email_hint_short', fallback: 'explorer@vowl.com', fallback: 'explorer@vowl.com'),
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
          label: context.tr('auth.password_field_label', fallback: 'Password', fallback: 'Password'),
          hint: context.tr('auth.password_field_hint_generic', fallback: 'Enter your password', fallback: 'Enter your password'),
          textField: true,
          child: TextFormField(
            key: fieldKey,
            focusNode: focusNode,
            onChanged: (password) =>
                context.read<LoginCubit>().passwordChanged(password),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('auth.validation_password_required', fallback: 'Password is required', fallback: 'Password is required');
              }
              if (value.length < 6) {
                return context.tr('auth.validation_password_too_short', fallback: 'Password must be at least 6 characters', fallback: 'Password must be at least 6 characters');
              }
              return null;
            },
            obscureText: !state.isPasswordVisible,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            style: TextStyle(color: contrastColor),
            decoration: InputDecoration(
              hintText: context.tr('auth.password_hint_text', fallback: 'Make it strong!', fallback: 'Make it strong!'),
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
                    ? context.tr('auth.hide_password', fallback: 'Hide password', fallback: 'Hide password')
                    : context.tr('auth.show_password', fallback: 'Show password', fallback: 'Show password'),
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
          label: context.tr('auth.login', fallback: 'Log In', fallback: 'Log In'),
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
                // maxLines + overflow, not Flexible — this Text is the
                // button's direct child (no Row ancestor), and Flexible
                // requires an immediate Flex ancestor or it throws at
                // runtime. This still guards against a longer translation
                // wrapping to two lines at high text scale.
                : Text(
                    context.tr('auth.login', fallback: 'Log In', fallback: 'Log In'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
          label: context.tr('auth.sign_in_with_google', fallback: 'Sign in with Google', fallback: 'Sign in with Google'),
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
                      // Flexible is valid here (unlike the buttons above)
                      // because this Text's immediate parent is the Row
                      // right above it, which provides the Flex context
                      // Flexible needs.
                      Flexible(
                        child: Text(
                          context.tr('auth.sign_in_with_google', fallback: 'Sign in with Google', fallback: 'Sign in with Google'),
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
