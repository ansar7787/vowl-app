import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';

/// Glassmorphic card that rewards users with a Strategic Hint after watching
/// a rewarded video ad.
///
/// Uses a [ValueNotifier] loading gate to prevent duplicate ad triggers from
/// rapid taps.
class HintAdCard extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final String? title;
  final String? subtitle;

  const HintAdCard({super.key, this.margin, this.title, this.subtitle});

  @override
  State<HintAdCard> createState() => _HintAdCardState();
}

class _HintAdCardState extends State<HintAdCard> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  int _remainingClaims = RewardLimitService.maxClaimsPerDay;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final claims = await RewardLimitService.getRemainingClaims('hints');
    if (mounted) {
      setState(() {
        _remainingClaims = claims;
      });
    }
  }

  @override
  void dispose() {
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _showHintAd() async {
    if (_isLoading.value || _remainingClaims <= 0) return;
    _isLoading.value = true;

    bool rewardEarned = false;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    try {
      di.sl<AdService>().showHintRewardedAd(
        context: context,
        isPremium: isPremium,
        onHintEarned: () {
          rewardEarned = true;
        },
        onDismissed: () async {
          if (rewardEarned) {
            await RewardLimitService.incrementClaimCount('hints');
            if (mounted) await _loadLimits();

            if (mounted) {
              context.read<EconomyBloc>().add(
                const EconomyPurchaseHintRequested(0, hintAmount: 1),
              );

              CustomSnackBar.show(
                context: context,
                message: context.tr(
                  'games.hint_earned_snack',
                  fallback: 'Hint Earned! +1 Strategic Hint',
                ),
                type: CustomSnackBarType.success,
              );
            }
          }
        },
      );
    } finally {
      if (mounted) _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = context.watch<AuthBloc>().state.user?.isPremium ?? false;

    return RepaintBoundary(
      child: Container(
        margin:
            widget.margin ??
            EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: GlassTile(
          borderRadius: BorderRadius.circular(24.r),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (widget.title ??
                        (isPremium
                            ? context.tr(
                                'games.claim_free_hints_title',
                                fallback: 'CLAIM FREE HINTS',
                              )
                            : context.tr(
                                'games.watch_earn_hints_title',
                                fallback: 'WATCH AND EARN HINTS',
                              )))
                    .toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFF59E0B),
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Hint label ─────────────────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 16.r,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            widget.subtitle ??
                                context.tr(
                                  'games.one_strategic_hint',
                                  fallback: '1 STRATEGIC HINT',
                                ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // ── Watch button ────────────────────────────────────────
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoading,
                    builder: (context, loading, child) {
                      final isLimitReached =
                          !isPremium && _remainingClaims <= 0;
                      final isDisabled = loading || isLimitReached;

                      return Semantics(
                        button: true,
                        enabled: !isDisabled,
                        label: isPremium
                            ? context.tr(
                                'games.hint_semantic_claim_label',
                                fallback: 'Claim a free strategic hint',
                              )
                            : (isLimitReached
                                  ? context.tr(
                                      'games.limit_reached_semantic',
                                      fallback: 'Daily limit reached',
                                    )
                                  : context.tr(
                                      'games.hint_semantic_label',
                                      fallback:
                                          'Watch ad to earn a strategic hint',
                                    )),
                        child: ScaleButton(
                          onTap: isDisabled ? null : _showHintAd,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            constraints: BoxConstraints(minHeight: 48.h),
                            decoration: BoxDecoration(
                              gradient: isDisabled
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                    ),
                              color: isDisabled
                                  ? const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.4)
                                  : null,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: isDisabled
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: loading
                                ? const VowlButtonSpinner(
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isLimitReached)
                                        Icon(
                                          isPremium
                                              ? Icons.redeem_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20.r,
                                        ),
                                      if (!isLimitReached) SizedBox(width: 4.w),
                                      Text(
                                        isLimitReached
                                            ? context.tr(
                                                'games.limit_button',
                                                fallback: 'LIMIT REACHED',
                                              )
                                            : (isPremium
                                                  ? context.tr(
                                                      'games.claim_button',
                                                      fallback: 'CLAIM',
                                                    )
                                                  : context.tr(
                                                      'games.watch_button',
                                                      fallback: 'WATCH',
                                                    )),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
