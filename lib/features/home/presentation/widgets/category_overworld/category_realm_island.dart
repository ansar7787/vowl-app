import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter/services.dart';

/// Floating Realm Island node representing a single game on the Category Overworld Map.
/// Clean, minimal, high-definition styling with crisp borders and zero clutter.
class CategoryRealmIsland extends StatelessWidget {
  final GameSubtype subtype;
  final bool isDark;
  final bool isMidnight;
  final bool isMastered;
  final bool isAllThreeStars;
  final int completedLevels;
  final int currentLevel;
  final int totalLevels;
  final int gameplayStars;
  final int maxStars;
  final double progress;
  final VoidCallback onTap;

  const CategoryRealmIsland({
    super.key,
    required this.subtype,
    required this.isDark,
    required this.isMidnight,
    required this.isMastered,
    required this.isAllThreeStars,
    required this.completedLevels,
    required this.currentLevel,
    required this.totalLevels,
    required this.gameplayStars,
    required this.maxStars,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final displayColor = theme.primaryColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;

    // Background color resolution based on state & theme
    final Color cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);

    // Clean, crisp border matching all cards without colored splash halos
    final Color borderColor = isMastered
        ? const Color(0xFFFFB300).withValues(alpha: 0.5)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.slate200);

    final double borderWidth = isMastered ? 1.5 : 1.0;

    final String statusLabel = isMastered
        ? (isAllThreeStars
            ? context.tr('category_games.perfect', fallback: '100% Perfect')
            : context.tr('category_games.mastered', fallback: 'Mastered'))
        : 'Level $currentLevel of $totalLevels, $gameplayStars stars';

    return Semantics(
      button: true,
      label: '${theme.title}, $statusLabel',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Main Island Card (Crisp, clean border, zero splash) ───────────
          ScaleButton(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              width: 210.w,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 10.r,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Game Realm Icon Pedestal
                  _buildIconPedestal(displayColor, isMastered),

                  SizedBox(width: 10.w),

                  // Game Realm Info & Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        AutoSizeText(
                          theme.title.toUpperCase(),
                          maxLines: 1,
                          minFontSize: 9,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: contentColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 5.h),

                        // Progress Bar
                        _buildProgressBar(
                          isAllThreeStars
                              ? const Color(0xFFFFB300)
                              : displayColor,
                        ),
                        SizedBox(height: 5.h),

                        // Stars & Level Subtitle (Guarded with FittedBox to prevent any RenderFlex overflow)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  '★ $gameplayStars / $maxStars',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isMastered
                                        ? const Color(0xFFFFB300)
                                        : displayColor,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerEnd,
                                child: _buildStatusPill(displayColor, context),
                              ),
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

          // ── Mastered Crown Badge ──────────────────────────────────────────
          if (isMastered)
            PositionedDirectional(
              end: -6.w,
              top: -10.h,
              child: Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                      blurRadius: 6.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isAllThreeStars
                      ? Icons.stars_rounded
                      : Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 14.r,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconPedestal(Color displayColor, bool isMastered) {
    return Container(
      width: 42.r,
      height: 42.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMastered
              ? [const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
              : [displayColor, displayColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13.r),
        boxShadow: [
          BoxShadow(
            color: (isMastered ? const Color(0xFFFFB300) : displayColor)
                .withValues(alpha: 0.35),
            blurRadius: 8.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          GameHelper.getIconForSubtype(subtype),
          color: Colors.white,
          size: 20.r,
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color color) {
    return Container(
      height: 5.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: progress <= 0 ? 0.0 : progress.clamp(0.04, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(Color displayColor, BuildContext context) {
    if (isMastered) {
      return Text(
        isAllThreeStars
            ? context.tr('category_games.perfect', fallback: '100% PERFECT')
            : context.tr('category_games.mastered', fallback: 'MASTERED'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 8.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFB300),
          letterSpacing: 0.5,
        ),
      );
    }

    // Never show locked! If not played yet, show a welcoming 'NEW' badge
    if (completedLevels == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          context.tr('common.new_badge', fallback: 'NEW'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
            color: displayColor,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return Text(
      'Lv.$currentLevel',
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 9.sp,
        fontWeight: FontWeight.w900,
        color: displayColor,
      ),
    );
  }
}
