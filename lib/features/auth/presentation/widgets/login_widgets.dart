import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/features/auth/domain/constants/auth_validators.dart';
import 'package:vowl/features/auth/presentation/widgets/auth_decoration.dart';

// ---------------------------------------------------------------------------
// Email Input
// ---------------------------------------------------------------------------

class LoginEmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;

  const LoginEmailInput({super.key, this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Semantics(
          label: context.tr('auth.email_field_label', fallback: 'Email'),
          hint: context.tr(
            'auth.email_field_hint_generic',
            fallback: 'Email Address',
          ),
          textField: true,
          child: TextFormField(
            key: fieldKey,
            focusNode: focusNode,
            onChanged: (email) =>
                context.read<LoginCubit>().emailChanged(email),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr(
                  'auth.validation_email_required',
                  fallback: 'Email is required',
                );
              }
              if (!AuthValidators.emailRegex.hasMatch(value.trim())) {
                return context.tr(
                  'auth.validation_email_invalid',
                  fallback: 'Invalid email address',
                );
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: contrastColor),
            decoration: buildAuthDecoration(
              context: context,
              contrastColor: contrastColor,
              hint: context.tr(
                'auth.email_hint_short',
                fallback: 'explorer@vowl.com',
              ),
              prefixIcon: Icons.email_outlined,
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
          label: context.tr('auth.password_field_label', fallback: 'Password'),
          hint: context.tr(
            'auth.password_field_hint_generic',
            fallback: 'Enter your password',
          ),
          textField: true,
          child: TextFormField(
            key: fieldKey,
            focusNode: focusNode,
            onChanged: (password) =>
                context.read<LoginCubit>().passwordChanged(password),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr(
                  'auth.validation_password_required',
                  fallback: 'Password is required',
                );
              }
              if (value.length < 6) {
                return context.tr(
                  'auth.validation_password_too_short',
                  fallback: 'Password must be at least 6 characters',
                );
              }
              return null;
            },
            obscureText: !state.isPasswordVisible,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            style: TextStyle(color: contrastColor),
            decoration: buildAuthDecoration(
              context: context,
              contrastColor: contrastColor,
              hint: context.tr(
                'auth.password_hint_text',
                fallback: 'Make it strong!',
              ),
              prefixIcon: Icons.lock_outlined,
              suffixIcon: Semantics(
                label: state.isPasswordVisible
                    ? context.tr(
                        'auth.hide_password',
                        fallback: 'Hide password',
                      )
                    : context.tr(
                        'auth.show_password',
                        fallback: 'Show password',
                      ),
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
          label: context.tr('auth.login', fallback: 'Log In'),
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
                ? const VowlButtonSpinner(size: 24, color: Colors.white)
                // maxLines + overflow, not Flexible — this Text is the
                // button's direct child (no Row ancestor), and Flexible
                // requires an immediate Flex ancestor or it throws at
                // runtime. This still guards against a longer translation
                // wrapping to two lines at high text scale.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr('auth.login', fallback: 'Log In'),
                      maxLines: 1,
                    ),
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
          label: context.tr(
            'auth.sign_in_with_google',
            fallback: 'Sign in with Google',
          ),
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
                ? const VowlButtonSpinner(size: 24, color: Colors.white)
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr(
                              'auth.sign_in_with_google',
                              fallback: 'Sign in with Google',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                            ),
                          ),
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
