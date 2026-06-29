import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/usecases/purchase_level_unlock.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class TollGateBottomSheet {
  static void show({
    required BuildContext context,
    required int level,
    required String gameType,
  }) {
    final user = context.read<AuthBloc>().state.user;
    final int userCoins = user?.coins ?? 0;
    const int cost = 150;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            border: Border(top: BorderSide(color: Colors.amber.withValues(alpha: 0.3), width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_open_rounded, size: 56.r, color: Colors.amber.shade600),
              ),
              SizedBox(height: 16.h),
              Text(
                context.tr('games.unlock_level_title', fallback: 'Unlock Next 3 Levels!'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                context.tr('games.unlock_level_desc', args: [cost.toString()], fallback: 'You need $cost coins to unlock the next 3 levels.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 24.h),
              ScaleButton(
                onTap: () async {
                  if (userCoins < cost) {
                    Navigator.pop(sheetContext);
                    CustomSnackBar.show(
                      context: context,
                      message: context.tr('games.not_enough_coins', fallback: 'Not enough coins!'),
                      type: CustomSnackBarType.error,
                    );
                    return;
                  }
                  Navigator.pop(sheetContext);
                  final result = await di.sl<PurchaseLevelUnlock>().call(
                    PurchaseLevelUnlockParams(gameType: gameType, cost: cost)
                  );
                  if (result.isRight() && context.mounted) {
                    CustomSnackBar.show(
                      context: context,
                      message: context.tr('games.level_unlocked_success', fallback: 'Next 3 Levels Unlocked!'),
                      type: CustomSnackBarType.success,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: userCoins >= cost 
                          ? [Colors.amber.shade400, Colors.amber.shade600]
                          : [Colors.grey.shade400, Colors.grey.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      if (userCoins >= cost)
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on_rounded, color: Colors.white, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('games.unlock_button', args: [cost.toString()], fallback: 'Unlock ($cost Coins)'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              ScaleButton(
                onTap: () {
                  final adService = di.sl<AdService>();
                  if (!adService.isRewardedAdLoaded) {
                    Navigator.pop(sheetContext);
                    CustomSnackBar.show(
                      context: context,
                      message: context.tr(
                        'games.ad_not_ready',
                        fallback: 'Ad not ready yet, try again in a moment.',
                      ),
                      type: CustomSnackBarType.warning,
                    );
                    return;
                  }
                  Navigator.pop(sheetContext);
                  adService.showRewardedAd(
                    isPremium: false,
                    onUserEarnedReward: (_) async {
                      // Free unlock via Ad!
                      final result = await di.sl<PurchaseLevelUnlock>().call(
                        PurchaseLevelUnlockParams(gameType: gameType, cost: 0)
                      );
                      if (result.isRight() && context.mounted) {
                        CustomSnackBar.show(
                          context: context,
                          message: context.tr('games.level_unlocked_success', args: [level.toString()], fallback: 'Level $level Unlocked!'),
                          type: CustomSnackBarType.success,
                        );
                      }
                    },
                    onDismissed: () {},
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.3),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('games.watch_ad_unlock_button', fallback: 'Watch Ad to Unlock'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              // Premium Upsell Section
              ScaleButton(
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRouter.premiumRoute);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.workspace_premium_rounded, color: Colors.amber.shade700, size: 24.r),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('games.premium_upsell_title', fallback: 'Tired of locks & ads?'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              context.tr('games.premium_upsell_desc', fallback: 'Get Premium for unlimited levels!'),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16.r),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}
