import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PremiumLockCard extends StatelessWidget {
  final VoidCallback onTap;

  const PremiumLockCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        padding: EdgeInsets.all(20.r),
        borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        borderWidth: 2,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('premium.support_vowl', fallback: 'SUPPORT VOWL'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF59E0B),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.tr('premium.watch_ad_unlock', fallback: 'Watch Ad to Unlock Limitless'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.r),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr('premium.watch_ad_btn', fallback: 'Watch Ad'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
