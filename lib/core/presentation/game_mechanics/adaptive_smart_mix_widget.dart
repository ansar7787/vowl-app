import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/pedagogical_blueprint.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class AdaptiveSmartMixWidget extends StatefulWidget {
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
  State<AdaptiveSmartMixWidget> createState() => _AdaptiveSmartMixWidgetState();
}

class _AdaptiveSmartMixWidgetState extends State<AdaptiveSmartMixWidget> {
  late final ValueNotifier<List<GameSubtype>> _mixNotifier;
  PedagogicalBlueprint? _blueprint;

  @override
  void initState() {
    super.initState();
    _mixNotifier = ValueNotifier<List<GameSubtype>>([]);
    _computeMix();
  }

  @override
  void didUpdateWidget(covariant AdaptiveSmartMixWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user ||
        oldWidget.categoryId != widget.categoryId) {
      _computeMix();
    }
  }
  
  @override
  void dispose() {
    _mixNotifier.dispose();
    super.dispose();
  }

  void _computeMix() {
    _blueprint = PedagogicalBlueprintMap.getBlueprint(widget.categoryId);
    if (_blueprint == null) return;

    // Determine the daily mix based on the current day to keep it consistent
    final today = DateTime.now();
    final random = math.Random(
      today.year * 10000 + today.month * 100 + today.day,
    );

    GameSubtype getWeakestGame(List<GameSubtype> tier) {
      if (tier.isEmpty) return GameSubtype.grammarQuest;
      GameSubtype weakest = tier.first;
      int lowestScore = 999;

      // Deterministically shuffle to handle ties differently each day
      final shuffledTier = List<GameSubtype>.from(tier)..shuffle(random);

      for (var game in shuffledTier) {
        int score = (widget.user.completedLevels[game.name]?.length ?? 0);
        if (score < lowestScore) {
          lowestScore = score;
          weakest = game;
        }
      }
      return weakest;
    }

    final newMix = [
      if (_blueprint!.tier1.isNotEmpty) getWeakestGame(_blueprint!.tier1),
      if (_blueprint!.tier2.isNotEmpty) getWeakestGame(_blueprint!.tier2),
      if (_blueprint!.tier3.isNotEmpty) getWeakestGame(_blueprint!.tier3),
    ];

    // Prevent unnecessary ValueNotifier triggers and re-animations 
    // if the resulting weakest games list is exactly the same as before.
    if (!listEquals(_mixNotifier.value, newMix)) {
      _mixNotifier.value = newMix;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blueprint == null) return const SizedBox.shrink();

    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: widget.isDark,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.primaryColor, size: 20.r)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white54),
              SizedBox(width: 8.w),
              AutoSizeText(
                context.tr('category.daily_mix', fallback: 'DAILY SMART MIX'),
                maxLines: 1,
                minFontSize: 8,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 2,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          SizedBox(height: 8.h),
          AutoSizeText(
            context.tr(
              'category.daily_mix_desc',
              fallback:
                  'Your personalized 3-step workout based on your weakest skills.',
            ),
            maxLines: 2,
            minFontSize: 8,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white70 : Colors.black54,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          SizedBox(height: 16.h),
          ValueListenableBuilder<List<GameSubtype>>(
            valueListenable: _mixNotifier,
            builder: (context, mix, child) {
              if (mix.isEmpty) return const SizedBox.shrink();
              return Column(
                children: mix.asMap().entries.map((entry) {
                  String tierLabel = '';
                  if (entry.key == 0) tierLabel = _blueprint!.tier1Label;
                  if (entry.key == 1) tierLabel = _blueprint!.tier2Label;
                  if (entry.key == 2) tierLabel = _blueprint!.tier3Label;

                  return Padding(
                    key: ValueKey('${entry.value.name}_${entry.key}'),
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildMixCard(
                      context,
                      entry.value,
                      entry.key + 1,
                      theme.primaryColor,
                      tierLabel,
                    ),
                  ).animate(key: ValueKey('anim_${entry.value.name}_${entry.key}'))
                   .fadeIn(delay: (200 + entry.key * 100).ms, duration: 400.ms)
                   .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMixCard(
    BuildContext context,
    GameSubtype subtype,
    int step,
    Color accentColor,
    String tierLabel,
  ) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: widget.isDark);
    final displayColor =
        widget.isDark
            ? theme.primaryColor
            : HSLColor.fromColor(theme.primaryColor).withLightness(0.4).toColor();
    final contentColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);

    return ScaleButton(
      onTap:
          () => context.push(
            '${AppRouter.levelsRoute}?category=${widget.categoryId}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
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
                child: AutoSizeText(
                  "$step",
                  maxLines: 1,
                  minFontSize: 6,
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
                  AutoSizeText(
                    theme.title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: contentColor,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    minFontSize: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  AutoSizeText(
                    tierLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: displayColor.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    minFontSize: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: displayColor, size: 32.r),
          ],
        ),
      ),
    );
  }
}
