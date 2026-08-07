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
import 'package:auto_size_text/auto_size_text.dart';

class VowlCoinsScreen extends StatelessWidget {
  const VowlCoinsScreen({super.key});

  static const int _hintPackCost = 5000;
  static const int _hintsPerPack = 5;
  static const int _bulkHintCost = 20000;
  static const int _bulkHintAmount = 25;
  static const int _singleHintCost = 1500;
  static const int _singleHintAmount = 1;

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
                                      '${user.coins}',
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
                              title: 'WAYS TO EARN',
                              items: [
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: 'Maintain Daily Streak',
                                    subtitle: 'Earn up to 5,000+ coins',
                                    icon: Icons.local_fire_department_rounded,
                                    color: const Color(0xFFEF4444),
                                    onTap: () =>
                                        context.push(AppRouter.streakRoute),
                                  ),
                                ),

                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: 'Watch Rewarded Ads',
                                    subtitle: 'Earn 20 coins instantly',
                                    icon: Icons.play_circle_filled_rounded,
                                    color: Theme.of(context).primaryColor,
                                    onTap: () {},
                                    isAdPlaceholder: true,
                                  ),
                                ),
                                const HintAdCard(margin: EdgeInsets.zero),
                              ],
                            ),
                            SizedBox(height: 32.h),
                            _buildActionSection(
                              context,
                              title: 'WHERE TO SPEND',
                              items: [
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: 'Streak Boosters',
                                    subtitle: 'Buy freezes & XP multipliers',
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
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: 'Single Hint',
                                    subtitle:
                                        'Buy 1 hint for $_singleHintCost coins',
                                    icon: Icons.lightbulb_outline_rounded,
                                    color: const Color(0xFFFBBF24),
                                    onTap: () => _purchaseHint(
                                      context,
                                      user,
                                      _singleHintCost,
                                      _singleHintAmount,
                                    ),
                                  ),
                                ),
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: 'Elite Hint Pack',
                                    subtitle:
                                        'Get $_hintsPerPack hints for $_hintPackCost coins',
                                    icon: Icons.lightbulb_rounded,
                                    color: const Color(0xFFF59E0B),
                                    onTap: () => _purchaseHint(
                                      context,
                                      user,
                                      _hintPackCost,
                                      _hintsPerPack,
                                    ),
                                  ),
                                ),
                                _buildActionItem(
                                  context,
                                  _ActionItem(
                                    title: 'Legendary Hint Pack',
                                    subtitle:
                                        'Get $_bulkHintAmount hints for $_bulkHintCost coins',
                                    icon: Icons.auto_awesome_rounded,
                                    color: Theme.of(context).primaryColor,
                                    onTap: () => _purchaseHint(
                                      context,
                                      user,
                                      _bulkHintCost,
                                      _bulkHintAmount,
                                    ),
                                  ),
                                ),
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
      titleBuilder: (amount) => amount > 1
          ? context.tr('adventure.hint_pack_elite', fallback: 'Elite Hint Pack')
          : context.tr(
              'adventure.hint_pack_strategic_singular',
              fallback: 'Strategic Hint Pack',
            ),
      bodyBuilder: (cost, amount) => context.tr(
        'adventure.hint_pack_exchange_body_with_hint',
        fallback: 'Trade coins for hints.',
        args: ['$cost', '$amount'],
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
      borderRadius: BorderRadius.circular(40.r),
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
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 2.seconds,
                      curve: Curves.easeInOut,
                    )
                    .fadeOut(duration: 2.seconds),

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
              "TOTAL BALANCE",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 3,
              ),
            ).animate().fadeIn(delay: 400.ms),
            SizedBox(height: 4.h),
            Text(
              "$coins",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.1,
                letterSpacing: -1,
              ),
              textAlign: TextAlign.center,
            ).animate().scale(begin: const Offset(0.9, 0.9)),
            Text(
              "VOWL COINS",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white24 : Colors.black26,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _buildInventoryGlance(context, coins, user.hintCount),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryGlance(BuildContext context, int coins, int hints) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glanceItem(
            Icons.lightbulb_rounded,
            "$hints HINTS AVAILABLE",
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _glanceItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16.r),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
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
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : const Color(0xFF64748B),
            letterSpacing: 1.5,
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
    if (item.isAdPlaceholder) {
      return const AdRewardCard(margin: EdgeInsets.zero);
    }
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
              'COIN LEDGER',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white38 : const Color(0xFF64748B),
                letterSpacing: 2,
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
                'RECENT 10',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w900,
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
            borderRadius: BorderRadius.circular(32.r),
            borderColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    size: 48.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Data Streams',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'Your transactions will appear here.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
                    ),
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
                formattedDate = DateFormat(
                  'MMM d • h:mm a',
                ).format(date).toUpperCase();
              } catch (_) {
                formattedDate = '';
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: GlassTile(
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
                            '${amount.abs()}',
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
  final bool isAdPlaceholder;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isAdPlaceholder = false,
  });
}
