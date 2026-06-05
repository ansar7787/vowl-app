import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/home/presentation/widgets/vowlbot_auth_companion.dart';

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
            Hero(
              tag: 'auth_title',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  'Vowl',
                  style: TextStyle(fontFamily: 'Outfit', 
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
          'Recover your account safely',
          style: TextStyle(fontFamily: 'Outfit', 
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

class ForgotPasswordEmailInput extends StatelessWidget {
  final GlobalKey<FormFieldState> fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color contrastColor;

  const ForgotPasswordEmailInput({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.contrastColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      style: TextStyle(color: contrastColor),
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        hintText: 'Email Address',
        hintStyle: TextStyle(color: contrastColor.withValues(alpha: 0.5)),
        errorStyle: TextStyle(fontFamily: 'Outfit', 
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
    );
  }
}

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
    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text('Send Reset Link'),
    );
  }
}

class RememberPasswordFooter extends StatelessWidget {
  final Color secondaryColor;

  const RememberPasswordFooter({super.key, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Remember your password? ",
          style: TextStyle(fontFamily: 'Outfit', 
            color: secondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRouter.loginRoute),
          child: Text(
            'Login',
            style: TextStyle(fontFamily: 'Outfit', 
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
