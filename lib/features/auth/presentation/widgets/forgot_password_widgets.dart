import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';

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
                    color: const Color(0xFF2563EB),
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          context.tr('auth.recover_account_subtitle', fallback: 'Let\'s get you back on track.'),
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

  // Identical pattern also exists (independently — Dart's per-file privacy
  // means a private static field can't be shared) in login_widgets.dart,
  // signup_widgets.dart, and all three auth Cubits. Verified byte-identical
  // across all six; see the review notes for why this can't be fully
  // deduplicated within this feature's file list.
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('auth.email_field_label', fallback: 'Email'),
      hint: context.tr('auth.email_field_hint_forgot_password', fallback: 'Enter your email address'),
      textField: true,
      child: TextFormField(
        key: fieldKey,
        focusNode: focusNode,
        onChanged: (email) =>
            context.read<ForgotPasswordCubit>().emailChanged(email),
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) {
            return context.tr('auth.validation_email_required', fallback: 'Email is required');
          }
          if (!_emailRegex.hasMatch(trimmed)) {
            return context.tr('auth.validation_email_invalid', fallback: 'Invalid email address');
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        style: TextStyle(color: contrastColor),
        decoration: InputDecoration(
          hintText: context.tr('auth.email_hint_full', fallback: 'e.g., explorer@vowl.com'),
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
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
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
      label: context.tr('auth.send_reset_link', fallback: 'Send Reset Link'),
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            // maxLines + overflow (not Flexible — this Text is the button's
            // direct child, not inside a Row/Column, and Flexible requires
            // an immediate Flex ancestor or it throws an "Incorrect use of
            // ParentDataWidget" error) guards against a longer translation
            // wrapping to two lines and looking visually broken inside this
            // full-width, fixed-height button at high accessibility text
            // scale.
            : Text(
                context.tr('auth.send_reset_link', fallback: 'Send Reset Link'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          child: Text(
            context.tr('auth.remember_password_prompt', fallback: 'Remember your password?'),
            style: TextStyle(
              fontFamily: 'Outfit',
              color: secondaryColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRouter.loginRoute),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            context.tr('auth.login', fallback: 'Log In'),
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
