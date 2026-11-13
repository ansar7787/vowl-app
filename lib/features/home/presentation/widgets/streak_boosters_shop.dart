import 'package:flutter/material.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorff5f6d = Color(0xFFFF5F6D);
  static const Color color38bdf8 = Color(0xFF38BDF8);
  static const Color colorfcd34d = Color(0xFFFCD34D);
}

/// Streak shop section providing streak freezes, emergency repairs, and VIP perks.
class StreakBoostersShop extends StatefulWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Creates a [StreakBoostersShop] for [user].
  const StreakBoostersShop({super.key, required this.user});

  @override
  State<StreakBoostersShop> createState() => _StreakBoostersShopState();
}

class _StreakBoostersShopState extends State<StreakBoostersShop> {
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  @override
  void dispose() {
    _isProcessing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return BlocListener<ProgressionBloc, ProgressionState>(
      listenWhen: (prev, curr) => prev.message != curr.message,
      listener: (context, state) {
        final msg = state.message;
        if (msg == null) return;

        if (mounted) _isProcessing.value = false;

        if (msg.contains('insufficient') || msg.contains('error')) {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'streak.purchase_failed',
              fallback: 'Purchase failed. Please try again.',
            ),
            type: CustomSnackBarType.error,
          );
        } else if (msg == 'progression.streak_repaired' ||
            msg == 'progression.streak_shield_purchased' ||
            msg == 'progression.double_xp_activated') {
          // Determine the name based on the msg
          String name = 'Booster';
          if (msg == 'progression.streak_repaired') {
            name = context.tr(
              'adventure.streak_repair',
              fallback: 'Streak Repair',
            );
          } else if (msg == 'progression.streak_shield_purchased') {
            name = context.tr(
              'adventure.streak_shield',
              fallback: 'Streak Shield',
            );
          } else if (msg == 'progression.double_xp_activated') {
            name = context.tr('adventure.double_xp', fallback: 'Double XP');
          }

          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'streak.item_activated',
              args: [name],
              fallback: '$name Activated!',
            ),
            type: CustomSnackBarType.success,
          );
        }

        // Clear the message
        context.read<ProgressionBloc>().add(
          const ProgressionClearMessageRequested(),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AutoSizeText(
                  context.tr(
                    'streak.boosters_title',
                    fallback: 'STREAK BOOSTERS',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  minFontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Semantics(
                label: context.tr(
                  'home.coins_value_label',
                  args: [user.coins.toString()],
                  fallback: '${user.coins} coins',
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.circleDollarSign,
                          color: Colors.green,
                          size: 16.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${user.coins}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildShopItem(
            context,
            title: context.tr('streak.repair_title', fallback: 'STREAK REPAIR'),
            subtitle: user.currentStreak > 0
                ? context.tr(
                    'streak.repair_streak_active',
                    fallback:
                        'Your flame is burning! Only needed when streak is lost.',
                  )
                : (user.previousStreak > 0
                    ? context.tr(
                        'streak.repair_restore_prev',
                        args: [user.previousStreak.toString()],
                        fallback:
                            'Restore your lost ${user.previousStreak}-day flame from yesterday.',
                      )
                    : context.tr(
                        'streak.repair_no_broken',
                        fallback: 'No lost streak to repair.',
                      )),
            icon: LucideIcons.flame,
            color: _LocalPalette.colorff5f6d,
            cost: UserGameConstants.kStreakRepairCost,
            currentCoins: user.coins,
            isPremiumOnly: false,
            isUserPremium: user.isPremium,
            isDisabled: user.currentStreak > 0 || user.previousStreak == 0,
            onTap: (user.currentStreak > 0 || user.previousStreak == 0)
                ? null
                : () => _handlePurchase(
                      context,
                      name: context.tr(
                        'adventure.streak_repair',
                        fallback: 'Streak Repair',
                      ),
                      cost: UserGameConstants.kStreakRepairCost,
                      currentCoins: user.coins,
                      action: () => context.read<ProgressionBloc>().add(
                        const ProgressionRepairStreakRequested(
                          UserGameConstants.kStreakRepairCost,
                        ),
                      ),
                    ),
            onAdTap:
                null, // Rewarded ad / free coin bypass removed per production policy
          ),
          SizedBox(height: 16.h),
          _buildShopItem(
            context,
            title: context
                .tr('adventure.streak_shield', fallback: 'Streak Shield')
                .toUpperCase(),
            subtitle: user.streakFreezes >= UserGameConstants.kMaxStreakShields
                ? context.tr(
                    'streak.shield_max_reached',
                    fallback: 'Maximum capacity reached (2/2 shields).',
                  )
                : context.tr(
                    'streak.shield_subtitle',
                    fallback: 'A mystical barrier that prevents streak loss.',
                  ),
            icon: LucideIcons.shieldCheck,
            color: _LocalPalette.color38bdf8,
            cost: UserGameConstants.kStreakShieldCost,
            count: user.streakFreezes,
            currentCoins: user.coins,
            isDisabled:
                user.streakFreezes >= UserGameConstants.kMaxStreakShields,
            onTap: user.streakFreezes >= UserGameConstants.kMaxStreakShields
                ? null
                : () => _handlePurchase(
                      context,
                      name: context.tr(
                        'adventure.streak_shield',
                        fallback: 'Streak Shield',
                      ),
                      cost: UserGameConstants.kStreakShieldCost,
                      currentCoins: user.coins,
                      action: () => context.read<ProgressionBloc>().add(
                        const ProgressionPurchaseStreakFreezeRequested(
                          UserGameConstants.kStreakShieldCost,
                        ),
                      ),
                    ),
          ),
          SizedBox(height: 16.h),
          _buildShopItem(
            context,
            title: context
                .tr('adventure.double_xp', fallback: 'Double XP')
                .toUpperCase(),
            subtitle: context.tr(
              'streak.double_xp_subtitle',
              fallback: 'Double the wisdom, double the progress for 24h.',
            ),
            icon: LucideIcons.zap,
            color: _LocalPalette.colorfcd34d,
            cost: UserGameConstants.kDoubleXpCost,
            isActive: user.isDoubleXPActive,
            activeUntil: user.doubleXPExpiry,
            currentCoins: user.coins,
            onTap: () => _handlePurchase(
              context,
              name: context.tr('adventure.double_xp', fallback: 'Double XP'),
              cost: UserGameConstants.kDoubleXpCost,
              currentCoins: user.coins,
              action: () => context.read<ProgressionBloc>().add(
                const ProgressionActivateDoubleXPRequested(
                  UserGameConstants.kDoubleXpCost,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(
    BuildContext context, {
    required String name,
    required int cost,
    required int currentCoins,
    required VoidCallback action,
  }) {
    if (_isProcessing.value) return;

    if (currentCoins < cost) {
      try {
        Haptics.vibrate(HapticsType.error);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('StreakBoostersShop: haptics unavailable: $e');
        }
      }
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'streak.insufficient_coins',
          args: [cost.toString()],
          fallback: 'Insufficient Vowl Coins! Needed: $cost',
        ),
        type: CustomSnackBarType.error,
      );
      return;
    }

    // Show confirmation
    _showPurchaseConfirmation(
      context,
      name: name,
      cost: cost,
      currentCoins: currentCoins,
      action: action,
    );
  }

  void _showPurchaseConfirmation(
    BuildContext context, {
    required String name,
    required int cost,
    required int currentCoins,
    required VoidCallback action,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final systemBottomPadding = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final safeBottom =
            (systemBottomPadding > 0 ? systemBottomPadding : 24.h) +
            bottomInset +
            12.h;

        return Container(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, safeBottom),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.slate900.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                context.tr(
                  'streak.confirm_purchase_title',
                  fallback: 'Confirm Purchase',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr(
                  'streak.confirm_purchase_body',
                  args: [cost.toString(), name],
                  fallback: 'Spend $cost coins on $name?',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                context.tr(
                  'streak.confirm_balance_label',
                  args: [
                    currentCoins.toString(),
                    (currentCoins - cost).toString(),
                  ],
                  fallback:
                      'Balance: $currentCoins → ${currentCoins - cost} coins',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald500,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        context.tr('common.cancel', fallback: 'CANCEL'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _executePurchase(context, name: name, action: action);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo500,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        context.tr(
                          'streak.confirm_buy_button',
                          fallback: 'Buy',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _executePurchase(
    BuildContext context, {
    required String name,
    required VoidCallback action,
  }) {
    _isProcessing.value = true;
    try {
      Haptics.vibrate(HapticsType.heavy);
    } catch (e) {
      if (kDebugMode) debugPrint('StreakBoostersShop: haptics unavailable: $e');
    }
    action();

    // Note: _isProcessing is now cleared by the BlocListener when the response arrives,
    // with a fallback timeout below
    // and success/failure UI feedback is handled there.
    // Fallback timeout below in case no message is emitted:
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _isProcessing.value = false;
    });
  }

  Widget _buildShopItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int cost,
    required int currentCoins,
    required VoidCallback? onTap,
    VoidCallback? onAdTap,
    int? count,
    bool isActive = false,
    bool isDisabled = false,
    DateTime? activeUntil,
    bool isPremiumOnly = false,
    bool isUserPremium = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAfford = currentCoins >= cost;
    final locale = Localizations.localeOf(context).toString();

    final statusLabel = isDisabled
        ? context.tr('streak.status_not_needed', fallback: 'NOT NEEDED')
        : (isActive
              ? context.tr('streak.status_active', fallback: 'ACTIVE')
              : (isPremiumOnly && !isUserPremium
                    ? 'VIP ONLY'
                    : (isPremiumOnly && isUserPremium
                          ? 'FREE WITH VIP'
                          : (canAfford
                                ? context.tr(
                                    'streak.cost_label',
                                    args: [cost.toString()],
                                    fallback: '$cost coins',
                                  )
                                : context.tr(
                                    'streak.cant_afford_label',
                                    args: [cost.toString()],
                                    fallback: 'Need $cost coins',
                                  )))));

    return Semantics(
      button: !isDisabled && !isActive,
      enabled: !isDisabled,
      label: '$title, $subtitle, $statusLabel',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24.r),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: ExcludeSemantics(
            child: Builder(
              builder: (ctx) {
                final isMidnight =
                    isDark &&
                    Theme.of(ctx).scaffoldBackgroundColor == Colors.black;
                final cardBg = isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? AppColors.midnightNavy : Colors.white);
                final cardBorder = isMidnight
                    ? Colors.white.withValues(alpha: 0.12)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate200);

                return Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDisabled
                          ? (isDark ? Colors.white10 : AppColors.slate200)
                          : cardBorder,
                      width: 1.0,
                    ),
                    boxShadow: [
                      if (canAfford && !isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      !isDisabled
                          ? Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: color, size: 24.r),
                            )
                          : Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: Colors.grey, size: 24.r),
                            ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: AutoSizeText(
                                    title,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (count != null && count > 0) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'x$count',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isDisabled ? Colors.grey : color,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                                if (isActive || isDisabled) ...[
                                  SizedBox(width: 8.w),
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isActive
                                                    ? AppColors.emerald500
                                                    : Colors.grey)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: AutoSizeText(
                                        isActive
                                            ? context.tr(
                                                'streak.status_active',
                                                fallback: 'ACTIVE',
                                              )
                                            : context.tr(
                                                'streak.status_not_needed',
                                                fallback: 'NOT NEEDED',
                                              ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                          color: isActive
                                              ? AppColors.emerald500
                                              : Colors.grey,
                                        ),
                                        maxLines: 1,
                                        minFontSize: 6,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            AutoSizeText(
                              subtitle,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                color: isDisabled
                                    ? Colors.grey.withValues(alpha: 0.5)
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black54),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isActive && activeUntil != null) ...[
                              SizedBox(height: 4.h),
                              AutoSizeText(
                                context.tr(
                                  'streak.expires_label',
                                  args: [
                                    DateFormat(
                                      'MMM d, h:mm a',
                                      locale,
                                    ).format(activeUntil),
                                  ],
                                  fallback:
                                      'Expires ${DateFormat('MMM d, h:mm a', locale).format(activeUntil)}',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                minFontSize: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isDisabled && !isActive) ...[
                        SizedBox(width: 8.w),
                        if (isPremiumOnly && !isUserPremium)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.indigo500,
                                  AppColors.violet500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.indigo500.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.crown,
                                  color: Colors.white,
                                  size: 13.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'VIP',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isPremiumOnly && isUserPremium)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald500.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.emerald500.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  color: AppColors.emerald500,
                                  size: 13.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr(
                                    'streak.restore_label',
                                    fallback: 'RESTORE',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.emerald500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? color.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: canAfford
                                    ? color.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.circleDollarSign,
                                  color: canAfford ? color : Colors.red,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$cost',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    color: canAfford ? color : Colors.red,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (onAdTap != null && !isDisabled) ...[
                        SizedBox(width: 8.w),
                        Semantics(
                          button: true,
                          label: context.tr(
                            'streak.watch_ad_free',
                            fallback: 'Watch an ad to get this for free',
                          ),
                          child: InkWell(
                            onTap: onAdTap,
                            child: ExcludeSemantics(
                              child: ConstrainedBox(
                                // Visual pill is intentionally compact; this
                                // guarantees the 48dp minimum tap target for a
                                // real monetization action without resizing it.
                                constraints: BoxConstraints(
                                  minWidth: 48.r,
                                  minHeight: 48.r,
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.amber.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.playCircle,
                                        color: Colors.amber,
                                        size: 12.r,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr(
                                          'streak.free_label',
                                          fallback: 'FREE',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.amber,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
