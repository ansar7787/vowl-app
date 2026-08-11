import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomeQuickStats extends StatelessWidget {
  final UserEntity user;

  const HomeQuickStats({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatTile(
            context,
            context.tr('home.streak', fallback: 'Streak'),
            '${user.currentStreak}',
            Icons.local_fire_department_rounded,
            const Color(0xFFF97316),
            AppRouter.streakRoute,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.15, end: 0),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildMiniStatTile(
            context,
            context.tr('home.coins', fallback: 'Coins'),
            '${user.coins}',
            Icons.paid_rounded,
            const Color(0xFF10B981),
            AppRouter.questCoinsRoute,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.15, end: 0),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildMiniStatTile(
            context,
            context.tr('home.kids', fallback: 'Kids'),
            '${user.kidsCoins}',
            Icons.monetization_on_rounded,
            const Color(0xFFF59E0B),
            '${AppRouter.kidsZoneRoute}/boutique',
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.15, end: 0),
      ],
    );
  }

  Widget _buildMiniStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String route,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: '$label: $value',
      child: ScaleButton(
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48.r),
          child: GlassTile(
            borderRadius: BorderRadius.circular(20.r),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            child: ExcludeSemantics(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20.r),
                    ),
                    SizedBox(height: 8.h),
                    AutoSizeText(
                      value,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    AutoSizeText(
                      label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : Colors.black45,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      minFontSize: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
