import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PremiumHeader extends StatelessWidget {
  const PremiumHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            // ACCESSIBILITY FIX: an icon-only IconButton with no tooltip
            // is announced by TalkBack/VoiceOver as just "button", giving
            // no indication of what it does. The default IconButton hit
            // target (48x48) already satisfies the minimum touch target.
            tooltip: context.tr('common.back', fallback: 'Back'),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(
              Icons.keyboard_backspace_rounded,
              color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000),
            ),
          ),
          // RESPONSIVENESS FIX: wrapped in Flexible so that on small
          // phones (320dp wide) combined with longer translations (e.g.
          // German, Indian regional scripts routinely run 30-50% longer
          // than the English source), this pill shrinks and ellipsizes
          // instead of overflowing past the screen edge or colliding with
          // the back button.
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x0DFFFFFF)
                    : const Color(0x08000000),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 14.r,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      context.tr('premium.verified_pro_badge', fallback: 'Verified Pro'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark
                            ? const Color(0xB3FFFFFF)
                            : const Color(0xDE000000),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
