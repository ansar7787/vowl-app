import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/theme/app_colors.dart';

class AdventureStoreSection extends StatelessWidget {
  final UserEntity user;

  const AdventureStoreSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offers = [
      {
        'title': context.tr(
          'adventure.streak_shield',
          fallback: 'Streak Shield',
        ),
        'desc': context.tr(
          'adventure.streak_shield_desc',
          fallback: 'Protects progress (+1 Freeze)',
        ),
        'cost': 150,
        'icon': Icons.shield_rounded,
        'color': AppColors.emerald500,
        'type': 'shield',
        'active': user.streakFreezes > 0,
        'activeText':
            '${user.streakFreezes} ${context.tr('adventure.active', fallback: 'ACTIVE')}',
      },
      {
        'title': context.tr('adventure.double_xp', fallback: 'Double XP'),
        'desc': context.tr(
          'adventure.double_xp_desc',
          fallback: '2x Multiplier (24hr active)',
        ),
        'cost': 300,
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF3B82F6),
        'type': 'warp',
        'active': user.isDoubleXPActive,
        'activeText':
            '2X ${context.tr('adventure.active', fallback: 'ACTIVE')}',
      },
      {
        'title': context.tr(
          'adventure.golden_scroll',
          fallback: 'Golden Scroll',
        ),
        'desc': context.tr(
          'adventure.golden_scroll_desc',
          fallback: 'Permanent 1.1x XP boost',
        ),
        'cost': 2000,
        'icon': Icons.auto_awesome,
        'color': AppColors.violet500,
        'type': 'scroll',
        'locked': user.level < 200 || !user.isPremium,
        'active': user.hasPermanentXPBoost,
        'activeText': context.tr('adventure.owned', fallback: 'OWNED'),
      },
    ];

    return BlocBuilder<ProgressionBloc, ProgressionState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header with coin balance ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'adventure.store_title',
                            fallback: 'POWER-UPS',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white38 : AppColors.slate500,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 4.r),
                        Text(
                          context.tr(
                            'adventure.store_subtitle',
                            fallback: 'Boost your progress',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassTile(
                    blur: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.r,
                      vertical: 6.r,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          size: 14.r,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 4.r),
                        Text(
                          NumberFormat('#,###').format(user.coins),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.r),

            // ── Store items ──
            SizedBox(
              height: 100.r,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 24.r),
                physics: const BouncingScrollPhysics(),
                itemCount: offers.length,
                separatorBuilder: (context, index) => SizedBox(width: 12.r),
                itemBuilder: (context, index) {
                  final item = offers[index];
                  final isLocked = item['locked'] as bool? ?? false;
                  final isCurrentlyActive = item['active'] == true;
                  final isProcessing =
                      state.isLoading && state.lastPurchaseType == item['type'];

                  return Semantics(
                    label:
                        '${item['title']}, ${isLocked
                            ? context.tr('adventure.locked', fallback: 'locked')
                            : isCurrentlyActive
                            ? item['activeText']
                            : '${item['cost']} ${context.tr('adventure.coins_label', fallback: 'coins')}'}',
                    child: Opacity(
                      opacity: isLocked ? 0.6 : 1.0,
                      child: ScaleButton(
                        onTap: () async {
                          if (isLocked) {
                            CustomSnackBar.show(
                              context: context,
                              message: context.tr(
                                'adventure.locked_requirement',
                                fallback: 'Requires Premium + Level 200',
                              ),
                              type: CustomSnackBarType.info,
                            );
                            return;
                          }

                          if (isCurrentlyActive) {
                            CustomSnackBar.show(
                              context: context,
                              message: item['type'] == 'shield'
                                  ? context.tr(
                                      'adventure.shield_already_active',
                                      fallback:
                                          'Streak Shield is already active!',
                                    )
                                  : context.tr(
                                      'adventure.boost_already_active',
                                      fallback: 'You already have this boost!',
                                    ),
                              type: CustomSnackBarType.info,
                            );
                            return;
                          }

                          final confirmed = await _showPurchaseConfirmation(
                            context,
                            title: item['title'] as String,
                            description: item['desc'] as String,
                            cost: item['cost'] as int,
                            currentBalance: user.coins,
                            icon: item['icon'] as IconData,
                            color: item['color'] as Color,
                          );

                          if (!confirmed || !context.mounted) return;

                          if (item['type'] == 'shield') {
                            context.read<ProgressionBloc>().add(
                              ProgressionPurchaseStreakFreezeRequested(
                                item['cost'] as int,
                              ),
                            );
                          } else if (item['type'] == 'warp') {
                            context.read<ProgressionBloc>().add(
                              ProgressionActivateDoubleXPRequested(
                                item['cost'] as int,
                              ),
                            );
                          } else if (item['type'] == 'scroll') {
                            context.read<ProgressionBloc>().add(
                              ProgressionPurchasePermanentXPBoostRequested(
                                item['cost'] as int,
                              ),
                            );
                          }
                        },
                        child: GlassTile(
                          blur: 0, // Performance: skip BackdropFilter in list
                          width: 200.r,
                          padding: EdgeInsets.all(12.r),
                          borderRadius: BorderRadius.circular(24.r),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: (item['color'] as Color).withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: isProcessing
                                    ? SizedBox(
                                        width: 20.r,
                                        height: 20.r,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: item['color'] as Color,
                                        ),
                                      )
                                    : Icon(
                                        item['icon'] as IconData,
                                        size: 20.r,
                                        color: item['color'] as Color,
                                      ),
                              ),
                              SizedBox(width: 12.r),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.slate900,
                                      ),
                                    ),
                                    Text(
                                      isLocked
                                          ? context.tr(
                                              'adventure.locked_premium_200',
                                              fallback: 'Premium + Lvl 200',
                                            )
                                          : isCurrentlyActive
                                          ? (item['activeText'] as String? ??
                                                context.tr(
                                                  'adventure.item_active',
                                                  fallback: 'ITEM ACTIVE',
                                                ))
                                          : '${item['cost']} ${context.tr('adventure.coins_label', fallback: 'Coins')}',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isLocked
                                            ? Colors.red.withValues(alpha: 0.7)
                                            : isCurrentlyActive
                                            ? AppColors.amber500
                                            : AppColors.emerald500,
                                      ),
                                    ),
                                    SizedBox(height: 2.r),
                                    Text(
                                      item['desc'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showPurchaseConfirmation(
    BuildContext context, {
    required String title,
    required String description,
    required int cost,
    required int currentBalance,
    required IconData icon,
    required Color color,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAfford = currentBalance >= cost;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassTile(
          padding: EdgeInsets.all(24.r),
          borderRadius: BorderRadius.circular(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32.r, color: color),
              ),
              SizedBox(height: 16.r),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              SizedBox(height: 8.r),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              SizedBox(height: 24.r),
              // ── Cost ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 20.r,
                    color: AppColors.amber500,
                  ),
                  SizedBox(width: 6.r),
                  Text(
                    NumberFormat('#,###').format(cost),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: canAfford ? AppColors.amber500 : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.r),
              Text(
                context.tr(
                  'adventure.your_balance',
                  args: [NumberFormat('#,###').format(currentBalance)],
                  fallback:
                      'Balance: ${NumberFormat('#,###').format(currentBalance)}',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              if (!canAfford) ...[
                SizedBox(height: 8.r),
                Text(
                  context.tr(
                    'adventure.insufficient_coins',
                    fallback: 'Not enough coins!',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ],
              SizedBox(height: 24.r),
              // ── Action buttons ──
              Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Text(
                            context.tr('adventure.cancel', fallback: 'Cancel'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.r),
                  Expanded(
                    child: ScaleButton(
                      onTap: canAfford
                          ? () => Navigator.of(dialogContext).pop(true)
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.r),
                        decoration: BoxDecoration(
                          gradient: canAfford
                              ? LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.8)],
                                )
                              : null,
                          color: canAfford
                              ? null
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Text(
                            context.tr(
                              'adventure.purchase',
                              fallback: 'Purchase',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
