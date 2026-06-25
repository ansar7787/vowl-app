import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PremiumFailureOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final String? errorMessage;

  const PremiumFailureOverlay({
    super.key,
    required this.onRetry,
    required this.onClose,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33F43F5E),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              label: context.tr('premium.failure_title'),
              child: Container(
                width: 80.r,
                height: 80.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF43F5E),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr('premium.failure_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF43F5E),
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            if (errorMessage != null && errorMessage!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: const Color(0xFFF43F5E),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            Text(
              errorMessage == null
                  ? context.tr('premium.failure_body_default')
                  : context.tr('premium.failure_body_retry_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: context.tr('premium.retry_button'),
                  child: ScaleButton(
                    onTap: onRetry,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        context.tr('premium.retry_button'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Semantics(
                  button: true,
                  label: context.tr('common.close'),
                  child: ScaleButton(
                    onTap: onClose,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        context.tr('common.close'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade().scale(begin: const Offset(0.9, 0.9));
  }
}
