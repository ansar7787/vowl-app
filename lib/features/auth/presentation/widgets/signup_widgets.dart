import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';

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
          hint: context.tr('auth.name_field_hint', fallback: 'Enter your name'),
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
            decoration: _buildDecoration(
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

  // Identical pattern also exists (independently — Dart's per-file privacy
  // means a private static field can't be shared) in login_widgets.dart,
  // forgot_password_widgets.dart, and all three auth Cubits. Verified
  // byte-identical across all six.
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

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
              if (!_emailRegex.hasMatch(value.trim())) {
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
            decoration: _buildDecoration(
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
        return Semantics(
          label: context.tr('auth.password_field_label', fallback: 'Password'),
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
            decoration: _buildDecoration(
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
                      context.read<SignUpCubit>().togglePasswordVisibility(),
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
                : Text(
                    context.tr('auth.signup', fallback: 'Sign Up'),
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
// Shared decoration builder (eliminates 3× repeated InputDecoration)
// ---------------------------------------------------------------------------

InputDecoration _buildDecoration({
  required BuildContext context,
  required Color contrastColor,
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: contrastColor.withValues(alpha: 0.5)),
    errorStyle: const TextStyle(color: Colors.red),
    prefixIcon: Icon(prefixIcon, color: contrastColor.withValues(alpha: 0.5)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF3F4F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
  );
}
