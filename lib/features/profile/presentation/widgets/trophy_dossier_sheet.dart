import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/claim_badge_reward.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/domain/models/trophy_metadata.dart';
import 'package:vowl/features/profile/presentation/widgets/trophy_medallion_artwork.dart';
import 'package:vowl/features/social_share/services/social_share_rasterizer.dart';

/// Interactive modal sheet displaying in-depth achievement dossier,
/// real-time progress ladder, XP bounty, and high-DPI social sharing card.
class TrophyDossierSheet extends StatefulWidget {
  /// Achievement metadata.
  final TrophyMetadata metadata;

  /// Whether the badge has been unlocked.
  final bool isEarned;

  /// Authenticated user entity.
  final UserEntity? user;

  /// Whether this badge is currently pinned to the hero showcase.
  final bool isPinned;

  /// Callback when user toggles the showcase pin.
  final VoidCallback onTogglePin;

  const TrophyDossierSheet({
    super.key,
    required this.metadata,
    required this.isEarned,
    this.user,
    required this.isPinned,
    required this.onTogglePin,
  });

  /// Presents the [TrophyDossierSheet] modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required TrophyMetadata metadata,
    required bool isEarned,
    UserEntity? user,
    required bool isPinned,
    required VoidCallback onTogglePin,
  }) {
    Haptics.vibrate(metadata.isLegendary ? HapticsType.heavy : HapticsType.light);

    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrophyDossierSheet(
        metadata: metadata,
        isEarned: isEarned,
        user: user,
        isPinned: isPinned,
        onTogglePin: onTogglePin,
      ),
    );
  }

  @override
  State<TrophyDossierSheet> createState() => _TrophyDossierSheetState();
}

class _TrophyDossierSheetState extends State<TrophyDossierSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _isClaiming = false;
  bool _claimedLocally = false;
  bool _showConfetti = false;
  String? _claimErrorMessage;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _isPinned = widget.isPinned;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleClaimReward() async {
    if (_isClaiming) return;
    setState(() {
      _isClaiming = true;
      _claimErrorMessage = null;
    });
    _pulseController.repeat(reverse: true);
    Haptics.vibrate(HapticsType.selection);
    debugPrint('[TrophyDossierSheet] Claiming bounty for trophy: "${widget.metadata.id}" (${widget.metadata.name})');

    try {
      if (di.sl.isRegistered<ClaimBadgeReward>()) {
        final result = await di.sl<ClaimBadgeReward>()(widget.metadata.id);
        result.fold(
          (failure) {
            debugPrint('[TrophyDossierSheet] Claim failed: ${failure.message}');
            Haptics.vibrate(HapticsType.error);
            if (mounted) {
              final errorText = failure.message == 'trophy-already-claimed'
                  ? 'This trophy bounty has already been claimed.'
                  : (failure.message == 'trophy-not-earned'
                      ? 'Complete the lesson criteria to unlock this trophy first!'
                      : 'Claim failed: ${failure.message}');
              setState(() {
                _claimErrorMessage = errorText;
              });
              CustomSnackBar.show(
                context: context,
                message: errorText,
                type: CustomSnackBarType.error,
              );
            }
          },
          (_) {
            debugPrint('[TrophyDossierSheet] Claim SUCCESS! +${widget.metadata.xpReward} XP, +${widget.metadata.coinReward} Coins');
            Haptics.vibrate(HapticsType.success);
            try {
              if (di.sl.isRegistered<SoundService>()) {
                di.sl<SoundService>().playCoinTally(count: 10);
              }
            } catch (_) {}
            if (mounted) {
              setState(() {
                _claimedLocally = true;
                _showConfetti = true;
                _claimErrorMessage = null;
              });
              CustomSnackBar.show(
                context: context,
                message: 'Bounty Claimed! +${widget.metadata.xpReward} XP, +${widget.metadata.coinReward} Coins',
                type: CustomSnackBarType.success,
              );
              if (di.sl.isRegistered<AuthBloc>()) {
                di.sl<AuthBloc>().add(const AuthReloadUser());
              }
            }
          },
        );
      } else {
        debugPrint('[TrophyDossierSheet] Error: ClaimBadgeReward is not registered in DI.');
        if (mounted) {
          const err = 'Service unavailable. Please restart app.';
          setState(() {
            _claimErrorMessage = err;
          });
          CustomSnackBar.show(
            context: context,
            message: err,
            type: CustomSnackBarType.error,
          );
        }
      }
    } catch (e, st) {
      debugPrint('[TrophyDossierSheet] Uncaught error during claim: $e\n$st');
      if (mounted) {
        final err = 'Failed to claim: $e';
        setState(() {
          _claimErrorMessage = err;
        });
        CustomSnackBar.show(
          context: context,
          message: err,
          type: CustomSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        _pulseController.stop();
        setState(() => _isClaiming = false);
      }
    }
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    Haptics.vibrate(HapticsType.success);

    try {
      await SocialShareRasterizer.captureAndShare(
        boundaryKey: _cardBoundaryKey,
        shareText: 'Unlocked the ${widget.metadata.name} trophy on VOWL! 🏆✨ #VowlApp',
        subject: 'My VOWL Trophy: ${widget.metadata.name}',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _handlePracticeNow() {
    Navigator.of(context).pop();
    const validCategories = {
      'speaking',
      'listening',
      'reading',
      'writing',
      'grammar',
      'vocabulary',
      'accent',
      'roleplay',
      'elitemastery',
    };
    final cat = widget.metadata.category.toLowerCase().trim();
    if (validCategories.contains(cat)) {
      context.push('${AppRouter.categoryGamesRoute}?category=$cat');
    } else {
      context.go(AppRouter.gamesRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final isClaimed = _claimedLocally ||
        (widget.user?.claimedBadgeRewards.contains(widget.metadata.id) ?? false);

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    final textPrimary = isDark ? Colors.white : AppColors.slate900;
    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate600;

    final progressRatio = widget.metadata.calculateProgress(
      widget.user,
      widget.user?.badges ?? [],
    );
    final progressLabel = widget.metadata.getProgressLabel(
      widget.user,
      widget.user?.badges ?? [],
    );
    final isEarnedEffective = widget.isEarned || progressRatio >= 1.0;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    final safeBottom = math.max(systemBottom, 16.h) + 16.h + bottomInset;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 0.90.sh,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, safeBottom),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              border: Border.all(color: borderColor, width: 1.w),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate700 : AppColors.slate300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Sharable Card Boundary
                  RepaintBoundary(
                    key: _cardBoundaryKey,
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1321) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          // Status Pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: isEarnedEffective
                                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEarnedEffective ? LucideIcons.checkCircle : LucideIcons.lock,
                                      size: 12.r,
                                      color: isEarnedEffective
                                          ? const Color(0xFF10B981)
                                          : textSecondary,
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      isEarnedEffective ? 'UNLOCKED' : 'LOCKED',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: isEarnedEffective
                                            ? const Color(0xFF10B981)
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          if (widget.metadata.isLegendary)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.gold.withValues(alpha: 0.15)
                                    : const Color(0xFFB45309).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.gold.withValues(alpha: 0.4)
                                      : const Color(0xFFB45309).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                'LEGENDARY',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.gold : const Color(0xFFB45309),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Large 3D Center Medallion
                      TrophyMedallionArtwork(
                        metadata: widget.metadata,
                        isEarned: isEarnedEffective,
                        size: 92.0,
                      ),
                      SizedBox(height: 16.h),

                      // Title & Category
                      Text(
                        widget.metadata.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.metadata.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          height: 1.3,
                        ),
                      ),

                      SizedBox(height: 18.h),

                      // Live Progress Tracker Bar
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                isEarnedEffective ? '100%' : progressLabel,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isEarnedEffective
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.white : AppColors.slate800),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 8.h,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isEarnedEffective
                                    ? const Color(0xFF10B981)
                                    : AppColors.indigo500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Rewards Bento
                      Row(
                        children: [
                          Expanded(
                            child: _buildBountyPill(
                              label: 'XP REWARD',
                              value: '+${widget.metadata.xpReward} XP',
                              icon: LucideIcons.zap,
                              color: AppColors.indigo500,
                              isDark: isDark,
                              borderColor: borderColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _buildBountyPill(
                              label: 'COIN REWARD',
                              value: '+${widget.metadata.coinReward} Coins',
                              icon: LucideIcons.coins,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Action Buttons
              if (isEarnedEffective) ...[
                if (_claimErrorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.rose500.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.rose500.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 15.sp,
                          color: AppColors.rose500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _claimErrorMessage!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rose500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],

                if (!isClaimed) ...[
                  ScaleButton(
                    onTap: _isClaiming ? null : _handleClaimReward,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isClaiming
                              ? [const Color(0xFF059669), const Color(0xFF10B981)]
                              : [const Color(0xFF10B981), const Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isClaiming
                          ? _buildClaimingLoadingState()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 16.sp,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    'Claim Bounty (+${widget.metadata.xpReward} XP, +${widget.metadata.coinReward} Coins)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981)
                          .withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 16.sp,
                          color: const Color(0xFF10B981),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'Bounty Claimed (+${widget.metadata.xpReward} XP, +${widget.metadata.coinReward} Coins)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Haptics.vibrate(HapticsType.light);
                            setState(() => _isPinned = !_isPinned);
                            widget.onTogglePin();
                          },
                          icon: Icon(
                            _isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                            size: 16.sp,
                            color: textPrimary,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _isPinned ? 'Unpin' : 'Pin to Showcase',
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(48.h),
                            maximumSize: Size.fromHeight(48.h),
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            side: BorderSide(color: borderColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: _handleShare,
                          icon: Icon(LucideIcons.share2, size: 16.sp),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _isSharing ? 'Generating...' : 'Share Trophy',
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indigo500,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            elevation: 0,
                            minimumSize: Size.fromHeight(48.h),
                            maximumSize: Size.fromHeight(48.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _handlePracticeNow,
                  icon: Icon(LucideIcons.playCircle, size: 18.sp),
                  label: Text(
                    'Practice Now',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo500,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (_showConfetti)
        const Positioned.fill(
          child: IgnorePointer(
            child: GameConfetti(shouldPop: true),
          ),
        ),
    ],
  ),
);
}

Widget _buildClaimingLoadingState() {
  return AnimatedBuilder(
    animation: _pulseAnimation,
    builder: (context, child) {
      return Opacity(
        opacity: _pulseAnimation.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: _pulseAnimation.value * math.pi * 0.25,
              child: Icon(
                LucideIcons.sparkles,
                size: 16.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'CLAIMING BOUNTY...',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildBountyPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14.r, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white54 : Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
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
