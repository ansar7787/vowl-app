import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Star vault milestone bottom sheet celebrating mastery milestones and awarding surprise rewards.
class KidsStarVaultBottomSheet extends StatefulWidget {
  /// The game type identifier.
  final String gameType;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsStarVaultBottomSheet] widget.
  const KidsStarVaultBottomSheet({
    super.key,
    required this.gameType,
    required this.primaryColor,
  });

  /// Displays the [KidsStarVaultBottomSheet] modal.
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
      builder: (ctx) => KidsStarVaultBottomSheet(
        gameType: gameType,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<KidsStarVaultBottomSheet> createState() =>
      _KidsStarVaultBottomSheetState();
}

class _KidsStarVaultBottomSheetState extends State<KidsStarVaultBottomSheet> {
  // Extended chest tiers up to 3000+ stars to account for Ad watches!
  static final List<int> _chestTiers = List.generate(100, (index) {
    if (index < 10) return 15 + (index * 15);
    return 150 + ((index - 9) * 30);
  });
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  @override
  void dispose() {
    _isProcessing.dispose();
    super.dispose();
  }

  ({int totalStars, int gameplayStars, int magicStars}) _calculateStars(
    Map<String, dynamic> categoryStars,
  ) {
    int gameplayStars = 0;
    final magicStars = (categoryStars['magic_stars'] as num?)?.toInt() ?? 0;

    categoryStars.forEach((key, value) {
      if (key != 'magic_stars' && key != 'claimed_chests') {
        gameplayStars += (value as num?)?.toInt() ?? 0;
      }
    });
    return (
      totalStars: gameplayStars + magicStars,
      gameplayStars: gameplayStars,
      magicStars: magicStars,
    );
  }

  Future<void> _claimChest(int tierIndex, int currentStars) async {
    if (_isProcessing.value) return;
    final requirement = _chestTiers[tierIndex];
    if (currentStars < requirement) return;

    _isProcessing.value = true;

    final updateUserRewards = di.sl<UpdateUserRewards>();

    final random = math.Random();
    // Balanced game economy: Moderate rewards to protect IAP revenue
    final baseReward = 15 + (tierIndex * 5);
    final variance = 5 + (tierIndex * 2);
    final int coinReward = baseReward + random.nextInt(variance + 1);

    final result = await updateUserRewards(
      UpdateUserRewardsParams(
        gameType: widget.gameType,
        level: 1, // Dummy level for vault
        xpIncrease: 0,
        coinIncrease:
            coinReward, // Will automatically route to kidsCoins inside repo
        claimChestTier: tierIndex + 1,
        isVaultReward: true,
      ),
    );

    if (!mounted) return;

    if (result.isLeft()) {
      _isProcessing.value = false;
      showDialog(
        context: context,
        builder: (ctx) => ModernGameDialog(
          title: context.tr('store.reward_failed', fallback: 'REWARD FAILED'),
          description: context.tr(
            'store.reward_failed_desc',
            fallback:
                "We couldn't grant your reward. Please contact support if this keeps happening.",
          ),
          buttonText: context.tr('common.ok', fallback: 'OK'),
          isSuccess: false,
          onButtonPressed: () => Navigator.of(ctx).pop(),
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(const AuthRefreshUser());

    _isProcessing.value = false;

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
                'store.chest_unlocked_desc',
                args: [coinReward.toString()],
                fallback: 'You found +$coinReward Toys in the magical chest!',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) return const SizedBox.shrink();

        final categoryStars = user.starRatings[widget.gameType] ?? {};
        final starsData = _calculateStars(categoryStars);
        final totalStars = starsData.totalStars;
        final gameplayStars = starsData.gameplayStars;
        final magicStars = starsData.magicStars;
        final claimedTier = categoryStars['claimed_chests'] ?? 0;

        int nextTierIndex = claimedTier;
        if (nextTierIndex >= _chestTiers.length) {
          nextTierIndex = _chestTiers.length - 1;
        }
        final nextRequirement = _chestTiers[nextTierIndex];

        return ListenableBuilder(
          listenable: _isProcessing,
          builder: (context, _) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
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
                              color:
                                  (isDark ? AppColors.slate800 : Colors.white)
                                      .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(40.r),
                              ),
                              border: Border.all(
                                color: widget.primaryColor,
                                width: 4.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.primaryColor.withValues(
                                    alpha: 0.6,
                                  ),
                                  offset: Offset(0, -6.h),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 12.h),
                                  Container(
                                    width: 50.w,
                                    height: 6.h,
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  ),
                                  SizedBox(height: 24.h),

                                  // Header
                                  Container(
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: widget.primaryColor,
                                      size: 48.sp,
                                    ),
                                  ).animate().scale(
                                    curve: Curves.elasticOut,
                                    duration: 800.ms,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    context.tr(
                                      'kids_zone.magical_star_vault',
                                      fallback: "Magical Star Vault",
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.w900,
                                      color: widget.primaryColor,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    context.tr(
                                      'kids_zone.collect_stars_desc',
                                      fallback:
                                          "Collect stars to unlock magical toys!",
                                    ),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),

                                  // Progress
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                    ),
                                    padding: EdgeInsets.all(20.r),
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(30.r),
                                      border: Border.all(
                                        color: widget.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 3.r,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                context.tr(
                                                  'store.vault_stars',
                                                  fallback: "Vault Stars",
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "$totalStars",
                                                    style: TextStyle(
                                                      fontSize: 36.sp,
                                                      fontFamily: 'Outfit',
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color:
                                                          widget.primaryColor,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Icon(
                                                    Icons.star_rounded,
                                                    color: const Color(
                                                      0xFFFFD700,
                                                    ),
                                                    size: 32.sp,
                                                  ),
                                                ],
                                              ),
                                              if (magicStars > 0) ...[
                                                SizedBox(height: 4.h),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8.w,
                                                    vertical: 2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: widget.primaryColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      '$gameplayStars Game + $magicStars Bonus',
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 10.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            widget.primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 3.w,
                                          height: 50.h,
                                          color: widget.primaryColor.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                context.tr(
                                                  'store.next_chest',
                                                  fallback: "Next Chest",
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "$nextRequirement",
                                                    style: TextStyle(
                                                      fontSize: 36.sp,
                                                      fontFamily: 'Outfit',
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Icon(
                                                    Icons.star_border_rounded,
                                                    color: Colors.grey,
                                                    size: 32.sp,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 32.h),

                                  // Chests ListView
                                  SizedBox(
                                    height: 170.h,
                                    child: Builder(
                                      builder: (context) {
                                        final tileWidth = 130.w + 16.w;
                                        final viewportWidth =
                                            ScreenUtil().screenWidth - 48.w;
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
                                            final requirement =
                                                _chestTiers[index];
                                            final isClaimed =
                                                claimedTier > index;
                                            final canClaim =
                                                !isClaimed &&
                                                totalStars >= requirement;
                                            final isNext =
                                                index == nextTierIndex;

                                            return Semantics(
                                              button: true,
                                              label: isClaimed
                                                  ? context.tr(
                                                      'store.chest_opened_label',
                                                      args: [
                                                        requirement.toString(),
                                                      ],
                                                      fallback:
                                                          'Chest at $requirement stars, already opened',
                                                    )
                                                  : canClaim
                                                  ? context.tr(
                                                      'store.chest_claim_label',
                                                      args: [
                                                        requirement.toString(),
                                                      ],
                                                      fallback:
                                                          'Open chest at $requirement stars',
                                                    )
                                                  : context.tr(
                                                      'store.chest_locked_label',
                                                      args: [
                                                        requirement.toString(),
                                                      ],
                                                      fallback:
                                                          'Chest at $requirement stars, locked',
                                                    ),
                                              child: ScaleButton(
                                                onTap: () {
                                                  if (canClaim) {
                                                    _claimChest(
                                                      index,
                                                      totalStars,
                                                    );
                                                  } else if (isClaimed) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (ctx) => ModernGameDialog(
                                                        title: context.tr(
                                                          'store.already_claimed',
                                                          fallback:
                                                              'ALREADY CLAIMED',
                                                        ),
                                                        description: context.tr(
                                                          'store.already_claimed_desc',
                                                          fallback:
                                                              'You have already opened this chest!',
                                                        ),
                                                        buttonText: context.tr(
                                                          'common.ok',
                                                          fallback: 'OK',
                                                        ),
                                                        isSuccess: true,
                                                        onButtonPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(),
                                                      ),
                                                    );
                                                  } else {
                                                    final needed =
                                                        requirement -
                                                        totalStars;
                                                    showDialog(
                                                      context: context,
                                                      builder: (ctx) => ModernGameDialog(
                                                        title: context.tr(
                                                          'store.not_enough_stars',
                                                          fallback:
                                                              'NOT ENOUGH STARS',
                                                        ),
                                                        description: context.tr(
                                                          'store.need_more_stars',
                                                          args: [
                                                            needed.toString(),
                                                          ],
                                                          fallback:
                                                              'You need $needed more stars to open this chest!',
                                                        ),
                                                        buttonText: context.tr(
                                                          'store.keep_playing',
                                                          fallback:
                                                              'KEEP PLAYING',
                                                        ),
                                                        isSuccess: false,
                                                        onButtonPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(),
                                                        customIcon: Icon(
                                                          Icons
                                                              .star_border_rounded,
                                                          color: Colors.orange,
                                                          size: 48.sp,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  width: 130.w,
                                                  margin: EdgeInsets.only(
                                                    right: 16.w,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: canClaim
                                                        ? LinearGradient(
                                                            colors: [
                                                              widget
                                                                  .primaryColor,
                                                              widget
                                                                  .primaryColor
                                                                  .withValues(
                                                                    alpha: 0.7,
                                                                  ),
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          )
                                                        : null,
                                                    color: canClaim
                                                        ? null
                                                        : (isClaimed
                                                              ? Colors.grey
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )
                                                              : isDark
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    )
                                                              : Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.02,
                                                                    )),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30.r,
                                                        ),
                                                    border: Border.all(
                                                      color: isClaimed
                                                          ? Colors.transparent
                                                          : canClaim
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                )
                                                          : isNext
                                                          ? widget.primaryColor
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                )
                                                          : Colors.transparent,
                                                      width: canClaim
                                                          ? 4.r
                                                          : 2.r,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
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
                                                            size: 52.sp,
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
                                                            duration:
                                                                1.5.seconds,
                                                          )
                                                          .then()
                                                          .shimmer(
                                                            duration: 1.seconds,
                                                            color: Colors.white,
                                                          ),
                                                      SizedBox(height: 12.h),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "$requirement",
                                                            style: TextStyle(
                                                              fontSize: 18.sp,
                                                              fontFamily:
                                                                  'Outfit',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color: isClaimed
                                                                  ? Colors.grey
                                                                  : canClaim
                                                                  ? Colors.white
                                                                  : isDark
                                                                  ? Colors
                                                                        .white70
                                                                  : Colors
                                                                        .black87,
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.star_rounded,
                                                            size: 18.sp,
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
                                                            fallback: "OPENED",
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 12.sp,
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
                                                                horizontal:
                                                                    12.w,
                                                                vertical: 4.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16.r,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            context.tr(
                                                              'store.chest_open',
                                                              fallback: "OPEN",
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
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
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).padding.bottom +
                                        24.h,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
