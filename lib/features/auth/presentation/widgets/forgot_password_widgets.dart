import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';
import 'package:vowl/features/auth/domain/constants/auth_validators.dart';
import 'package:vowl/features/auth/presentation/widgets/auth_decoration.dart';

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class ForgotPasswordHeader extends StatelessWidget {
  final FocusNode emailFocus;
  final Color secondaryColor;

  const ForgotPasswordHeader({
    super.key,
    required this.emailFocus,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VowlBotAuthCompanion(
              emailFocus: emailFocus,
              size: 60,
              isForgotPassword: true,
            ),
            SizedBox(width: 8.w),
            // 'Vowl' is the app's brand name — deliberately not localized.
            Hero(
              tag: 'auth_title',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  'Vowl',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 44.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF6366F1),
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          context.tr(
            'auth.recover_account_subtitle',
            fallback: 'Let\'s get you back on track.',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Email Input
// ---------------------------------------------------------------------------

/// Email input field for the forgot-password flow.
///
/// Uses [ForgotPasswordCubit.emailChanged] to keep cubit state in sync,
/// so [ForgotPasswordCubit.sendPasswordResetEmail] always has the latest
/// value without requiring a [TextEditingController] on the parent.
class ForgotPasswordEmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  final Color contrastColor;

  const ForgotPasswordEmailInput({
    super.key,
    this.fieldKey,
    this.focusNode,
    required this.contrastColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('auth.email_field_label', fallback: 'Email'),
      hint: context.tr(
        'auth.email_field_hint_forgot_password',
        fallback: 'Enter your email address',
      ),
      textField: true,
      child: TextFormField(
        key: fieldKey,
        focusNode: focusNode,
        onChanged: (email) =>
            context.read<ForgotPasswordCubit>().emailChanged(email),
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) {
            return context.tr(
              'auth.validation_email_required',
              fallback: 'Email is required',
            );
          }
          if (!AuthValidators.emailRegex.hasMatch(trimmed)) {
            return context.tr(
              'auth.validation_email_invalid',
              fallback: 'Invalid email address',
            );
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        style: TextStyle(color: contrastColor),
        decoration: buildAuthDecoration(
          context: context,
          contrastColor: contrastColor,
          hint: context.tr(
            'auth.email_hint_full',
            fallback: 'Enter your email address',
          ),
          prefixIcon: Icons.email_outlined,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Send Reset Link Button
// ---------------------------------------------------------------------------

class SendResetLinkButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const SendResetLinkButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('auth.send_reset_link', fallback: 'Reset Password'),
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        child: isSubmitting
            ? const VowlButtonSpinner(size: 24, color: Colors.white)
            // maxLines + overflow (not Flexible — this Text is the button's
            // direct child, not inside a Row/Column, and Flexible requires
            // an immediate Flex ancestor or it throws an "Incorrect use of
            // ParentDataWidget" error) guards against a longer translation
            // wrapping to two lines and looking visually broken inside this
            // full-width, fixed-height button at high accessibility text
            // scale.
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('auth.send_reset_link', fallback: 'Reset Password'),
                  maxLines: 1,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class RememberPasswordFooter extends StatelessWidget {
  final Color secondaryColor;

  const RememberPasswordFooter({super.key, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Flexible + ellipsis: a longer translation of this prompt on a
        // narrow (320px) device could otherwise push this Row into a
        // RenderFlex overflow next to the "Login" button.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr(
                'auth.remember_password_prompt',
                fallback: 'Remembered your password?',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.loginRoute);
            }
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            splashFactory: NoSplash.splashFactory,
            overlayColor: Colors.transparent,
          ),
          child: Text(
            context.tr('auth.login', fallback: 'Log In'),
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
