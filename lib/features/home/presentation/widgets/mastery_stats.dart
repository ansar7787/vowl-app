import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:go_router/go_router.dart';

class MasteryStats extends StatelessWidget {
  const MasteryStats({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInteractiveStatCard(
          context,
          context.tr('mastery.total_experience'),
          '${user.totalExp}',
          context.tr('mastery.view_xp_history'),
          Icons.auto_fix_high_rounded,
          const Color(0xFF2563EB),
          () => context.push(AppRouter.adventureXPRoute),
        ),
        SizedBox(height: 12.h),
        _buildInteractiveStatCard(
          context,
          context.tr('mastery.global_rank'),
          context.tr('home.level', args: [user.level.toString()]),
          context.tr('mastery.view_leaderboard'),
          Icons.emoji_events_rounded,
          const Color(0xFFF59E0B),
          () => context.push(AppRouter.leaderboardRoute),
        ),
        SizedBox(height: 12.h),
        _buildInteractiveStatCard(
          context,
          context.tr('mastery.vowl_coins'),
          '${user.coins}',
          context.tr('mastery.visit_coin_rewards'),
          Icons.monetization_on_rounded,
          const Color(0xFF10B981),
          () => context.push(AppRouter.questCoinsRoute),
        ),
      ],
    );
  }

  Widget _buildInteractiveStatCard(
    BuildContext context,
    String label,
    String value,
    String subLabel,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      button: true,
      label: '$label: $value. $subLabel',
      child: ScaleButton(
        onTap: onTap,
        child: ConstrainedBox(
          // Guarantees the minimum 48x48dp accessible touch target even
          // though the visual card is already comfortably larger than that.
          constraints: BoxConstraints(minHeight: 48.r),
          child: GlassTile(
            padding: EdgeInsets.all(20.r),
            borderRadius: BorderRadius.circular(28.r),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: color, size: 28.r),
                  ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subLabel,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              isRtl
                                  ? Icons.arrow_back_ios_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 10.r,
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
