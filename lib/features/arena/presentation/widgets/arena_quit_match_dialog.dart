import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Modern confirmation modal for exiting/forfeiting an active Arena duel or canceling room lobby.
class ArenaQuitMatchDialog extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onForfeit;
  final bool isWaitingLobby;

  const ArenaQuitMatchDialog({
    super.key,
    required this.onStay,
    required this.onForfeit,
    this.isWaitingLobby = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required VoidCallback onForfeit,
    bool isWaitingLobby = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArenaQuitMatchDialog(
        isWaitingLobby: isWaitingLobby,
        onStay: () => Navigator.of(ctx).pop(false),
        onForfeit: () {
          Navigator.of(ctx).pop(true);
          onForfeit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;
    final borderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.22)
        : AppColors.slate200;

    final accentColor = isWaitingLobby ? AppColors.indigo500 : AppColors.rose500;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: borderColor, width: 1.5.r),
      ),
      elevation: 16,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Tag
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWaitingLobby ? LucideIcons.doorOpen : LucideIcons.alertTriangle,
                      size: 11.sp,
                      color: accentColor,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      isWaitingLobby ? 'LOBBY DISSOLUTION' : 'FORFEIT WARNING',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Icon Emblem
            Center(
              child: Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.28),
                    width: 2.r,
                  ),
                ),
                child: Icon(
                  isWaitingLobby ? LucideIcons.doorOpen : LucideIcons.swords,
                  size: 24.sp,
                  color: accentColor,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Dialog Title
            Text(
              isWaitingLobby ? 'Cancel Room Lobby?' : 'Forfeit 1v1 Arena Duel?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 8.h),

            // Body Explanation
            Text(
              isWaitingLobby
                  ? 'No opponent has joined yet. Leaving now will dissolve the room and refund your 30 coins immediately.'
                  : 'Leaving mid-match will count as a forfeit defeat. Your 30 coins will be awarded to your opponent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                color: textSecondary,
                height: 1.35,
              ),
            ),

            SizedBox(height: 14.h),

            // Consequence Breakdown Pill
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B101D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    isWaitingLobby ? LucideIcons.shieldCheck : LucideIcons.alertCircle,
                    size: 16.sp,
                    color: isWaitingLobby ? AppColors.emerald500 : AppColors.rose500,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      isWaitingLobby
                          ? 'Zero penalty: 30 coins returned to your balance'
                          : 'Immediate forfeit: Defeat recorded & 30🪙 lost',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isWaitingLobby ? AppColors.emerald500 : AppColors.rose500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Primary Action: Stay & Fight
            ElevatedButton(
              onPressed: onStay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isWaitingLobby ? LucideIcons.clock : LucideIcons.swords,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isWaitingLobby ? 'Keep Waiting' : 'Stay & Fight',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            // Secondary Action
            OutlinedButton(
              onPressed: onForfeit,
              style: OutlinedButton.styleFrom(
                foregroundColor: isWaitingLobby ? textSecondary : AppColors.rose500,
                side: BorderSide(
                  color: isWaitingLobby
                      ? borderColor
                      : AppColors.rose500.withValues(alpha: 0.4),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                isWaitingLobby ? 'Cancel Lobby (Refund 30🪙)' : 'Forfeit Match (-30🪙)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isWaitingLobby ? textSecondary : AppColors.rose500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
