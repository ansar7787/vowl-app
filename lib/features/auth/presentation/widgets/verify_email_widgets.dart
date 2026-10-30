import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color4b5563 = Color(0xFF4B5563);
  static const Color color6b7280 = Color(0xFF6B7280);
}

// ---------------------------------------------------------------------------
// Icon Header
// ---------------------------------------------------------------------------

/// Visual header icon for the email verification screen displaying an unread mail badge.
class VerifyEmailIconHeader extends StatelessWidget {
  /// Creates a [VerifyEmailIconHeader].
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
          color: AppColors.indigo500.withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.mark_email_unread_rounded,
          size: 64.r,
          color: AppColors.indigo500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery Status Enum
// ---------------------------------------------------------------------------

/// Real-time status for the verification email delivery lifecycle.
enum EmailDeliveryStatus {
  /// Initial idle state.
  idle,

  /// Actively dispatching the verification email.
  sending,

  /// Successfully dispatched to the recipient's mail provider.
  sent,

  /// Automated dispatch encountered an error or rate-limit.
  failed,
}

// ---------------------------------------------------------------------------
// Status Text
// ---------------------------------------------------------------------------

/// Instructional status text and recipient chip for the email verification screen.
class VerifyEmailStatusText extends StatelessWidget {
  /// The recipient email address to which the verification link was dispatched.
  final String? email;

  /// Current delivery lifecycle status for visual feedback.
  final EmailDeliveryStatus deliveryStatus;

  /// Creates a [VerifyEmailStatusText] with an optional recipient [email].
  const VerifyEmailStatusText({
    super.key,
    this.email,
    this.deliveryStatus = EmailDeliveryStatus.idle,
  });

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
            color: AppColors.indigo500,
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
            color: isDark ? Colors.white70 : _LocalPalette.color4b5563,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (email != null && email!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16.r,
                  color: AppColors.indigo500,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    email!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.2,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Live delivery status pill
        if (deliveryStatus != EmailDeliveryStatus.idle) ...[
          SizedBox(height: 12.h),
          _buildDeliveryStatusPill(context, isDark),
        ],
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.5.h),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 14.r,
                  color: isDark ? Colors.white54 : _LocalPalette.color6b7280,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  context.tr(
                    'auth.check_spam_hint',
                    fallback:
                        "Didn't receive it? Please check your spam folder.",
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: isDark ? Colors.white54 : _LocalPalette.color6b7280,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatusPill(BuildContext context, bool isDark) {
    Color bg;
    Color border;
    Color textColor;
    Widget leading;
    String text;

    switch (deliveryStatus) {
      case EmailDeliveryStatus.sending:
        bg = AppColors.indigo500.withValues(alpha: 0.08);
        border = AppColors.indigo500.withValues(alpha: 0.25);
        textColor = AppColors.indigo500;
        leading = SizedBox(
          width: 14.r,
          height: 14.r,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        );
        text = context.tr(
          'auth.sending_verification_link',
          fallback: 'Sending verification link...',
        );
        break;
      case EmailDeliveryStatus.sent:
        bg = Colors.green.withValues(alpha: 0.08);
        border = Colors.green.withValues(alpha: 0.25);
        textColor = isDark ? Colors.greenAccent : Colors.green.shade700;
        leading = Icon(Icons.check_circle_rounded, size: 16.r, color: textColor);
        text = context.tr(
          'auth.verification_link_sent_badge',
          fallback: 'Verification link sent to your inbox!',
        );
        break;
      case EmailDeliveryStatus.failed:
        bg = Colors.amber.withValues(alpha: 0.1);
        border = Colors.amber.withValues(alpha: 0.3);
        textColor = isDark ? Colors.amberAccent : Colors.amber.shade900;
        leading = Icon(Icons.error_outline_rounded, size: 16.r, color: textColor);
        text = context.tr(
          'auth.verification_send_failed_badge',
          fallback: "Couldn't send automatically. Tap Resend below.",
        );
        break;
      case EmailDeliveryStatus.idle:
        return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Open Email App Button
// ---------------------------------------------------------------------------

/// Primary prominent action button enabling the user to launch their default email application.
class OpenEmailAppButton extends StatelessWidget {
  /// Callback triggered when opening the device's mail client.
  final VoidCallback onPressed;

  /// Creates an [OpenEmailAppButton].
  const OpenEmailAppButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(
        'auth.open_email_app_semantic',
        fallback: 'Open default email application',
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo500,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56.h),
          elevation: 2,
          shadowColor: AppColors.indigo500.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_rounded, size: 20.r, color: Colors.white),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                context.tr('auth.open_email_app', fallback: 'Open Email App'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resend Email Button
// ---------------------------------------------------------------------------

/// Action button that initiates resending a verification email or reflects countdown cooldown.
class ResendEmailButton extends StatelessWidget {
  /// Whether the resend action is active or currently cooled down.
  final bool canResendEmail;

  /// Remaining seconds before resending is permitted again.
  final int secondsRemaining;

  /// Callback triggered when resending the verification email.
  final VoidCallback onPressed;

  /// Creates a [ResendEmailButton].
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
            fallback: 'Resend available in {0}s',
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
          backgroundColor: AppColors.indigo500,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmation Button ("I've Verified")
// ---------------------------------------------------------------------------

/// Secondary outline button allowing user to manually trigger a verification status check.
class VerifyConfirmationButton extends StatelessWidget {
  /// Callback invoked to verify the user's current email status.
  final VoidCallback onPressed;

  /// Creates a [VerifyConfirmationButton].
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
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr(
              'auth.verified_confirmation',
              fallback: "Yes, I've verified it!",
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.indigo500,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout Button
// ---------------------------------------------------------------------------

/// Cancel/logout text button enabling user to abandon email verification and log out.
class VerifyLogoutButton extends StatelessWidget {
  /// Callback invoked when the user elects to cancel and log out.
  final VoidCallback onPressed;

  /// Creates a [VerifyLogoutButton].
  const VerifyLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('auth.cancel_and_logout_semantic', fallback: 'Log Out'),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('auth.cancel_and_logout', fallback: 'Cancel'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: _LocalPalette.color6b7280,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
