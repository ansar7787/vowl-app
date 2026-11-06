import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/laurel_trophy_3d_artwork.dart';

/// World-class celebration dialog for weekly league champions (Ranks 1 to 10).
/// Features multi-color confetti bursts, glowing 3D trophies/medals,
/// sound & haptic feedback, prize breakdown cards (VIP days, coins, aura badges),
/// and one-tap social sharing.
class WeeklyLeagueChampionDialog extends StatefulWidget {
  final UserEntity user;
  final int rank;
  final int vipDays;
  final int coins;
  final String weekKey;
  final Future<void> Function() onClaim;

  const WeeklyLeagueChampionDialog({
    super.key,
    required this.user,
    required this.rank,
    required this.vipDays,
    required this.coins,
    required this.weekKey,
    required this.onClaim,
  });

  /// Displays the celebration dialog with smooth backdrop fade.
  static Future<void> show({
    required BuildContext context,
    required UserEntity user,
    required int rank,
    required int vipDays,
    required int coins,
    required String weekKey,
    required Future<void> Function() onClaim,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Weekly League Champion Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => WeeklyLeagueChampionDialog(
        user: user,
        rank: rank,
        vipDays: vipDays,
        coins: coins,
        weekKey: weekKey,
        onClaim: onClaim,
      ),
    );
  }

  @override
  State<WeeklyLeagueChampionDialog> createState() =>
      _WeeklyLeagueChampionDialogState();
}

class _WeeklyLeagueChampionDialogState extends State<WeeklyLeagueChampionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Trigger celebratory haptic feedback and fanfare on mount
    HapticFeedback.heavyImpact();
    if (di.sl.isRegistered<SoundService>()) {
      di.sl<SoundService>().playLevelComplete();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.rank) {
      case 1:
        return IllustrationColors.premiumGold;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.indigo500;
    }
  }

  String get _title {
    switch (widget.rank) {
      case 1:
        return context.tr(
          'leaderboard.champion_title_1',
          fallback: 'LEAGUE CHAMPION 👑',
        );
      case 2:
        return context.tr(
          'leaderboard.champion_title_2',
          fallback: 'SILVER RUNNER-UP 🥈',
        );
      case 3:
        return context.tr(
          'leaderboard.champion_title_3',
          fallback: 'BRONZE PODIUM 🥉',
        );
      default:
        return context.tr(
          'leaderboard.champion_title_top10',
          fallback: 'TOP 10 FINISHER 🎖️',
        );
    }
  }

  String get _subtitle {
    switch (widget.rank) {
      case 1:
        return context.tr(
          'leaderboard.champion_sub_1',
          fallback: 'You dominated the global weekly league at #1!',
        );
      case 2:
        return context.tr(
          'leaderboard.champion_sub_2',
          fallback: 'Outstanding sprint! You secured the 2nd podium position.',
        );
      case 3:
        return context.tr(
          'leaderboard.champion_sub_3',
          fallback: 'Spectacular effort! You took the bronze podium spot.',
        );
      default:
        return context.tr(
          'leaderboard.champion_sub_top10',
          fallback: 'You conquered the week and finished in the top 10 elite!',
        );
    }
  }

  Future<void> _handleClaim() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    HapticFeedback.mediumImpact();
    if (di.sl.isRegistered<SoundService>()) {
      di.sl<SoundService>().playCoinTally(count: 12);
    }

    try {
      await widget.onClaim();
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    final data = ShareCardData.fromRank(
      userName: widget.user.safeDisplayName,
      userPhotoUrl: widget.user.photoUrl,
      rank: widget.rank,
      totalXp: widget.user.totalExp,
      streak: widget.user.currentStreak,
      referralCode: widget.user.referralCode,
    );
    ShareCardPreviewModal.show(context: context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final cardBg = isMidnight
        ? const Color(0xFF090D16)
        : (isDark ? const Color(0xFF0F172A) : Colors.white);
    final borderColor = _accentColor.withValues(alpha: 0.35);

    final now = DateTime.now();
    final bool isCurrentlyVip =
        widget.user.isPremium &&
        widget.user.premiumExpiryDate != null &&
        widget.user.premiumExpiryDate!.isAfter(now);

    final DateTime? calculatedNewExpiry;
    if (widget.vipDays > 0) {
      if (isCurrentlyVip) {
        calculatedNewExpiry = widget.user.premiumExpiryDate!.add(
          Duration(days: widget.vipDays),
        );
      } else {
        calculatedNewExpiry = now.add(Duration(days: widget.vipDays));
      }
    } else {
      calculatedNewExpiry = null;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 24.h),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background Confetti Burst
          const Positioned.fill(
            child: IgnorePointer(child: GameConfetti(shouldPop: true)),
          ),

          // Main Modal Body
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 420.w, maxHeight: 680.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: borderColor, width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.cardSpacious, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18.r,
                            color: isDark ? Colors.white70 : AppColors.slate700,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // 3D Metallic Laurel Trophy / Medallion Artwork with Ambient Rotating Rays
                    LaurelTrophy3DArtwork(
                      rank: widget.rank,
                      size: 155,
                      rotationController: reduceMotion ? null : _rotationController,
                    ),

                    SizedBox(height: 16.h),

                    // Title
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: _accentColor,
                        letterSpacing: 1.1,
                      ),
                    ),

                    SizedBox(height: 6.h),

                    // Subtitle
                    Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Prize Cards Breakdown
                    if (widget.vipDays > 0) ...[
                      _buildRewardRow(
                        icon: LucideIcons.crown,
                        iconColor: IllustrationColors.premiumGold,
                        title: isCurrentlyVip
                            ? '+${widget.vipDays} Days VIP Extended!'
                            : '+${widget.vipDays} Days Full VIP Unlocked!',
                        subtitle: calculatedNewExpiry != null
                            ? 'Valid through ${DateFormat.yMMMd().format(calculatedNewExpiry.toLocal())}'
                            : 'All categories, unlimited energy & 2x XP',
                        isDark: isDark,
                      ),
                      SizedBox(height: 10.h),
                    ],

                    if (widget.coins > 0) ...[
                      _buildRewardRow(
                        icon: Icons.monetization_on_rounded,
                        iconColor: AppColors.amber500,
                        title: '+${widget.coins} Quest Coins',
                        subtitle:
                            'Added directly to your treasury for duels & hints',
                        isDark: isDark,
                      ),
                      SizedBox(height: 10.h),
                    ],

                    // Permanent / Weekly Flex Badge
                    _buildRewardRow(
                      icon: widget.rank == 1
                          ? LucideIcons.sparkles
                          : LucideIcons.medal,
                      iconColor: _accentColor,
                      title: widget.rank == 1
                          ? 'Golden Crown Avatar Aura'
                          : (widget.rank <= 3
                              ? 'Podium Laurels Profile Badge'
                              : 'Division Finisher Ribbons'),
                      subtitle: widget.rank == 1
                          ? 'Glows around your avatar in the league all week'
                          : 'Showcased across your global profile and arena',
                      isDark: isDark,
                    ),

                    SizedBox(height: 24.h),

                    // Primary Action: Claim & Celebrate
                    ScaleButton(
                      onTap: _isClaiming ? null : _handleClaim,
                      child: Container(
                        width: double.infinity,
                        height: 52.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentColor,
                              _accentColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isClaiming
                            ? SizedBox(
                                width: 22.r,
                                height: 22.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.checkCheck,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    context.tr(
                                      'leaderboard.claim_and_celebrate',
                                      fallback: 'Claim & Celebrate',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // Secondary Action: Share Victory
                    TextButton.icon(
                      onPressed: _handleShare,
                      icon: Icon(
                        LucideIcons.share2,
                        size: 16.r,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                      ),
                      label: Text(
                        context.tr(
                          'leaderboard.share_victory',
                          fallback: 'Share Victory Card',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

