import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/pedagogical_blueprint.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class AdaptiveSmartMixWidget extends StatelessWidget {
  const AdaptiveSmartMixWidget({
    super.key,
    required this.user,
    required this.isDark,
    required this.categoryId,
  });

  final UserEntity user;
  final bool isDark;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final blueprint = PedagogicalBlueprintMap.getBlueprint(categoryId);
    if (blueprint == null) return const SizedBox.shrink();

    // Determine the daily mix based on the current day to keep it consistent
    final today = DateTime.now();
    final random = math.Random(today.year * 10000 + today.month * 100 + today.day);

    GameSubtype getWeakestGame(List<GameSubtype> tier) {
      if (tier.isEmpty) return GameSubtype.grammarQuest;
      GameSubtype weakest = tier.first;
      int lowestScore = 999;
      
      // Deterministically shuffle to handle ties differently each day
      final shuffledTier = List<GameSubtype>.from(tier)..shuffle(random);
      
      for (var game in shuffledTier) {
        int score = (user.completedLevels[game.name]?.length ?? 0);
        if (score < lowestScore) {
          lowestScore = score;
          weakest = game;
        }
      }
      return weakest;
    }

    final mix = [
      if (blueprint.tier1.isNotEmpty) getWeakestGame(blueprint.tier1),
      if (blueprint.tier2.isNotEmpty) getWeakestGame(blueprint.tier2),
      if (blueprint.tier3.isNotEmpty) getWeakestGame(blueprint.tier3),
    ];

    final theme = LevelThemeHelper.getCategoryTheme(categoryId, isDark: isDark);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primaryColor, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                context.tr('category.daily_mix', fallback: 'DAILY SMART MIX'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr('category.daily_mix_desc', fallback: 'Your personalized 3-step workout based on your weakest skills.'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 16.h),
          ...mix.asMap().entries.map((entry) {
            String tierLabel = '';
            if (entry.key == 0) tierLabel = blueprint.tier1Label;
            if (entry.key == 1) tierLabel = blueprint.tier2Label;
            if (entry.key == 2) tierLabel = blueprint.tier3Label;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildMixCard(context, entry.value, entry.key + 1, theme.primaryColor, tierLabel),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMixCard(BuildContext context, GameSubtype subtype, int step, Color accentColor, String tierLabel) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final displayColor = isDark
        ? theme.primaryColor
        : HSLColor.fromColor(theme.primaryColor).withLightness(0.4).toColor();
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ScaleButton(
      onTap: () => context.push(
        '${AppRouter.levelsRoute}?category=$categoryId&gameType=${Uri.encodeQueryComponent(subtype.name)}',
      ),
      child: GlassTile(
        borderRadius: BorderRadius.circular(20.r),
        padding: EdgeInsets.all(16.r),
        glassOpacity: 0.15,
        showShadow: false,
        usePremiumStyle: true,
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: displayColor.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  "$step",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: displayColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: contentColor,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tierLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: displayColor.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill_rounded,
              color: displayColor,
              size: 32.r,
            ),
          ],
        ),
      ),
    );
  }
}
