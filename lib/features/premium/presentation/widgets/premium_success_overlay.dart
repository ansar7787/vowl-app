import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PremiumSuccessOverlay extends StatelessWidget {
  final VoidCallback onBeginAdventure;
  final String? transactionId;

  const PremiumSuccessOverlay({
    super.key,
    required this.onBeginAdventure,
    this.transactionId,
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
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33F59E0B),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      // BUG FIX: the sibling PremiumFailureOverlay already wraps its
      // Column in a SingleChildScrollView so it can't overflow vertically
      // (e.g. landscape on a small phone, or a long transaction ID at a
      // large accessibility text scale). This overlay was missing that
      // same safety net - added here for parity and overflow-safety.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              label: context.tr('premium.success_title', fallback: 'Welcome to Premium!'),
              child:
                  Container(
                        width: 80.r,
                        height: 80.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF59E0B),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .shimmer(duration: 2.seconds),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr('premium.success_title', fallback: 'Welcome to Premium!'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF59E0B),
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              context.tr('premium.success_subtitle', fallback: 'Your upgrade was successful.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            if (transactionId != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('premium.transaction_id_label', fallback: 'Transaction ID'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    SelectableText(
                      transactionId!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Semantics(
              button: true,
              label: context.tr('premium.begin_adventure_button', fallback: 'Begin Adventure'),
              child: ScaleButton(
                onTap: onBeginAdventure,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    context.tr('premium.begin_adventure_button', fallback: 'Begin Adventure'),
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
      ),
    ).animate().fade().scale(begin: const Offset(0.9, 0.9));
  }
}
