import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Clean, production-grade modal displayed when a player has insufficient coins
/// to enter a 1v1 Arena Duel. Features structured balance breakdown, human copy,
/// and design consistency across light, dark, and OLED midnight themes.
class ArenaRefuelDialog extends StatelessWidget {
  final int currentCoins;
  final int requiredCoins;
  final VoidCallback onWatchAd;
  final VoidCallback onCancel;

  const ArenaRefuelDialog({
    super.key,
    required this.currentCoins,
    this.requiredCoins = 30,
    required this.onWatchAd,
    required this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required int currentCoins,
    int requiredCoins = 30,
    required VoidCallback onWatchAd,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArenaRefuelDialog(
        currentCoins: currentCoins,
        requiredCoins: requiredCoins,
        onWatchAd: () {
          Navigator.of(ctx).pop(true);
          onWatchAd();
        },
        onCancel: () => Navigator.of(ctx).pop(false),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onCancel();
      },
      child: Dialog(
        backgroundColor: cardBg,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: borderColor, width: 1.2.r),
        ),
        elevation: 16,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Coin Icon Badge
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.coins,
                    size: 24.r,
                    color: AppColors.amber500,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 2. Direct, Natural Title
              Text(
                'Not Enough Coins',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 14.h),

              // 3. Structured Balance vs Entry Fee Card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    // User Balance
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'YOUR BALANCE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: textSecondary,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '$currentCoins 🪙',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.amber500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1.w,
                      height: 26.h,
                      color: borderColor,
                    ),

                    // Required Stake
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'ENTRY FEE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: textSecondary,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '$requiredCoins 🪙',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // 4. Concise, Human Subtitle
              Text(
                'Watch a short video to get 30 coins.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),

              SizedBox(height: 20.h),

              // 5. Primary Action Button (Golden gradient)
              ScaleButton(
                onTap: onWatchAd,
                child: Container(
                  height: 46.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.video, size: 16.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Watch Video (+30🪙)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // 6. Secondary Dismiss Action
              ScaleButton(
                onTap: onCancel,
                child: Container(
                  height: 36.h,
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

