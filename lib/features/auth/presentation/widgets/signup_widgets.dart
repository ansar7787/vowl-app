import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/auth/domain/constants/auth_validators.dart';
import 'package:vowl/features/auth/presentation/widgets/auth_decoration.dart';

// ---------------------------------------------------------------------------
// Name Input
// ---------------------------------------------------------------------------

class SignUpNameInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;

  const SignUpNameInput({super.key, this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) => previous.name != current.name,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Semantics(
          label: context.tr('auth.name_field_label', fallback: 'Name'),
          hint: context.tr('auth.name_field_hint', fallback: 'What should we call you?'),
          textField: true,
          child: TextFormField(
            key: fieldKey,
            focusNode: focusNode,
            onChanged: (name) => context.read<SignUpCubit>().nameChanged(name),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr(
                  'auth.validation_name_required',
                  fallback: 'Name is required',
                );
              }
              if (value.trim().length < 2) {
                return context.tr(
                  'auth.validation_name_too_short',
                  fallback: 'Name is too short',
                );
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            autofillHints: const [AutofillHints.name],
            style: TextStyle(color: contrastColor),
            decoration: buildAuthDecoration(
              context: context,
              contrastColor: contrastColor,
              hint: context.tr(
                'auth.name_hint_text',
                fallback: 'What should we call you?',
              ),
              prefixIcon: Icons.person_outline,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Email Input
// ---------------------------------------------------------------------------

class SignUpEmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;

  const SignUpEmailInput({super.key, this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
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
                context.read<SignUpCubit>().emailChanged(email),
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
                fallback: 'you@email.com',
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

class SignUpPasswordInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;

  const SignUpPasswordInput({super.key, this.fieldKey, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordVisible != current.isPasswordVisible,
      builder: (context, state) {
        final contrastColor = MeshGradientBackground.getContrastColor(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: context.tr(
                'auth.password_field_label',
                fallback: 'Password',
              ),
              hint: context.tr(
                'auth.password_field_hint_signup',
                fallback: 'Create a password',
              ),
              textField: true,
              child: TextFormField(
                key: fieldKey,
                focusNode: focusNode,
                onChanged: (password) =>
                    context.read<SignUpCubit>().passwordChanged(password),
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
                textInputAction: TextInputAction.done,
                obscureText: !state.isPasswordVisible,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [AutofillHints.newPassword],
                style: TextStyle(color: contrastColor),
                decoration: buildAuthDecoration(
                  context: context,
                  contrastColor: contrastColor,
                  hint: context.tr(
                    'auth.password_hint_text',
                    fallback: 'Your secret key',
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
                      onPressed: () => context
                          .read<SignUpCubit>()
                          .togglePasswordVisibility(),
                    ),
                  ),
                ),
              ),
            ),
            if (state.password.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _PasswordStrengthIndicator(password: state.password),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sign Up Button
// ---------------------------------------------------------------------------

class SignUpButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onValidationError;

  const SignUpButton({
    super.key,
    required this.formKey,
    required this.onValidationError,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        return Semantics(
          button: true,
          label: context.tr('auth.signup', fallback: 'Sign Up'),
          child: ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () {
                    if (formKey.currentState?.validate() ?? false) {
                      context.read<SignUpCubit>().signUp();
                    } else {
                      onValidationError();
                    }
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: state.isSubmitting
                ? const VowlButtonSpinner(size: 24, color: Colors.white)
                // maxLines + overflow, not Flexible — see LoginButton's
                // identical comment for why.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.tr('auth.signup', fallback: 'Sign Up'),
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
// Password Strength Indicator
// ---------------------------------------------------------------------------

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    double strength = 0.0;
    Color strengthColor = Colors.red;
    String strengthLabel = context.tr('auth.strength_weak', fallback: 'Weak');

    if (password.length >= 6) {
      strength = 0.33;
      if (password.length >= 10 && RegExp(r'[0-9]').hasMatch(password)) {
        strength = 1.0;
        strengthColor = Colors.green;
        strengthLabel = context.tr('auth.strength_strong', fallback: 'Strong');
      } else if (password.length >= 8) {
        strength = 0.66;
        strengthColor = Colors.blue;
        strengthLabel = context.tr('auth.strength_fair', fallback: 'Fair');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr(
                'auth.password_strength',
                fallback: 'Password Strength',
              ),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            Text(
              strengthLabel,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white12
                : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 4.h,
          ),
        ),
      ],
    );
  }
}
