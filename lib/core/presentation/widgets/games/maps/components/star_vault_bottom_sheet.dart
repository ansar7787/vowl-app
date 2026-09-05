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
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';

class StarVaultBottomSheet extends StatefulWidget {
  final String gameType;
  final Color primaryColor;

  const StarVaultBottomSheet({
    super.key,
    required this.gameType,
    required this.primaryColor,
  });

  static Future<void> show(
    BuildContext context,
    String gameType,
    Color primaryColor,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) =>
          StarVaultBottomSheet(gameType: gameType, primaryColor: primaryColor),
    );
  }

  @override
  State<StarVaultBottomSheet> createState() => _StarVaultBottomSheetState();
}

class _StarVaultBottomSheetState extends State<StarVaultBottomSheet> {
  // Extended chest tiers up to 3000+ stars to account for Ad watches!
  static final List<int> _chestTiers = List.generate(100, (index) {
    if (index < 10) return 15 + (index * 15);
    return 150 + ((index - 9) * 30);
  });
  bool _isProcessing = false;
  int _remainingClaims = RewardLimitService.maxClaimsPerDay;
  bool _isLoadingLimits = true;
  int _outOfAdsShake = 0;

  late final ValueNotifier<int> _stateHash = ValueNotifier(0);

  void _updateState() {
    if (mounted) _stateHash.value++;
  }

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final remaining = await RewardLimitService.getRemainingClaims('stars');
    if (mounted) {
      _remainingClaims = remaining;
      _isLoadingLimits = false;
      _updateState();
    }
  }

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

  /// Shows a failure dialog when a reward grant doesn't go through -
  /// shared by both [_claimChest] and [_watchAdForMagicStars], which
  /// previously had no failure path at all (see their doc comments).
  void _showRewardFailedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => ModernGameDialog(
        title: context.tr(
          'store.reward_failed_title',
          fallback: 'REWARD FAILED',
        ),
        description: context.tr(
          'store.reward_failed_desc',
          fallback:
              "We couldn't grant your reward. Please contact support if this keeps happening.",
        ),
        buttonText: context.tr('common.ok', fallback: 'OK').toUpperCase(),
        isSuccess: false,
        onButtonPressed: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _claimChest(int tierIndex, int currentStars) async {
    if (_isProcessing) return;
    final requirement = _chestTiers[tierIndex];
    if (currentStars < requirement) return;

    _isProcessing = true;
    _updateState();

    final updateUserRewards = di.sl<UpdateUserRewards>();

    // Randomized rewards based on tier (Scarcity Psychology for Ad Revenue)
    final random = math.Random();
    // Balanced game economy: Moderate rewards to protect IAP revenue
    final baseReward = 15 + (tierIndex * 5);
    final variance = 5 + (tierIndex * 2);
    final int coinReward = baseReward + random.nextInt(variance + 1);

    // BUG FIX (SILENT/FALSE SUCCESS): the return value of this call was
    // previously discarded entirely (`await updateUserRewards(...);` with
    // no result captured), so the success dialog + confetti below fired
    // UNCONDITIONALLY - even if the backend update actually failed. That
    // means a user could see "You found +50 coins!" with a full confetti
    // celebration while their actual balance never changed, since the
    // grant silently failed server-side. Capturing and checking the
    // Either result fixes this.
    final result = await updateUserRewards(
      UpdateUserRewardsParams(
        gameType: widget.gameType,
        level: 1, // Dummy level for vault
        xpIncrease: 0,
        coinIncrease: coinReward,
        claimChestTier: tierIndex + 1,
        isVaultReward: true,
      ),
    );

    if (!mounted) return;

    if (result.isLeft()) {
      _isProcessing = false;
      _updateState();
      _showRewardFailedDialog();
      return;
    }

    final isKidsMode = UserGameConstants.kKidsGameTypes.contains(
      widget.gameType,
    );
    final currencyName = isKidsMode
        ? context.tr('store.toys', fallback: 'Toys')
        : context.tr('store.coins', fallback: 'Coins');

    context.read<AuthBloc>().add(const AuthRefreshUser());

    _isProcessing = false;
    _updateState();

    showDialog(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ModernGameDialog(
              title: context.tr(
                'store.chest_unlocked_title',
                fallback: 'CHEST UNLOCKED!',
              ),
              description: context.tr(
                'store.chest_reward_desc',
                args: ['$coinReward', currencyName],
                fallback:
                    'You found +$coinReward $currencyName in the magical chest!',
              ),
              buttonText: context.tr('store.collect', fallback: 'COLLECT'),
              isSuccess: true,
              onButtonPressed: () {
                Navigator.of(ctx).pop();
                if (mounted && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Positioned.fill(child: IgnorePointer(child: GameConfetti())),
          ],
        ),
      ),
    );
  }

  Future<void> _watchAdForMagicStars() async {
    if (_isProcessing) return;
    if (_remainingClaims <= 0) {
      _outOfAdsShake++;
      _updateState();
      showDialog(
        context: context,
        builder: (ctx) => ModernGameDialog(
          title: context.tr(
            'store.limit_reached_title',
            fallback: 'DAILY LIMIT REACHED',
          ),
          description: context.tr(
            'store.limit_reached_desc_stars',
            fallback:
                'You have claimed all your free stars for today! Come back tomorrow or visit the Premium Store for unlimited access.',
          ),
          buttonText: context.tr('store.got_it', fallback: 'GOT IT'),
          isSuccess: false,
          onButtonPressed: () => Navigator.of(ctx).pop(),
          customIcon: Icon(
            Icons.lock_clock_rounded,
            color: Colors.orange,
            size: 48.sp,
          ),
        ),
      );
      return;
    }
    _isProcessing = true;
    _updateState();

    final adService = di.sl<AdService>();
    if (!adService.isRewardedAdLoaded) {
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'store.ad_not_ready_wait',
          fallback: 'Ad not ready yet. Please wait a moment.',
        ),
        type: CustomSnackBarType.warning,
      );
      _isProcessing = false;
      _updateState();
      return;
    }

    final user = context.read<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;

    bool rewardEarned = false;

    adService.showRewardedAd(
      context: context,
      isPremium: isPremium,
      onUserEarnedReward: (_) {
        rewardEarned = true;
      },
      onDismissed: () async {
        if (!mounted) return;
        _isProcessing = false;
        _updateState();

        if (!rewardEarned) return;

        _isProcessing = true;
        _updateState();

        final updateUserRewards = di.sl<UpdateUserRewards>();
        // BUG FIX: same discarded-result issue as _claimChest above - the
        // user watches a full rewarded ad, and previously would see
        // "Magic Stars Earned!" even if the grant call failed.
        final result = await updateUserRewards(
          UpdateUserRewardsParams(
            gameType: widget.gameType,
            level: 1,
            xpIncrease: 0,
            coinIncrease: 0,
            addMagicStars: 2,
            isVaultReward: true,
          ),
        );

        if (result.isRight()) {
          await RewardLimitService.incrementClaimCount('stars');
        }

        if (!mounted) return;
        _isProcessing = false;
        _updateState();

        if (result.isLeft()) {
          _showRewardFailedDialog();
          return;
        }

        if (mounted) await _loadLimits();

        if (!mounted) return;
        context.read<AuthBloc>().add(const AuthRefreshUser());

        showDialog(
          context: context,
          builder: (ctx) => Material(
            type: MaterialType.transparency,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ModernGameDialog(
                  title: context.tr(
                    'store.magic_stars_earned_title',
                    fallback: 'MAGIC STARS EARNED!',
                  ),
                  description: context.tr(
                    'store.magic_stars_earned_desc',
                    fallback: 'You got +2 Magic Stars for watching the ad!',
                  ),
                  buttonText: context.tr('store.awesome', fallback: 'AWESOME'),
                  isSuccess: true,
                  onButtonPressed: () => Navigator.of(ctx).pop(),
                  customIcon: Icon(
                    Icons.auto_awesome_rounded,
                    color: const Color(0xFF10B981),
                    size: 48.sp,
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(child: GameConfetti()),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Safety timeout in case ad fails to load without dismissing
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isProcessing) {
        _isProcessing = false;
        _updateState();
      }
    });
  }

  @override
  void dispose() {
    _stateHash.dispose();
    super.dispose();
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
        final isPremium = user.isPremium;

        // Find next target
        int nextTierIndex = claimedTier;
        if (nextTierIndex >= _chestTiers.length) {
          nextTierIndex = _chestTiers.length - 1; // All claimed
        }
        final nextRequirement = _chestTiers[nextTierIndex];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: ValueListenableBuilder<int>(
            valueListenable: _stateHash,
            builder: (context, _, child) {
              return GestureDetector(
                onTap:
                    () {}, // Prevent taps on the sheet content from closing it
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: ScreenUtil().screenHeight * 0.85,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32.r),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: widget.primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 12.h),
                              Container(
                                width: 40.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_open_rounded,
                                    color: widget.primaryColor,
                                    size: 28.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    context.tr(
                                      'store.vault_title',
                                      fallback: 'Star Vault',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                context.tr(
                                  'store.vault_subtitle',
                                  fallback:
                                      'Collect stars to unlock massive rewards!',
                                ),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Progress
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 24.w),
                                padding: EdgeInsets.all(20.r),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: widget.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          context.tr(
                                            'store.your_stars',
                                            fallback: 'Your Stars',
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            Text(
                                              "$totalStars",
                                              style: TextStyle(
                                                fontSize: 32.sp,
                                                fontFamily: 'Outfit',
                                                fontWeight: FontWeight.w900,
                                                color: widget.primaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 4.w),
                                            Icon(
                                              Icons.star_rounded,
                                              color: const Color(0xFFFFD700),
                                              size: 28.sp,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 2,
                                      height: 40.h,
                                      color: widget.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          context.tr(
                                            'store.next_chest',
                                            fallback: 'Next Chest',
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            Text(
                                              "$nextRequirement",
                                              style: TextStyle(
                                                fontSize: 32.sp,
                                                fontFamily: 'Outfit',
                                                fontWeight: FontWeight.w900,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            SizedBox(width: 4.w),
                                            Icon(
                                              Icons.star_border_rounded,
                                              color: Colors.grey,
                                              size: 28.sp,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Progress toward next chest
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          context.tr(
                                            'store.progress_label',
                                            fallback: 'Progress',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          '$totalStars / $nextRequirement',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            color: widget.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: SizedBox(
                                        height: 10.h,
                                        child: LinearProgressIndicator(
                                          value: nextRequirement > 0
                                              ? (totalStars / nextRequirement)
                                                    .clamp(0.0, 1.0)
                                              : 0.0,
                                          backgroundColor: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                widget.primaryColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24.h),

                              // Chests ListView — auto-scrolls to the next claimable chest
                              SizedBox(
                                height: 160.h,
                                child: Builder(
                                  builder: (context) {
                                    // Each tile is 120.w wide + 16.w right margin = 136.w per tile.
                                    // Scroll so the "next" tile is centered in the viewport.
                                    final tileWidth = 120.w + 16.w;
                                    final viewportWidth =
                                        ScreenUtil().screenWidth -
                                        48.w; // minus horizontal padding
                                    final initialOffset =
                                        (nextTierIndex * tileWidth -
                                                viewportWidth / 2 +
                                                tileWidth / 2)
                                            .clamp(0.0, double.infinity);

                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      controller: ScrollController(
                                        initialScrollOffset: initialOffset,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24.w,
                                      ),
                                      itemCount: _chestTiers.length,
                                      itemBuilder: (context, index) {
                                        final requirement = _chestTiers[index];
                                        final isClaimed = claimedTier > index;
                                        final canClaim =
                                            !isClaimed &&
                                            totalStars >= requirement;
                                        final isNext = index == nextTierIndex;

                                        // FIX (ACCESSIBILITY): these 100 chest tiles
                                        // previously relied on ScaleButton's generic
                                        // `Semantics(button: true)` with no label, so a
                                        // screen reader user heard nothing but "button"
                                        // repeated 100 times with zero indication of
                                        // star requirement or claimed/available/locked
                                        // status. Explicit descriptive label added.
                                        final String semanticLabel = isClaimed
                                            ? context.tr(
                                                'store.chest_claimed_semantic',
                                                args: ['$requirement'],
                                                fallback:
                                                    'Chest requiring $requirement stars, already opened',
                                              )
                                            : canClaim
                                            ? context.tr(
                                                'store.chest_claimable_semantic',
                                                args: ['$requirement'],
                                                fallback:
                                                    'Chest requiring $requirement stars, ready to open',
                                              )
                                            : context.tr(
                                                'store.chest_locked_semantic',
                                                args: [
                                                  '$requirement',
                                                  '${requirement - totalStars}',
                                                ],
                                                fallback:
                                                    'Chest requiring $requirement stars, locked, ${requirement - totalStars} more needed',
                                              );

                                        return Semantics(
                                          button: true,
                                          label: semanticLabel,
                                          child: ScaleButton(
                                            onTap: () {
                                              if (canClaim) {
                                                _claimChest(index, totalStars);
                                              } else if (isClaimed) {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => ModernGameDialog(
                                                    title: context.tr(
                                                      'store.already_claimed_title',
                                                      fallback:
                                                          'ALREADY CLAIMED',
                                                    ),
                                                    description: context.tr(
                                                      'store.already_claimed_desc',
                                                      fallback:
                                                          'You have already opened this chest!',
                                                    ),
                                                    buttonText: context.tr(
                                                      'store.ok',
                                                      fallback: 'OK',
                                                    ),
                                                    isSuccess: true,
                                                    onButtonPressed: () =>
                                                        Navigator.of(ctx).pop(),
                                                  ),
                                                );
                                              } else {
                                                final needed =
                                                    requirement - totalStars;
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => ModernGameDialog(
                                                    title: context.tr(
                                                      'store.not_enough_stars_title',
                                                      fallback:
                                                          'NOT ENOUGH STARS',
                                                    ),
                                                    description: context.tr(
                                                      'store.not_enough_stars_desc',
                                                      args: ['$needed'],
                                                      fallback:
                                                          'You need $needed more stars to open this chest!',
                                                    ),
                                                    buttonText: context.tr(
                                                      'games.keep_playing',
                                                      fallback: 'KEEP PLAYING',
                                                    ),
                                                    isSuccess: false,
                                                    onButtonPressed: () =>
                                                        Navigator.of(ctx).pop(),
                                                    customIcon: Icon(
                                                      Icons.star_border_rounded,
                                                      color: Colors.orange,
                                                      size: 48.sp,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              width: 120.w,
                                              margin: EdgeInsets.only(
                                                right: 16.w,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: canClaim
                                                    ? LinearGradient(
                                                        colors: [
                                                          widget.primaryColor,
                                                          widget.primaryColor
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      )
                                                    : null,
                                                color: canClaim
                                                    ? null
                                                    : (isClaimed
                                                          ? Colors.grey
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                )
                                                          : isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.02,
                                                                )),
                                                borderRadius:
                                                    BorderRadius.circular(24.r),
                                                border: Border.all(
                                                  color: isClaimed
                                                      ? Colors.transparent
                                                      : canClaim
                                                      ? Colors.white.withValues(
                                                          alpha: 0.5,
                                                        )
                                                      : isNext
                                                      ? widget.primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            )
                                                      : Colors.transparent,
                                                  width: canClaim ? 2 : 1,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                        isClaimed
                                                            ? Icons
                                                                  .inventory_2_rounded
                                                            : canClaim
                                                            ? Icons
                                                                  .redeem_rounded
                                                            : Icons
                                                                  .lock_rounded,
                                                        size: 44.sp,
                                                        color: isClaimed
                                                            ? Colors.grey
                                                            : canClaim
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade400,
                                                      )
                                                      .animate(
                                                        target: canClaim
                                                            ? 1
                                                            : 0,
                                                      )
                                                      .shake(
                                                        hz: 3,
                                                        duration: 1.5.seconds,
                                                      )
                                                      .then()
                                                      .shimmer(
                                                        duration: 1.seconds,
                                                        color: Colors.white,
                                                      ),
                                                  SizedBox(height: 8.h),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "$requirement",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 16.sp,
                                                          color: isClaimed
                                                              ? Colors.grey
                                                              : canClaim
                                                              ? Colors.white
                                                              : isDark
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.star_rounded,
                                                        size: 16.sp,
                                                        color: isClaimed
                                                            ? Colors.grey
                                                            : const Color(
                                                                0xFFFFD700,
                                                              ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (isClaimed) ...[
                                                    SizedBox(height: 6.h),
                                                    Text(
                                                      context.tr(
                                                        'store.chest_opened',
                                                        fallback: 'OPENED',
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 10.sp,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ] else if (canClaim) ...[
                                                    SizedBox(height: 6.h),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10.w,
                                                            vertical: 4.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        context.tr(
                                                          'store.chest_open',
                                                          fallback: 'OPEN',
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 10.sp,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: widget
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ); // itemBuilder return
                                      }, // itemBuilder callback
                                    ); // ListView.builder
                                  }, // Builder callback
                                ), // Builder
                              ), // SizedBox

                              SizedBox(height: 32.h),

                              // Magic Star Ad Button
                              if (claimedTier < _chestTiers.length &&
                                  totalStars < nextRequirement) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: ScaleButton(
                                    onTap: _watchAdForMagicStars,
                                    child: ShakeableWrapper(
                                      shakeCount: _outOfAdsShake,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFF6D28D9),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            24.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF8B5CF6,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: _isProcessing || _isLoadingLimits
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 24.sp,
                                                    height: 24.sp,
                                                    child:
                                                        const VowlButtonSpinner(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    context.tr(
                                                      'store.loading_ad',
                                                      fallback: 'Loading...',
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : _remainingClaims <= 0
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.lock_clock_rounded,
                                                    color: Colors.white70,
                                                    size: 24.sp,
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    context.tr(
                                                      'store.daily_limit_reached',
                                                      fallback:
                                                          'Daily Limit Reached',
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    isPremium
                                                        ? Icons
                                                              .auto_awesome_rounded
                                                        : Icons
                                                              .play_circle_filled_rounded,
                                                    color: Colors.white,
                                                    size: 24.sp,
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    isPremium
                                                        ? context.tr(
                                                            'store.claim_magic_stars',
                                                            fallback:
                                                                'Claim +2 Free Magic Stars',
                                                          )
                                                        : context.tr(
                                                            'store.watch_ad_magic_stars',
                                                            fallback:
                                                                'Watch Ad for +2 Magic Stars',
                                                          ),
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  _remainingClaims <= 0
                                      ? context.tr(
                                          'store.come_back_tomorrow',
                                          fallback:
                                              'Come back tomorrow for more free stars!',
                                        )
                                      : context.tr(
                                          'store.magic_stars_hint',
                                          fallback:
                                              'Magic Stars permanently count towards your total! ($_remainingClaims left today)',
                                        ),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],

                              SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom +
                                    24.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
