import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class StarVaultBottomSheet extends StatefulWidget {
  final String gameType;
  final Color primaryColor;

  const StarVaultBottomSheet({
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
      builder: (ctx) => StarVaultBottomSheet(gameType: gameType, primaryColor: primaryColor),
    );
  }

  @override
  State<StarVaultBottomSheet> createState() => _StarVaultBottomSheetState();
}

class _StarVaultBottomSheetState extends State<StarVaultBottomSheet> {
  // Extended chest tiers up to 3000+ stars to account for Ad watches!
  final List<int> _chestTiers = List.generate(100, (index) {
    if (index < 10) return 15 + (index * 15);
    return 150 + ((index - 9) * 30);
  });
  bool _isProcessing = false;

  int _calculateTotalStars(Map<String, dynamic> categoryStars) {
    int gameplayStars = 0;
    final magicStars = (categoryStars['magic_stars'] as num?)?.toInt() ?? 0;
    
    categoryStars.forEach((key, value) {
      if (key != 'magic_stars' && key != 'claimed_chests') {
        gameplayStars += (value as num?)?.toInt() ?? 0;
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
    
    // Randomized rewards based on tier (Scarcity Psychology for Ad Revenue)
    final random = math.Random();
    // Balanced game economy: Moderate rewards to protect IAP revenue
    final baseReward = 15 + (tierIndex * 5); 
    final variance = 5 + (tierIndex * 2);
    final int coinReward = baseReward + random.nextInt(variance + 1);

    await updateUserRewards(
      UpdateUserRewardsParams(
        gameType: widget.gameType,
        level: 1, // Dummy level for vault
        xpIncrease: 0,
        coinIncrease: coinReward,
        claimChestTier: tierIndex + 1,
        isVaultReward: true,
      ),
    );

    if (mounted) {
      final isKidsMode = UserGameConstants.kKidsGameTypes.contains(widget.gameType);
      final currencyName = isKidsMode ? "Toys" : "Coins";

      context.read<AuthBloc>().add(const AuthRefreshUser());
      
      setState(() {
        _isProcessing = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => Material(
          type: MaterialType.transparency,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(child: IgnorePointer(child: GameConfetti())),
              ModernGameDialog(
                title: 'CHEST UNLOCKED!',
                description: 'You found +$coinReward $currencyName in the magical chest!',
                buttonText: 'COLLECT',
                isSuccess: true,
                onButtonPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _watchAdForMagicStars() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final adService = di.sl<AdService>();
    if (!adService.isRewardedAdLoaded) {
      CustomSnackBar.show(
        context: context,
        message: "Ad not ready yet. Please wait a moment.",
        type: CustomSnackBarType.warning,
      );
      setState(() => _isProcessing = false);
      return;
    }

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
          showDialog(
            context: context,
            builder: (ctx) => Material(
              type: MaterialType.transparency,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(child: IgnorePointer(child: GameConfetti())),
                  ModernGameDialog(
                    title: 'MAGIC STARS EARNED!',
                    description: 'You got +2 Magic Stars for watching the ad!',
                    buttonText: 'AWESOME',
                    isSuccess: true,
                    onButtonPressed: () => Navigator.of(ctx).pop(),
                    customIcon: Icon(Icons.auto_awesome_rounded, color: const Color(0xFF10B981), size: 48.sp),
                  ),
                ],
              ),
            ),
          );
        }
      },
      onDismissed: () {
        if (mounted) setState(() => _isProcessing = false);
      },
    );
    
    // Safety timeout in case ad fails to load without dismissing
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

        // Find next target
        int nextTierIndex = claimedTier;
        if (nextTierIndex >= _chestTiers.length) {
          nextTierIndex = _chestTiers.length - 1; // All claimed
        }
        final nextRequirement = _chestTiers[nextTierIndex];

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: ScreenUtil().screenHeight * 0.85),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                border: Border(top: BorderSide(color: widget.primaryColor.withValues(alpha: 0.3), width: 2)),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 12.h),
                    Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2.r))),
                    SizedBox(height: 24.h),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open_rounded, color: widget.primaryColor, size: 28.sp),
                        SizedBox(width: 12.w),
                        Text(
                          "Star Vault",
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 24.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Collect stars to unlock massive rewards!",
                      style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    SizedBox(height: 24.h),

                    // Progress
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(color: widget.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24.r), border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text("Your Stars", style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text("$totalStars", style: TextStyle(fontSize: 32.sp, fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: widget.primaryColor)),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: 28.sp),
                                ],
                              ),
                            ],
                          ),
                          Container(width: 2, height: 40.h, color: widget.primaryColor.withValues(alpha: 0.2)),
                          Column(
                            children: [
                              Text("Next Chest", style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text("$nextRequirement", style: TextStyle(fontSize: 32.sp, fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Colors.grey)),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.star_border_rounded, color: Colors.grey, size: 28.sp),
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
                      height: 160.h,
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
                            onTap: () {
                                if (canClaim) {
                                  _claimChest(index, totalStars);
                                } else if (isClaimed) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => ModernGameDialog(
                                      title: 'ALREADY CLAIMED',
                                      description: 'You have already opened this chest!',
                                      buttonText: 'OK',
                                      isSuccess: true,
                                      onButtonPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                  );
                                } else {
                                  final needed = requirement - totalStars;
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => ModernGameDialog(
                                      title: 'NOT ENOUGH STARS',
                                      description: 'You need $needed more stars to open this chest!',
                                      buttonText: 'KEEP PLAYING',
                                      isSuccess: false,
                                      onButtonPressed: () => Navigator.of(ctx).pop(),
                                      customIcon: Icon(Icons.star_border_rounded, color: Colors.orange, size: 48.sp),
                                    ),
                                  );
                                }
                            },
                            child: Container(
                              width: 120.w,
                              margin: EdgeInsets.only(right: 16.w),
                              decoration: BoxDecoration(
                                gradient: canClaim ? LinearGradient(
                                  colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ) : null,
                                color: canClaim ? null : (isClaimed ? Colors.grey.withValues(alpha: 0.1) : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: isClaimed ? Colors.transparent : canClaim ? Colors.white.withValues(alpha: 0.5) : isNext ? widget.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                                  width: canClaim ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isClaimed ? Icons.inventory_2_rounded : canClaim ? Icons.redeem_rounded : Icons.lock_rounded,
                                    size: 44.sp,
                                    color: isClaimed ? Colors.grey : canClaim ? Colors.white : Colors.grey.shade400,
                                  ).animate(target: canClaim ? 1 : 0).shake(hz: 3, duration: 1.5.seconds).then().shimmer(duration: 1.seconds, color: Colors.white),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("$requirement", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: isClaimed ? Colors.grey : canClaim ? Colors.white : isDark ? Colors.white70 : Colors.black87)),
                                      Icon(Icons.star_rounded, size: 16.sp, color: isClaimed ? Colors.grey : const Color(0xFFFFD700)),
                                    ],
                                  ),
                                  if (isClaimed) ...[
                                    SizedBox(height: 6.h),
                                    Text("OPENED", style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.grey)),
                                  ] else if (canClaim) ...[
                                    SizedBox(height: 6.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
                                      child: Text("OPEN", style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900, color: widget.primaryColor)),
                                    ),
                                  ]
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
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: _isProcessing 
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 24.sp, height: 24.sp, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "Loading Ad...",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white70),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 24.sp),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "Watch Ad for +2 Magic Stars",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text("Magic Stars permanently count towards your total!", style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
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
