import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';
import 'package:vowl/features/referral/presentation/bloc/referral_cubit.dart';
import 'package:vowl/features/referral/presentation/bloc/referral_state.dart';
import 'package:vowl/features/referral/presentation/widgets/monthly_cup_leaderboard.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_claim_dialog.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_stats_card.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';

class ReferralHubScreen extends StatelessWidget {
  final String? initialInviteCode;
  final int initialTab;

  const ReferralHubScreen({
    super.key,
    this.initialInviteCode,
    this.initialTab = 0,
  });

  static Route<void> route({String? initialInviteCode, int initialTab = 0}) {
    return MaterialPageRoute(
      builder: (_) => ReferralHubScreen(
        initialInviteCode: initialInviteCode,
        initialTab: initialTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ReferralCubit(repository: di.sl<ReferralRepository>());
        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          cubit.init(authState.user!);
        }
        return cubit;
      },
      child: _ReferralHubView(
        initialInviteCode: initialInviteCode,
        initialTab: initialTab,
      ),
    );
  }
}

class _ReferralHubView extends StatefulWidget {
  final String? initialInviteCode;
  final int initialTab;

  const _ReferralHubView({this.initialInviteCode, this.initialTab = 0});

  @override
  State<_ReferralHubView> createState() => _ReferralHubViewState();
}

class _ReferralHubViewState extends State<_ReferralHubView> {
  bool _hasTriggeredAutoClaim = false;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 1);
  }

  void _checkAutoClaim(UserEntity user) {
    if (_hasTriggeredAutoClaim || widget.initialInviteCode == null) return;
    if (user.hasClaimedReferral) return;
    _hasTriggeredAutoClaim = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showClaimDialog(context, user, initialCode: widget.initialInviteCode);
      }
    });
  }

  Widget _buildSegmentedSwitcher(
    bool isDark,
    bool isMidnight,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.compact,
        vertical: 8.h,
      ),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark
                  ? const Color(0xFF131A29)
                  : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              icon: Icons.card_giftcard_rounded,
              label: 'Invite & Earn',
              isSelected: _selectedTab == 0,
              isDark: isDark,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildTabButton(
              index: 1,
              icon: LucideIcons.trophy,
              label: 'Monthly Cup',
              isSelected: _selectedTab == 1,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return ScaleButton(
      onTap: () {
        if (_selectedTab == index) return;
        di.sl<HapticService>().selection();
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.indigo500 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15.r,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.indigo500)
                      : (isDark ? Colors.white54 : AppColors.slate500),
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5.sp,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.slate900)
                        : (isDark ? Colors.white54 : AppColors.slate600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final backgroundColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : Colors.white);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? const Color(0xFF64748B));
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isMidnight
            ? Colors.black
            : (isDark ? AppColors.slate900 : Colors.white),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.r,
            color: textPrimary,
          ),
          onPressed: () {
            di.sl<HapticService>().light();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Ambassador Hub',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSegmentedSwitcher(
            isDark,
            isMidnight,
            borderColor,
            textPrimary,
            textSecondary,
          ),
          Expanded(
            child: BlocConsumer<ReferralCubit, ReferralState>(
              listener: (context, state) {
                if (state.claimSuccess != null) {
                  context.read<AuthBloc>().add(const AuthReloadUser());
                  CustomSnackBar.show(
                    context: context,
                    message: state.claimSuccess!.message,
                    type: CustomSnackBarType.success,
                  );
                }
                if (state.cupRewardClaimResult != null) {
                  if (state.cupRewardClaimResult!.success) {
                    context.read<AuthBloc>().add(const AuthReloadUser());
                  }
                  CustomSnackBar.show(
                    context: context,
                    message: state.cupRewardClaimResult!.message,
                    type: state.cupRewardClaimResult!.success
                        ? CustomSnackBarType.success
                        : CustomSnackBarType.error,
                  );
                }
                if (state.syncedAmbassadorRewardCount != null &&
                    state.syncedAmbassadorRewardCount! > 0) {
                  context.read<AuthBloc>().add(const AuthReloadUser());
                  final count = state.syncedAmbassadorRewardCount!;
                  final coins = count * 100;
                  CustomSnackBar.show(
                    context: context,
                    message:
                        '$count friend(s) completed Level 1! You unlocked +$coins Coins & +$count Day VIP!',
                    type: CustomSnackBarType.success,
                  );
                }
              },
              builder: (context, state) {
                final authState = context.watch<AuthBloc>().state;
                final user = authState.status == AuthStatus.authenticated
                    ? authState.user
                    : null;

                if (user == null) {
                  return Center(
                    child: Text(
                      'Please sign in to view invite rewards',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                if (state.isLoading && state.referralCode == null) {
                  return Center(
                    child: Padding(
                      padding: AppSpacing.spaciousPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 30.r,
                            color: AppColors.indigo500,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Loading your rewards...',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final code = state.referralCode ?? 'VOWL-XXXX';
                _checkAutoClaim(user);

                return RefreshIndicator(
                  onRefresh: () => context.read<ReferralCubit>().init(user),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.compact,
                      vertical: 8.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedTab == 0) ...[
                          // Referral Stats & Code Box
                          ReferralStatsCard(
                            referralCode: code,
                            lifetimeCount: user.totalReferralsCount,
                            monthlyCount: user.activeMonthlyReferralsCount,
                            hasClaimedReferral: user.hasClaimedReferral,
                            pendingReferralCode: user.pendingReferralCode,
                            referredBy: user.referredBy,
                            hasActivePremium: user.hasActivePremium,
                            premiumExpiryDate: user.premiumExpiryDate,
                            isCopied: state.copiedToClipboard,
                            onCopy: () =>
                                context.read<ReferralCubit>().copyCode(code),
                            onShare: () {
                              ShareCardPreviewModal.show(
                                context: context,
                                data: ShareCardData.fromReferral(
                                  userName: user.safeDisplayName,
                                  userPhotoUrl: user.photoUrl,
                                  referralCode: code,
                                ),
                              );
                            },
                            onEnterCode: () => _showClaimDialog(context, user),
                          ),
                          SizedBox(height: 16.h),
                          // How It Works Rules Card
                          _buildHowItWorksCard(
                            isDark,
                            isMidnight,
                            borderColor,
                            textPrimary,
                            textSecondary,
                          ),
                        ] else ...[
                          // Monthly Ambassador Cup Leaderboard
                          MonthlyCupLeaderboard(
                            items: state.ambassadorLeaderboard,
                            isLoading: state.isLoading,
                            currentUserId: user.id,
                            currentUserPhotoUrl: user.photoUrl,
                            myMonthlyReferrals:
                                user.activeMonthlyReferralsCount,
                            onClaimPastMonth: () => context
                                .read<ReferralCubit>()
                                .claimMonthlyCupReward(user),
                            isClaimingPastMonth: state.isClaimingCupReward,
                            hasUnclaimedPastMonth:
                                user.activeMonthlyReferralsCount > 0,
                            onInviteTap: () {
                              di.sl<HapticService>().selection();
                              setState(() => _selectedTab = 0);
                            },
                          ),
                        ],
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(
    bool isDark,
    bool isMidnight,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isMidnight
            ? AppColors.midnightSurface
            : (isDark ? AppColors.slate900 : Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18.r,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 8.w),
              Text(
                'How Rewards Work',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildStepRow(
            step: '1',
            title: 'Share your code or link',
            description:
                'Send your invite code to friends, classmates, or family learning English.',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 12.h),
          _buildStepRow(
            step: '2',
            title: 'Friend completes Level 1',
            description:
                'When they finish their first pronunciation lesson, both of you unlock rewards.',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 12.h),
          _buildStepRow(
            step: '3',
            title: 'Unlock 100 Coins & 1 Day VIP',
            description:
                'Coins and VIP time are credited instantly, and you rank up in the Monthly Cup!',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String description,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.r,
          height: 24.r,
          decoration: BoxDecoration(
            color: AppColors.indigo500.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.indigo500.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.indigo500,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClaimDialog(
    BuildContext context,
    UserEntity user, {
    String? initialCode,
  }) {
    final cubit = context.read<ReferralCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => BlocBuilder<ReferralCubit, ReferralState>(
        bloc: cubit,
        builder: (context, state) {
          return ReferralClaimDialog(
            initialCode: initialCode,
            isLoading: state.isClaiming,
            errorMessage: state.claimError,
            onClaim: (code) async {
              await cubit.claimCode(code, user);
              if (cubit.state.claimSuccess != null && dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
            },
          );
        },
      ),
    );
  }
}
