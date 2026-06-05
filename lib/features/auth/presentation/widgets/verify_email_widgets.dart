import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class VerifyEmailIconHeader extends StatelessWidget {
  const VerifyEmailIconHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.mark_email_unread_rounded,
        size: 64.r,
        color: const Color(0xFF2563EB),
      ),
    );
  }
}

class VerifyEmailStatusText extends StatelessWidget {
  const VerifyEmailStatusText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Verify your email',
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2563EB),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          'We have sent a verification email to your address. Please check your inbox and click the link to verify your account.',
          style: TextStyle(fontFamily: 'Outfit', 
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
    return ElevatedButton(
      onPressed: canResendEmail ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        canResendEmail ? 'Resend Email' : 'Resend in $secondsRemaining s',
        style: TextStyle(fontFamily: 'Outfit', 
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class VerifyConfirmationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VerifyConfirmationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        "I've Verified",
        style: TextStyle(fontFamily: 'Outfit', 
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class VerifyLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VerifyLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Cancel & Logout',
        style: TextStyle(fontFamily: 'Outfit', 
          fontSize: 16.sp,
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
