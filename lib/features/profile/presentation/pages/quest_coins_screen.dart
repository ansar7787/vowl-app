import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/ad_reward_card.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/hint_ad_card.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/hint_purchase_dialog.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';

class VowlCoinsScreen extends StatelessWidget {
  const VowlCoinsScreen({super.key});

  static const int _hintPackCost = 750;
  static const int _hintsPerPack = 5;
  static const int _bulkHintCost = 1000;
  static const int _bulkHintAmount = 10;
  static const int _singleHintCost = 200;
  static const int _singleHintAmount = 1;

  /// Formats a coin value with locale-aware grouping (e.g. 15000 → "15,000").
  static String _formatCoins(int value) =>
      NumberFormat.decimalPattern().format(value);

  /// Returns a human-readable relative time string ("Just now", "2h ago",
  /// "Yesterday", etc.) for recent transactions.
  static String _relativeTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return context.tr('time.just_now', fallback: 'Just now');
    }
    if (diff.inMinutes < 60) {
      return context.tr(
        'time.minutes_ago',
        fallback: '${diff.inMinutes}m ago',
        args: [diff.inMinutes.toString()],
      );
    }
    if (diff.inHours < 24) {
      return context.tr(
        'time.hours_ago',
        fallback: '${diff.inHours}h ago',
        args: [diff.inHours.toString()],
      );
    }
    if (diff.inDays == 1) {
      return context.tr('time.yesterday', fallback: 'Yesterday');
    }
    if (diff.inDays < 7) {
      return context.tr(
        'time.days_ago',
        fallback: '${diff.inDays}d ago',
        args: [diff.inDays.toString()],
      );
    }
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          return Stack(
            children: [
              const MeshGradientBackground(),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<AuthBloc>().add(const AuthReloadUser());
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  color: isDark ? Colors.white : const Color(0xFF10B981),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        toolbarHeight: 70.h,
                        automaticallyImplyLeading: false,
                        title: GlassTile(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32.r,
                                height: 32.r,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18.r,
                                  onPressed: () => context.pop(),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Vowl Treasury',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.paid_rounded,
                                      color: const Color(0xFF10B981),
                                      size: 14.r,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _formatCoins(user.coins),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Body Content ──
                      SliverPadding(
                        padding: EdgeInsets.all(24.r),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildCoinBalanceCard(context, user),
                            SizedBox(height: 32.h),
                            _buildActionSection(
                              context,
                              title: context.tr(
                                'economy.ways_to_earn',
                                fallback: 'Ways to Earn',
                              ),
                              items: [
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: context.tr(
                                      'economy.maintain_streak',
                                      fallback: 'Maintain Daily Streak',
                                    ),
                                    subtitle: context.tr(
                                      'economy.earn_up_to_coins',
                                      fallback: 'Earn up to 5,000+ coins',
                                    ),
                                    icon: Icons.local_fire_department_rounded,
                                    color: const Color(0xFFEF4444),
                                    onTap: () =>
                                        context.push(AppRouter.streakRoute),
                                  ),
                                ),
                                const AdRewardCard(margin: EdgeInsets.zero),
                                const HintAdCard(margin: EdgeInsets.zero),
                              ],
                            ),
                            SizedBox(height: 32.h),
                            _buildActionSection(
                              context,
                              title: context.tr(
                                'economy.where_to_spend',
                                fallback: 'Where to Spend',
                              ),
                              items: [
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: context.tr(
                                      'streak_boosters.title',
                                      fallback: 'Streak Boosters',
                                    ),
                                    subtitle: context.tr(
                                      'streak_boosters.subtitle',
                                      fallback: 'Buy freezes & XP multipliers',
                                    ),
                                    icon: Icons.bolt_rounded,
                                    color: const Color(0xFF8B5CF6),
                                    onTap: () =>
                                        context.push(AppRouter.streakRoute),
                                  ),
                                ),
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: context.tr(
                                      'adventure.title',
                                      fallback: 'Adventure Details',
                                    ),
                                    subtitle:
                                        'Buy Masteries, Scroll of Wisdom & more',
                                    icon: Icons.storefront_rounded,
                                    color: const Color(0xFF6366F1),
                                    onTap: () => context.push(
                                      AppRouter.adventureXPRoute,
                                    ),
                                  ),
                                ),
                                _buildHintStore(context, user),
                              ],
                            ),
                            SizedBox(height: 32.h),
                            _buildCoinHistory(context, user),
                            SizedBox(height: 48.h),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Hint Purchase ──
  void _purchaseHint(
    BuildContext context,
    UserEntity user,
    int cost,
    int amount,
  ) {
    HintPurchaseDialog.show(
      context: context,
      user: user,
      cost: cost,
      amount: amount,
      titleBuilder: (amount) => amount == 1
          ? context.tr('economy.unlock_hint_single', fallback: 'Unlock 1 Hint')
          : context.tr(
              'economy.unlock_hints_plural',
              fallback: 'Unlock $amount Hints',
              args: [amount.toString()],
            ),
      bodyBuilder: (cost, amount) => context.tr(
        'economy.purchase_confirm_body',
        fallback:
            'This will deduct ${_formatCoins(cost)} coins from your balance.',
        args: [_formatCoins(cost)],
      ),
      onConfirm: () {
        context.read<EconomyBloc>().add(
          EconomyPurchaseHintRequested(cost, hintAmount: amount),
        );
        di.sl<HapticService>().heavy(); // Premium haptic
        HintPurchaseDialog.showSuccessSnackbar(context, amount);
      },
    );
  }

  Widget _buildCoinBalanceCard(BuildContext context, UserEntity user) {
    final int coins = user.coins;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = const Color(0xFF10B981); // Emerald Green for adult coins

    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(28.r),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.15)
          : const Color(0xFFCBD5E1),
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.95),
      borderWidth: 1.5,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Animated Pulse Glow
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.08, 1.08),
                      duration: 3.seconds,
                      curve: Curves.easeInOut,
                    ),

                Container(
                  padding: EdgeInsets.all(28.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.monetization_on_rounded,
                    color: color,
                    size: 56.r,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr('economy.total_balance', fallback: 'TOTAL BALANCE'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 400.ms),
            SizedBox(height: 4.h),
            AutoSizeText(
              _formatCoins(coins),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.1,
                letterSpacing: -1,
              ),
              maxLines: 1,
              minFontSize: 24,
              textAlign: TextAlign.center,
            ).animate().scale(begin: const Offset(0.9, 0.9)),
            SizedBox(height: 8.h),
            _buildWeeklyEarnings(context, user, color),
            SizedBox(height: 20.h),
            _buildInventoryGlance(context, coins, user.hintCount),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryGlance(BuildContext context, int coins, int hints) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.15)
            : const Color(0xFF0F172A).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glanceItem(
            context,
            Icons.lightbulb_rounded,
            context.tr(
              'economy.hints_available',
              fallback: '$hints hints available',
              args: [hints.toString()],
            ),
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _glanceItem(
    BuildContext context,
    IconData icon,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 16.r),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : const Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 16.h),
        ...items.map((widget) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: widget,
          );
        }),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, _ActionItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: item.onTap,
      child: GlassTile(
        padding: EdgeInsets.all(16.r),
        borderRadius: BorderRadius.circular(24.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(item.icon, color: item.color, size: 24.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AutoSizeText(
                    item.subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    minFontSize: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }

  // ── Weekly Earnings Summary ──
  Widget _buildWeeklyEarnings(
    BuildContext context,
    UserEntity user,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sum earned coins from the past 7 days
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int weeklyEarned = 0;
    for (final txn in user.coinHistory) {
      final dateStr = txn['date'] as String?;
      final isEarned = txn['isEarned'] == true;
      if (dateStr == null || !isEarned) continue;
      try {
        final date = DateTime.parse(dateStr);
        if (date.isAfter(weekAgo)) {
          weeklyEarned += ((txn['amount'] as num?)?.toInt() ?? 0).abs();
        }
      } catch (_) {
        continue;
      }
    }

    if (weeklyEarned == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, color: accentColor, size: 14.r),
          SizedBox(width: 6.w),
          Text(
            context.tr(
              'economy.this_week_earnings',
              fallback: '+${_formatCoins(weeklyEarned)} this week',
              args: [_formatCoins(weeklyEarned)],
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hint Store (Grouped Comparison Card) ──
  Widget _buildHintStore(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final packs = [
      (
        name: context.tr('economy.hint_single', fallback: '1 Hint'),
        hints: _singleHintAmount,
        cost: _singleHintCost,
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFFFBBF24),
        isBest: false,
      ),
      (
        name: context.tr(
          'economy.hints_amount',
          fallback: '5 Hints',
          args: ['5'],
        ),
        hints: _hintsPerPack,
        cost: _hintPackCost,
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFF59E0B),
        isBest: false,
      ),
      (
        name: context.tr(
          'economy.hints_amount',
          fallback: '10 Hints',
          args: ['10'],
        ),
        hints: _bulkHintAmount,
        cost: _bulkHintCost,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFF59E0B),
        isBest: true,
      ),
    ];

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: const Color(0xFFF59E0B),
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                context.tr('economy.hint_store', fallback: 'Hint Store'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...packs.map((pack) {
            final canAfford = user.coins >= pack.cost;
            final perUnit = (pack.cost / pack.hints).round();

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: ScaleButton(
                onTap: canAfford
                    ? () => _purchaseHint(context, user, pack.cost, pack.hints)
                    : () {
                        di.sl<HapticService>().light();
                        CustomSnackBar.show(
                          context: context,
                          message: context.tr(
                            'economy.insufficient_coins',
                            fallback: 'Not enough coins',
                            args: ['${pack.cost}'],
                          ),
                          type: CustomSnackBarType.error,
                        );
                      },
                child: Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? pack.color.withValues(alpha: isDark ? 0.08 : 0.06)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: canAfford
                          ? pack.color.withValues(alpha: 0.2)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: pack.color.withValues(
                            alpha: canAfford ? 0.15 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          pack.icon,
                          color: canAfford
                              ? pack.color
                              : (isDark ? Colors.white24 : Colors.black26),
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pack.name,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: canAfford
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B))
                                        : (isDark
                                              ? Colors.white30
                                              : Colors.black26),
                                  ),
                                ),
                                if (pack.isBest) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      context.tr(
                                        'economy.best_value',
                                        fallback: 'BEST VALUE',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${_formatCoins(perUnit)} ${context.tr('economy.coins_per_hint', fallback: 'coins/hint')}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: canAfford
                                    ? (isDark
                                          ? Colors.white38
                                          : const Color(0xFF94A3B8))
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.black12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCoins(pack.cost),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: canAfford
                                  ? pack.color
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.black12),
                            ),
                          ),
                          if (!canAfford)
                            Text(
                              context.tr(
                                'economy.need_x_more',
                                fallback:
                                    'Need ${_formatCoins(pack.cost - user.coins)} more',
                                args: [_formatCoins(pack.cost - user.coins)],
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Coin History Ledger (Vision 2026) ──
  Widget _buildCoinHistory(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Take the 10 most recent transactions, but display them with the newest at the bottom
    final recentHistory = user.coinHistory.reversed
        .take(10)
        .toList()
        .reversed
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr('economy.coin_ledger', fallback: 'COIN LEDGER'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                context.tr(
                  'economy.recent_n',
                  fallback: 'RECENT ${recentHistory.length}',
                  args: [recentHistory.length.toString()],
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (recentHistory.isEmpty)
          GlassTile(
            padding: EdgeInsets.all(32.r),
            borderRadius: BorderRadius.circular(24.r),
            borderColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.08),
                    size: 48.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr(
                      'economy.no_transactions',
                      fallback: 'No Transactions Yet',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.tr(
                      'economy.earn_first_coins',
                      fallback: 'Complete a quest to earn your first coins!',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...recentHistory.asMap().entries.map((entry) {
            final idx = entry.key;
            final txn = entry.value;
            final isEarned =
                (txn['isEarned'] == true) ||
                (txn['amount'] != null && (txn['amount'] as num) > 0);
            final amount = (txn['amount'] as num?)?.toInt() ?? 0;
            // Read 'titleKey' (the current schema) with 'title' as legacy
            // fallback — older entries written before the titleKey migration
            // stored raw English in 'title'.
            final rawKey =
                (txn['titleKey'] as String?) ??
                (txn['title'] as String?) ??
                'Transaction';
            final title = _localizeTransactionKey(context, rawKey, txn);
            final dateStr = txn['date'] as String?;

            final color = isEarned
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444);

            String formattedDate = '';
            if (dateStr != null) {
              try {
                final date = DateTime.parse(dateStr);
                formattedDate = _relativeTime(context, date);
              } catch (_) {
                formattedDate = '';
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: GlassTile(
                blur: 0, // PERFORMANCE FIX: Disabled blur for list items
                padding: EdgeInsets.all(16.r),
                borderRadius: BorderRadius.circular(24.r),
                borderColor: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFCBD5E1),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.95),
                borderWidth: 1,
                child: Row(
                  children: [
                    // Status Icon with Neon Glow
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isEarned ? Icons.add_rounded : Icons.remove_rounded,
                        color: color,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Title and Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            title,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            minFontSize: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (formattedDate.isNotEmpty)
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF94A3B8),
                                letterSpacing: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Amount
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: color,
                            size: 14.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _formatCoins(amount.abs()),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (idx * 50).ms).fadeIn().slideX(begin: 0.05),
            );
          }),
      ],
    );
  }

  // ── Transaction key → human-readable title ─────────────────────────────
  /// Resolves a `titleKey` stored in Firestore's `coinHistory` to a
  /// user-facing localized string. Keys follow the `coin_history.*` pattern
  /// established in `_recordCoinHistory` across the repository layer.
  ///
  /// Legacy entries that pre-date the titleKey migration may contain raw
  /// English (e.g. 'Earned Coins') — those pass through unchanged.
  static String _localizeTransactionKey(
    BuildContext context,
    String rawKey,
    Map<String, dynamic> txn,
  ) {
    // Helper to extract params for interpolation.
    final params = txn['params'] as Map<String, dynamic>?;
    final gameType = params?['gameType'] as String? ?? '';
    final milestone = params?['milestone']?.toString() ?? '';

    switch (rawKey) {
      case 'coin_history.quest_reward':
        return context.tr(
          'coin_history.quest_reward',
          args: [gameType],
          fallback: 'Quest Reward${gameType.isNotEmpty ? ' – $gameType' : ''}',
        );
      case 'coin_history.ad_triple_reward':
        return context.tr(
          'coin_history.ad_triple_reward',
          fallback: 'Ad Triple Reward 🎬',
        );
      case 'coin_history.earned_coins':
        return context.tr(
          'coin_history.earned_coins',
          fallback: 'Earned Coins',
        );
      case 'coin_history.purchased_hint_pack':
        return context.tr(
          'coin_history.purchased_hint_pack',
          fallback: 'Purchased Hint Pack',
        );
      case 'coin_history.repaired_streak':
        return context.tr(
          'coin_history.repaired_streak',
          fallback: 'Repaired Streak 🔥',
        );
      case 'coin_history.purchased_streak_freeze':
        return context.tr(
          'coin_history.purchased_streak_freeze',
          fallback: 'Streak Freeze ❄️',
        );
      case 'coin_history.purchased_double_xp':
        return context.tr(
          'coin_history.purchased_double_xp',
          fallback: 'Double XP Boost ⚡',
        );
      case 'coin_history.purchased_permanent_xp_boost':
        return context.tr(
          'coin_history.purchased_permanent_xp_boost',
          fallback: 'Permanent XP Boost 🚀',
        );
      case 'coin_history.streak_milestone_reward':
        return context.tr(
          'coin_history.streak_milestone_reward',
          args: [milestone],
          fallback:
              'Streak Milestone${milestone.isNotEmpty ? ' ($milestone🔥)' : ''} 🏆',
        );
      case 'coin_history.level_milestone_reward':
        return context.tr(
          'coin_history.level_milestone_reward',
          args: [milestone],
          fallback:
              'Level Milestone${milestone.isNotEmpty ? ' (Lv.$milestone)' : ''} 🏆',
        );
      case 'coin_history.ad_reward':
        return context.tr('coin_history.ad_reward', fallback: 'Ad Reward 🎬');
      case 'coin_history.daily_gift':
        return context.tr('coin_history.daily_gift', fallback: 'Daily Gift 🎁');
      case 'coin_history.vip_gift':
        return context.tr('coin_history.vip_gift', fallback: 'VIP Gift ⭐');
      case 'coin_history.spin_reward':
        return context.tr(
          'coin_history.spin_reward',
          fallback: 'Spin Reward 🎰',
        );
      case 'coin_history.daily_chest':
        return context.tr(
          'coin_history.daily_chest',
          fallback: 'Daily Chest 🎁',
        );
      case 'coin_history.speaking_bonus':
        return context.tr(
          'coin_history.speaking_bonus',
          fallback: 'Speaking Bonus 🎤',
        );
      case 'coin_history.purchased_mascot':
        return context.tr(
          'coin_history.purchased_mascot',
          fallback: 'Purchased Mascot 🦉',
        );
      case 'coin_history.purchased_accessory':
        return context.tr(
          'coin_history.purchased_accessory',
          fallback: 'Purchased Accessory ✨',
        );
      case 'coin_history.purchased_golden_key':
        return context.tr(
          'coin_history.purchased_golden_key',
          fallback: 'Purchased Golden Key 🔑',
        );
      case 'coin_history.purchased_coin_pack':
        return context.tr(
          'coin_history.purchased_coin_pack',
          fallback: 'Purchased Coin Pack 💎',
        );
      default:
        // Legacy raw-English entries or unknown keys — display as-is.
        return rawKey;
    }
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
