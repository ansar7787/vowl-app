import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';
import 'package:vowl/features/referral/presentation/bloc/referral_cubit.dart';
import 'package:vowl/features/referral/presentation/bloc/referral_state.dart';
import 'package:vowl/features/referral/presentation/widgets/monthly_cup_leaderboard.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_claim_dialog.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_stats_card.dart';

class ReferralHubScreen extends StatelessWidget {
  const ReferralHubScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => const ReferralHubScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ReferralCubit(
          repository: di.sl<ReferralRepository>(),
        );
        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated && authState.user != null) {
          cubit.init(authState.user!);
        }
        return cubit;
      },
      child: const _ReferralHubView(),
    );
  }
}

class _ReferralHubView extends StatelessWidget {
  const _ReferralHubView();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF070A12) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.slate400 : (tokens?.textSecondary ?? const Color(0xFF64748B));
    final borderColor = isDark ? AppColors.slate800 : (tokens?.border ?? const Color(0xFFE2E8F0));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.midnightSurface : (tokens?.surface ?? Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20.sp, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ambassador Hub',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ReferralCubit, ReferralState>(
        listener: (context, state) {
          if (state.claimSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.emerald500,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  state.claimSuccess!.message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }
          if (state.cupRewardClaimResult != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: state.cupRewardClaimResult!.success
                    ? AppColors.emerald500
                    : AppColors.rose500,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  state.cupRewardClaimResult!.message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          final user = authState.status == AuthStatus.authenticated ? authState.user : null;

          if (user == null) {
            return Center(
              child: Text(
                'Please sign in to access Ambassador Hub',
                style: TextStyle(color: textSecondary, fontSize: 14.sp),
              ),
            );
          }

          if (state.isLoading && state.referralCode == null) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final code = state.referralCode ?? 'VOWL-XXXX';

          return RefreshIndicator(
            onRefresh: () => context.read<ReferralCubit>().init(user),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Referral Stats & Code Box
                  ReferralStatsCard(
                    referralCode: code,
                    lifetimeCount: user.totalReferralsCount,
                    monthlyCount: user.activeMonthlyReferralsCount,
                    hasClaimedReferral: user.hasClaimedReferral,
                    isCopied: state.copiedToClipboard,
                    onCopy: () => context.read<ReferralCubit>().copyCode(code),
                    onShare: () => context.read<ReferralCubit>().shareCode(code),
                    onEnterCode: () => _showClaimDialog(context, user),
                  ),

                  SizedBox(height: 16.h),

                  // How It Works Rules Card
                  _buildHowItWorksCard(isDark, borderColor, textPrimary, textSecondary),

                  SizedBox(height: 16.h),

                  // Monthly Ambassador Cup Leaderboard
                  MonthlyCupLeaderboard(
                    items: state.ambassadorLeaderboard,
                    isLoading: state.isLoading,
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHowItWorksCard(
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16.sp, color: AppColors.indigo500),
              SizedBox(width: 8.w),
              Text(
                'How Rewards Work',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildStepRow(
            step: '1',
            title: 'Share your code',
            description: 'Send your invite code or link to friends learning English.',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 12.h),
          _buildStepRow(
            step: '2',
            title: 'Friend completes Level 1',
            description: 'You both receive 100 Coins + 1 Day VIP Trial immediately.',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          SizedBox(height: 12.h),
          _buildStepRow(
            step: '3',
            title: 'Compete in the Monthly Cup',
            description: 'Top 10 ambassadors win 1 Month VIP, 1 Week VIP, and bonus coin pots at month-end.',
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
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: AppColors.indigo500.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
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
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClaimDialog(BuildContext context, UserEntity user) {
    final cubit = context.read<ReferralCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => BlocBuilder<ReferralCubit, ReferralState>(
        bloc: cubit,
        builder: (context, state) {
          return ReferralClaimDialog(
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
