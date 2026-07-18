import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

// ---------------------------------------------------------------------------
// Icon Header
// ---------------------------------------------------------------------------

class VerifyEmailIconHeader extends StatelessWidget {
  const VerifyEmailIconHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.tr(
        'auth.verify_email_icon_label',
        fallback: 'Verify Email',
      ),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.mark_email_unread_rounded,
          size: 64.r,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Text
// ---------------------------------------------------------------------------

class VerifyEmailStatusText extends StatelessWidget {
  const VerifyEmailStatusText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('auth.verify_email_title', fallback: 'Check your inbox'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6366F1),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          context.tr(
            'auth.verify_email_description',
            fallback:
                'We sent a verification link to your email. Please click the link to verify your account.',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : const Color(0xFF4B5563),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Resend Email Button
// ---------------------------------------------------------------------------

class ResendEmailButton extends StatelessWidget {
  final bool canResendEmail;
  final int secondsRemaining;
  final VoidCallback onPressed;

  const ResendEmailButton({
    super.key,
    required this.canResendEmail,
    required this.secondsRemaining,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE — not fully localizable yet: 'Resend in $secondsRemaining s'
    // interpolates a number directly into English text. None of the eight
    // files in this review contain a single example of a *parameterized*
    // context.tr() call (every existing call site is a bare string key with
    // no arguments), so there's no confirmed evidence of what signature
    // locale_service.dart's tr() extension actually supports for
    // placeholders/pluralization. Guessing at an unverified method
    // signature risks a compile error, and concatenating translated
    // fragments around the number (e.g. '${context.tr('auth.resend_in', fallback: 'Resend in')}
    // $secondsRemaining ${context.tr('auth.seconds_unit', fallback: 's')}') is a worse
    // localization anti-pattern than what's here now — word order and
    // pluralization both vary by language, and fragment concatenation
    // can't express either correctly. Left as English pending confirmation
    // of the real parameterization API; see the review notes.
    final label = canResendEmail
        ? context.tr('auth.resend_email', fallback: 'Resend Email')
        : 'Resend in $secondsRemaining s';
    return Semantics(
      button: true,
      label: canResendEmail
          ? context.tr(
              'auth.resend_verification_email_semantic',
              fallback: 'Resend verification email',
            )
          : 'Resend available in $secondsRemaining seconds',
      child: ElevatedButton(
        onPressed: canResendEmail ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          // maxLines + overflow, not Flexible — this Text is the button's
          // direct child (no Row ancestor), and Flexible requires an
          // immediate Flex ancestor or it throws at runtime.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmation Button ("I've Verified")
// ---------------------------------------------------------------------------

class VerifyConfirmationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VerifyConfirmationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        'auth.verified_confirmation_semantic',
        fallback: 'Email verified, you can now continue',
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          context.tr('auth.verified_confirmation', fallback: 'Email Verified!'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6366F1),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout Button
// ---------------------------------------------------------------------------

class VerifyLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VerifyLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        'auth.cancel_and_logout_semantic',
        fallback: 'Cancel and log out',
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(
          context.tr('auth.cancel_and_logout', fallback: 'Cancel'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
