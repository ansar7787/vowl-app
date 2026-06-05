import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PremiumFailureOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const PremiumFailureOverlay({
    super.key,
    required this.onRetry,
    required this.onClose,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          SizedBox(height: 24.h),
          Text(
            "TRANSACTION FAILED",
            style: TextStyle(fontFamily: 'RobotoMono', 
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF43F5E),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "The payment could not be completed. Please try again or use another payment method.",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 14.sp,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleButton(
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
                    "RETRY",
                    style: TextStyle(fontFamily: 'Outfit', 
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              ScaleButton(
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
                    "CLOSE",
                    style: TextStyle(fontFamily: 'Outfit', 
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().scale(begin: const Offset(0.9, 0.9));
  }
}
