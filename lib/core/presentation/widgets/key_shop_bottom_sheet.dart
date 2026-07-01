import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';

class KeyShopBottomSheet {
  static void show({
    required BuildContext context,
    required bool isKidsMode,
    Color primaryColor = Colors.amber,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _KeyShopContent(
          isKidsMode: isKidsMode,
          primaryColor: primaryColor,
        );
      },
    );
  }
}

class _KeyShopContent extends StatelessWidget {
  final bool isKidsMode;
  final Color primaryColor;

  const _KeyShopContent({
    required this.isKidsMode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: GestureDetector(
        onTap: () {}, // Prevent taps on the sheet content from closing it
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            border: Border.all(color: primaryColor, width: 4.w),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.6),
                offset: Offset(0, -6.h),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.key_rounded,
                      size: 56.r, color: Colors.amber.shade600),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Golden Keys",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Get a Golden Key to unlock Toll Gates on the map!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Purchase with Coins
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState.user;
                    final userCoins = isKidsMode ? (user?.kidsCoins ?? 0) : (user?.coins ?? 0);
                    const int cost = 150;

                    return ScaleButton(
                      onTap: () async {
                        if (userCoins < cost) {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (ctx) => ModernGameDialog(
                              title: isKidsMode ? 'NOT ENOUGH TOYS' : 'NOT ENOUGH COINS',
                              description: 'You need $cost ${isKidsMode ? 'toys' : 'coins'} to get a key!',
                              buttonText: 'KEEP PLAYING',
                              isSuccess: false,
                              onButtonPressed: () => Navigator.of(ctx).pop(),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        final result = await di.sl<PurchaseGoldenKey>().call(
                          PurchaseGoldenKeyParams(
                            cost: cost,
                            isKidsMode: isKidsMode,
                          )
                        );
                        
                        if (result.isRight() && context.mounted) {
                          context.read<AuthBloc>().add(const AuthReloadUser());
                          showDialog(
                            context: context,
                            builder: (ctx) => Material(
                              type: MaterialType.transparency,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ModernGameDialog(
                                    title: 'GOT A KEY!',
                                    description: 'You got a Golden Key! 🗝️',
                                    buttonText: 'AWESOME',
                                    isSuccess: true,
                                    onButtonPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  const Positioned.fill(child: IgnorePointer(child: GameConfetti())),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: userCoins >= cost
                              ? Colors.amber
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: userCoins >= cost
                                ? Colors.amber.shade700
                                : Colors.grey.shade600,
                            width: 3.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: userCoins >= cost
                                  ? Colors.amber.shade700
                                  : Colors.grey.shade600,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monetization_on_rounded,
                                color: Colors.white, size: 20.r),
                            SizedBox(width: 8.w),
                            Text(
                              "Buy for $cost",
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
                    );
                  },
                ),
                
                SizedBox(height: 12.h),
                
                // Get with Ad
                ScaleButton(
                  onTap: () {
                    final adService = di.sl<AdService>();
                    if (!adService.isRewardedAdLoaded) {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => ModernGameDialog(
                          title: 'AD NOT READY',
                          description: context.tr('games.ad_not_ready', fallback: 'Ad not ready yet, try again in a moment.'),
                          buttonText: 'OK',
                          isSuccess: false,
                          onButtonPressed: () => Navigator.of(ctx).pop(),
                          customIcon: Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 48.sp),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    adService.showRewardedAd(
                      isPremium: false,
                      onUserEarnedReward: (_) async {
                        final result = await di.sl<AddGoldenKey>().call(
                          const AddGoldenKeyParams(amount: 1)
                        );
                        
                        if (result.isRight() && context.mounted) {
                          context.read<AuthBloc>().add(const AuthReloadUser());
                          showDialog(
                            context: context,
                            builder: (ctx) => Material(
                              type: MaterialType.transparency,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ModernGameDialog(
                                    title: 'REWARD UNLOCKED!',
                                    description: 'You got a Golden Key! 🗝️',
                                    buttonText: 'AWESOME',
                                    isSuccess: true,
                                    onButtonPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  const Positioned.fill(child: IgnorePointer(child: GameConfetti())),
                                ],
                              ),
                            ),
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
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.8),
                        width: 3.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.8),
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white, size: 20.r),
                        SizedBox(width: 8.w),
                        Text(
                          "Watch Ad for 1 Key",
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
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
