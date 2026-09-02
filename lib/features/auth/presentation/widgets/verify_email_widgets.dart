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
  final String? email;

  const VerifyEmailStatusText({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (email != null) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_rounded,
                  size: 16.r,
                  color: const Color(0xFF6366F1),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    email!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6366F1),
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14.r,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                context.tr(
                  'auth.check_spam_hint',
                  fallback: "Can't find it? Check your spam folder.",
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
              ),
            ),
          ],
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
    final label = canResendEmail
        ? context.tr('auth.resend_email', fallback: 'Resend Email')
        : context.tr(
            'auth.resend_in',
            fallback: 'Resend in {0} s',
            args: ['$secondsRemaining'],
          );
    return Semantics(
      button: true,
      label: canResendEmail
          ? context.tr(
              'auth.resend_verification_email_semantic',
              fallback: 'Resend verification email',
            )
          : context.tr(
              'auth.resend_cooldown_semantic',
              fallback: 'Resend available in {0} seconds',
              args: ['$secondsRemaining'],
            ),
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
        fallback: 'Check if email has been verified',
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
          context.tr(
            'auth.verified_confirmation',
            fallback: "I've Verified My Email",
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6366F1),
          ),
          maxLines: 1,
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
        ),
      ),
    );
  }
}
