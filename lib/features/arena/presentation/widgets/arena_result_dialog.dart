import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

class ArenaResultDialog extends StatelessWidget {
  final bool isWinner;
  final bool isDraw;
  final int myScore;
  final int rivalScore;
  final String rivalName;
  final int payoutCoins;
  final VoidCallback onRematch;
  final VoidCallback onClose;

  const ArenaResultDialog({
    super.key,
    required this.isWinner,
    required this.isDraw,
    required this.myScore,
    required this.rivalScore,
    required this.rivalName,
    required this.payoutCoins,
    required this.onRematch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.midnightSurface : (tokens?.surface ?? Colors.white);
    final borderColor = isDark ? AppColors.slate800 : (tokens?.border ?? const Color(0xFFE2E8F0));
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));

    final title = isDraw ? 'Tied Match!' : (isWinner ? 'Victory!' : 'Defeat');
    final iconColor = isDraw
        ? const Color(0xFFF59E0B)
        : (isWinner ? AppColors.emerald500 : AppColors.rose500);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: borderColor, width: 1.w),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Victory / Defeat Badge
            Center(
              child: Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDraw ? LucideIcons.scale : (isWinner ? LucideIcons.trophy : LucideIcons.swords),
                  size: 32.sp,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isDraw
                  ? 'Great minds think alike! 30 coins returned.'
                  : (isWinner
                      ? 'You crushed the duel! +$payoutCoins coins awarded.'
                      : 'Close battle! +$payoutCoins coins consolation.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: textSecondary,
              ),
            ),

            SizedBox(height: 18.h),

            // Score Comparison Box
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('You', style: TextStyle(fontSize: 11.sp, color: textSecondary)),
                      SizedBox(height: 2.h),
                      Text(
                        '$myScore',
                        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.indigo500),
                      ),
                    ],
                  ),
                  Text('VS', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: textSecondary)),
                  Column(
                    children: [
                      Text(rivalName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: textSecondary)),
                      SizedBox(height: 2.h),
                      Text(
                        '$rivalScore',
                        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Rematch Button (Double or Nothing)
            ElevatedButton.icon(
              onPressed: onRematch,
              icon: Icon(LucideIcons.flame, size: 18.sp, color: Colors.white),
              label: Text(
                '🔥 Rematch (Double or Nothing!)',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),

            SizedBox(height: 8.h),

            // Exit Button
            TextButton(
              onPressed: onClose,
              child: Text(
                'Back to Leaderboard',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
