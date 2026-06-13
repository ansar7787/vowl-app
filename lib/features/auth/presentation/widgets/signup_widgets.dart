import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SignUpNameInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  const SignUpNameInput({super.key, this.fieldKey, this.focusNode});

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
          keyboardType: TextInputType.name,
          autofillHints: const [AutofillHints.name],
          style: TextStyle(color: MeshGradientBackground.getContrastColor(context)),
          decoration: InputDecoration(
            hintText: 'Full Name',
            hintStyle: TextStyle(
              color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
            ),
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

class SignUpEmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  const SignUpEmailInput({super.key, this.fieldKey, this.focusNode});

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
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: TextStyle(color: MeshGradientBackground.getContrastColor(context)),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(
              color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
            ),
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
        );
      },
    );
  }
}

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
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.newPassword],
          style: TextStyle(color: MeshGradientBackground.getContrastColor(context)),
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(
              color: MeshGradientBackground.getContrastColor(context).withValues(alpha: 0.5),
            ),
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
              : Text(context.tr('auth.signup')),
        );
      },
    );
  }
}
