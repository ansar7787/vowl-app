import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

/// An elegant, non-intrusive inline card on the Home dashboard for claiming
/// the daily mystery chest. Replaces the old blocking modal popup.
///
/// Features:
/// - Vector gift and sparkles icons (no emojis).
/// - Emerald-green celebratory confetti burst upon claim.
/// - Synced tactile haptics & rapid coin-tally audio effect.
/// - Dual `SizeTransition` + `ScaleTransition` "eating" collapse animation
///   that smoothly folds the card to 0dp height once claimed.
class DailyMysteryChestCard extends StatefulWidget {
  final void Function({required Offset originOffset, required int coins})? onClaimed;

  const DailyMysteryChestCard({
    super.key,
    this.onClaimed,
  });

  @override
  State<DailyMysteryChestCard> createState() => _DailyMysteryChestCardState();
}

class _DailyMysteryChestCardState extends State<DailyMysteryChestCard>
    with TickerProviderStateMixin {
  late final AnimationController _collapseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _sizeAnimation;

  bool _isClaimedLocally = false;
  bool _isClaiming = false;
  int? _awardedCoins;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _sizeAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _verifyLocalClaimStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.read<AuthBloc>().state.user?.id;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _isClaimedLocally = false;
      _verifyLocalClaimStatus();
    }
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  Future<void> _verifyLocalClaimStatus() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowLocal = DateTime.now().toLocal();
      final todayStr =
          '${nowLocal.year}-${nowLocal.month.toString().padLeft(2, '0')}-${nowLocal.day.toString().padLeft(2, '0')}';

      final localDate = prefs.getString('last_daily_mystery_claimed_date');
      final userDate = userId != null && userId.isNotEmpty
          ? prefs.getString('last_daily_mystery_claimed_date_$userId')
          : null;

      final alreadyClaimed = userId != null && userId.isNotEmpty
          ? userDate == todayStr
          : localDate == todayStr;

      if (mounted && alreadyClaimed) {
        setState(() => _isClaimedLocally = true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyMysteryChestCard: local check failed: $e');
      }
    }
  }

  Future<void> _handleClaim() async {
    if (_isClaiming || _isClaimedLocally) return;
    setState(() => _isClaiming = true);

    // 1. Roll rewards
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    final roll = math.Random().nextDouble();
    int totalCoins;
    if (roll < 0.05) {
      totalCoins = math.Random().nextInt(20) + 31; // 5%: 31-50 coins (jackpot)
    } else if (roll < 0.30) {
      totalCoins = math.Random().nextInt(15) + 16; // 25%: 16-30 coins
    } else {
      totalCoins = math.Random().nextInt(11) + 5; // 70%: 5-15 coins
    }
    if (isPremium) {
      totalCoins = totalCoins * 3 + math.Random().nextInt(30);
    }

    setState(() => _awardedCoins = totalCoins);

    // 2. Tactile celebration (Haptics & Audio)
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCoinTally(count: 8);
      }
    } catch (_) {}

    // 3. Trigger screen-level unclipped confetti & luxury flying coins
    if (widget.onClaimed != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      final origin = (renderBox != null && renderBox.hasSize)
          ? renderBox.localToGlobal(renderBox.size.center(Offset.zero))
          : Offset(1.sw * 0.5, 1.sh * 0.28);
      widget.onClaimed!(originOffset: origin, coins: totalCoins);
    }

    // 4. Dispatch claim to Firestore via EconomyBloc
    final currentUser = context.read<AuthBloc>().state.user;
    final userId = currentUser?.id;
    context.read<EconomyBloc>().add(
      EconomyClaimDailyChestRequested(totalCoins),
    );

    // 5. Persist claim date locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowLocal = DateTime.now().toLocal();
      final todayStr =
          '${nowLocal.year}-${nowLocal.month.toString().padLeft(2, '0')}-${nowLocal.day.toString().padLeft(2, '0')}';
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString(
          'last_daily_mystery_claimed_date_$userId',
          todayStr,
        );
      }
      await prefs.setString('last_daily_mystery_claimed_date', todayStr);
    } catch (_) {}

    // 6. Hold victory state while coins arrive at top bar, then execute smooth collapse
    await Future.delayed(const Duration(milliseconds: 1150));
    if (!mounted) return;

    await _collapseController.forward();
    if (mounted) {
      setState(() => _isClaimedLocally = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRewardAvailable = context.select<EconomyBloc, bool>(
      (bloc) => bloc.state.isDailyRewardAvailable,
    );

    // If already claimed locally, or if reward is unavailable and not actively claiming,
    // collapse to SizedBox.shrink().
    if (_isClaimedLocally || (!isRewardAvailable && !_isClaiming)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    // Main Card Widget wrapped in Semantics for accessibility
    Widget cardContent = Semantics(
      button: true,
      label: _awardedCoins != null
          ? context.tr('home.chest_coins_collected', fallback: 'Coins collected')
          : '${context.tr('home.chest_daily_mystery', fallback: 'Daily mystery')}, ${context.tr('home.chest_tap_unveil', fallback: 'Tap to unveil')}',
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isMidnight
              ? AppColors.midnightSurface
              : (isDark ? const Color(0xFF131A29) : Colors.white),
          gradient: isDark
              ? LinearGradient(
                  colors: isMidnight
                      ? const [Color(0xFF0B0F19), Color(0xFF060910)]
                      : const [Color(0xFF161F33), Color(0xFF0F1524)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isMidnight
                ? Colors.white.withValues(alpha: 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.slate100),
            width: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Subtle warm glow accent along the left edge
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3.5.r,
                decoration: BoxDecoration(
                  color: AppColors.amber500,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    bottomLeft: Radius.circular(20.r),
                  ),
                ),
              ),
            ),

            // Main horizontal capsule content with full-card tap recognition
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleClaim,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.cardCompact, vertical: 8.h),
                child: Row(
              children: [
                // Glowing circular gift badge
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.gift,
                      color: AppColors.amber500,
                      size: 16.r,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Title & Subtitle or Victory state
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              _awardedCoins != null
                                  ? context.tr(
                                      'home.chest_coins_collected',
                                      fallback: 'COINS COLLECTED',
                                    )
                                  : context.tr(
                                      'home.chest_daily_mystery',
                                      fallback: 'DAILY MYSTERY',
                                    ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              minFontSize: 9,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            LucideIcons.sparkles,
                            color: AppColors.amber500,
                            size: 11.r,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      AutoSizeText(
                        _awardedCoins != null
                          ? '+$_awardedCoins ${context.tr('home.coins', fallback: 'COINS')}!'
                          : context.tr(
                              'home.chest_tap_unveil',
                              fallback: 'TAP TO UNVEIL',
                            ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: _awardedCoins != null
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _awardedCoins != null
                              ? AppColors.amber500
                              : (isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600),
                        ),
                        maxLines: 1,
                        minFontSize: 9,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Tactile Claim CTA
                ScaleButton(
                  onTap: _handleClaim,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          IllustrationColors.warmOrange,
                          AppColors.amber500,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber500.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _awardedCoins != null
                        ? Icon(
                            LucideIcons.check,
                            size: 14.r,
                            color: Colors.black,
                          )
                        : Text(
                            context.tr(
                              'streak.milestone_claim_cta',
                              fallback: 'CLAIM',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    ),
  );

    // Eating animation: smooth reverse SizeTransition (vertical shrink) + ScaleTransition
    Widget animatedCard = SizeTransition(
      sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(_sizeAnimation),
      axisAlignment: 0.0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, 14.h, AppSpacing.screen, 0),
          child: cardContent,
        ),
      ),
    );

    if (reduceMotion) {
      return animatedCard;
    }

    return animatedCard.animate().fadeIn(duration: 350.ms).slideY(begin: -0.04);
  }
}
