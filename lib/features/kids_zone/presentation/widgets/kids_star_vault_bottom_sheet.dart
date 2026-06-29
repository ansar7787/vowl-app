import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class KidsStarVaultBottomSheet extends StatefulWidget {
  final String gameType;
  final Color primaryColor;

  const KidsStarVaultBottomSheet({
    super.key,
    required this.gameType,
    required this.primaryColor,
  });

  static Future<void> show(BuildContext context, String gameType, Color primaryColor) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => KidsStarVaultBottomSheet(gameType: gameType, primaryColor: primaryColor),
    );
  }

  @override
  State<KidsStarVaultBottomSheet> createState() => _KidsStarVaultBottomSheetState();
}

class _KidsStarVaultBottomSheetState extends State<KidsStarVaultBottomSheet> {
  final List<int> _chestTiers = [15, 30, 45, 60, 75];
  bool _isProcessing = false;
  bool _showConfetti = false;

  int _calculateTotalStars(Map<String, dynamic> categoryStars) {
    int gameplayStars = 0;
    final magicStars = categoryStars['magic_stars'] ?? 0;
    
    categoryStars.forEach((key, value) {
      if (key != 'magic_stars' && key != 'claimed_chests') {
        gameplayStars += value as int;
      }
    });
    return gameplayStars + magicStars;
  }

  Future<void> _claimChest(int tierIndex, int currentStars) async {
    if (_isProcessing) return;
    final requirement = _chestTiers[tierIndex];
    if (currentStars < requirement) return;

    setState(() => _isProcessing = true);

    final updateUserRewards = di.sl<UpdateUserRewards>();
    
    final random = math.Random();
    int coinReward = 100;
    switch(tierIndex) {
      case 0: coinReward = 50 + random.nextInt(101); break;
      case 1: coinReward = 150 + random.nextInt(151); break;
      case 2: coinReward = 300 + random.nextInt(201); break;
      case 3: coinReward = 500 + random.nextInt(301); break;
      case 4: coinReward = 800 + random.nextInt(401); break;
    }

    await updateUserRewards(
      UpdateUserRewardsParams(
        gameType: widget.gameType,
        level: 1, // Dummy level for vault
        xpIncrease: 0,
        coinIncrease: coinReward, // Will automatically route to kidsCoins inside repo
        claimChestTier: tierIndex + 1,
        isVaultReward: true,
      ),
    );

    if (mounted) {
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.read<EconomyBloc>().add(EconomyFetchCoins());
      
      setState(() {
        _showConfetti = true;
        _isProcessing = false;
      });

      CustomSnackBar.show(
        context: context,
        message: "Magical Chest Unlocked! +$coinReward Toys!",
        type: CustomSnackBarType.success,
      );
    }
  }

  Future<void> _watchAdForMagicStars() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final adService = di.sl<AdService>();
    final user = context.read<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;

    adService.showRewardedAd(
      isPremium: isPremium,
      onUserEarnedReward: (_) async {
        final updateUserRewards = di.sl<UpdateUserRewards>();
        await updateUserRewards(
          UpdateUserRewardsParams(
            gameType: widget.gameType,
            level: 1,
            xpIncrease: 0,
            coinIncrease: 0,
            addMagicStars: 2,
            isVaultReward: true,
          ),
        );

        if (mounted) {
          context.read<AuthBloc>().add(const AuthRefreshUser());
          CustomSnackBar.show(
            context: context,
            message: "+2 Magic Stars Added!",
            type: CustomSnackBarType.success,
          );
        }
      },
      onDismissed: () {
        if (mounted) setState(() => _isProcessing = false);
      },
    );
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isProcessing) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) return const SizedBox.shrink();

        final categoryStars = user.starRatings[widget.gameType] ?? {};
        final totalStars = _calculateTotalStars(categoryStars);
        final claimedTier = categoryStars['claimed_chests'] ?? 0;

        int nextTierIndex = claimedTier;
        if (nextTierIndex >= _chestTiers.length) {
          nextTierIndex = _chestTiers.length - 1;
        }
        final nextRequirement = _chestTiers[nextTierIndex];

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_showConfetti) const Positioned.fill(child: IgnorePointer(child: GameConfetti())),
            Container(
              constraints: BoxConstraints(maxHeight: ScreenUtil().screenHeight * 0.85),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                border: Border.all(color: widget.primaryColor.withValues(alpha: 0.5), width: 4.r),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 12.h),
                    Container(width: 50.w, height: 6.h, decoration: BoxDecoration(color: widget.primaryColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3.r))),
                    SizedBox(height: 24.h),
                    
                    // Header
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: widget.primaryColor, size: 48.sp),
                    ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                    SizedBox(height: 16.h),
                    Text(
                      "Magical Star Vault",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 26.sp, fontWeight: FontWeight.w900, color: widget.primaryColor, letterSpacing: 1.0),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Collect stars to unlock magical toys!",
                      style: TextStyle(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 24.h),

                    // Progress
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3), width: 3.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text("Your Stars", style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w800)),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text("$totalStars", style: TextStyle(fontSize: 36.sp, fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: widget.primaryColor)),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: 32.sp),
                                ],
                              ),
                            ],
                          ),
                          Container(width: 3.w, height: 50.h, color: widget.primaryColor.withValues(alpha: 0.2)),
                          Column(
                            children: [
                              Text("Next Chest", style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w800)),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text("$nextRequirement", style: TextStyle(fontSize: 36.sp, fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Colors.grey)),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.star_border_rounded, color: Colors.grey, size: 32.sp),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Chests ListView
                    SizedBox(
                      height: 150.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        itemCount: _chestTiers.length,
                        itemBuilder: (context, index) {
                          final requirement = _chestTiers[index];
                          final isClaimed = claimedTier > index;
                          final canClaim = !isClaimed && totalStars >= requirement;
                          final isNext = index == nextTierIndex;

                          return ScaleButton(
                            onTap: canClaim ? () => _claimChest(index, totalStars) : null,
                            child: Container(
                              width: 120.w,
                              margin: EdgeInsets.only(right: 16.w),
                              decoration: BoxDecoration(
                                color: isClaimed ? Colors.grey.withValues(alpha: 0.1) : canClaim ? widget.primaryColor.withValues(alpha: 0.15) : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(
                                  color: isClaimed ? Colors.transparent : canClaim ? widget.primaryColor : isNext ? widget.primaryColor.withValues(alpha: 0.5) : Colors.transparent,
                                  width: canClaim ? 4.r : 2.r,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isClaimed ? Icons.inventory_2_rounded : canClaim ? Icons.redeem_rounded : Icons.lock_rounded,
                                    size: 48.sp,
                                    color: isClaimed ? Colors.grey : canClaim ? widget.primaryColor : Colors.grey.shade400,
                                  ).animate(target: canClaim ? 1 : 0).shake(hz: 2, duration: 1.seconds),
                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("$requirement", style: TextStyle(fontSize: 18.sp, fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: isClaimed ? Colors.grey : canClaim ? widget.primaryColor : isDark ? Colors.white70 : Colors.black87)),
                                      Icon(Icons.star_rounded, size: 18.sp, color: isClaimed ? Colors.grey : const Color(0xFFFFD700)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Magic Star Ad Button
                    if (claimedTier < _chestTiers.length && totalStars < nextRequirement) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: ScaleButton(
                          onTap: _watchAdForMagicStars,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 18.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]),
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                              boxShadow: [BoxShadow(color: const Color(0xFFEC4899).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: _isProcessing 
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 28.sp),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "Watch Ad for +2 Magic Stars",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ],
                                ),
                          ),
                        ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 24.h),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
