import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/category_overworld/category_overworld_segment_painter.dart';
import 'package:vowl/features/home/presentation/widgets/category_overworld/category_realm_island.dart';

/// Interactive Overworld Map presenting curriculum games along a continuous, serpentine adventure path.
/// Alternates cards on opposite sides using maximum screen width with a deep, organic, seamless S-curve.
class CategoryOverworldMap extends StatelessWidget {
  final List<GameSubtype> games;
  final UserEntity user;
  final String categoryId;
  final Color themeColor;
  final bool isDark;
  final bool isMidnight;
  final double? bottomPadding;

  const CategoryOverworldMap({
    super.key,
    required this.games,
    required this.user,
    required this.categoryId,
    required this.themeColor,
    required this.isDark,
    required this.isMidnight,
    this.bottomPadding,
  });

  /// Calculates alternating maximum-side node points with subtle organic harmonic variance.
  /// Alternates between the left and right sides of the screen to create a massive, deep sweeping curve.
  List<Offset> _calculatePoints(int count, double screenWidth, double rowHeight) {
    final List<Offset> points = [];
    final double cardWidth = 210.w;
    final double sideMargin = 16.w;
    final double leftCenter = sideMargin + (cardWidth / 2);
    final double rightCenter = screenWidth - sideMargin - (cardWidth / 2);

    for (int i = 0; i < count; i++) {
      final bool isLeft = (i % 2 == 0);
      final double drift = math.sin(i * 1.4) * 6.w;
      final double x = isLeft ? (leftCenter + drift) : (rightCenter - drift);
      final double y = rowHeight / 2;
      points.add(Offset(x, y));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final screenWidth = MediaQuery.of(context).size.width;
    // 175.h vertical spacing ensures cards never touch and gives the S-curve generous sweep
    final rowHeight = 175.h;
    final islandWidth = 210.w;
    final islandHeight = 70.h;

    final points = _calculatePoints(games.length, screenWidth, rowHeight);

    return SliverPadding(
      padding: EdgeInsets.only(
        top: 14.h,
        bottom: bottomPadding ?? (MediaQuery.of(context).padding.bottom + 48.h),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = games[index];
            final point = points[index];

            final prevPoint = index > 0
                ? Offset(points[index - 1].dx, 0)
                : null;
            final nextPoint = index < games.length - 1
                ? Offset(points[index + 1].dx, rowHeight)
                : null;

            final completedCount = user.completedLevels[game.name]?.length ?? 0;
            final totalLevels = CurriculumManifest.getLevels(game.name);
            final isMastered = completedCount >= totalLevels;
            final currentLevel = isMastered ? totalLevels : completedCount + 1;

            final categoryStars = user.starRatings[game.name] ?? {};
            int gameplayStars = 0;
            categoryStars.forEach((key, value) {
              if (key != 'magic_stars' && key != 'claimed_chests') {
                gameplayStars += value;
              }
            });
            final maxStars = totalLevels * 3;
            final isAllThreeStars = isMastered && gameplayStars >= maxStars;
            final double progress = totalLevels > 0 ? (completedCount / totalLevels) : 0.0;

            return SizedBox(
              height: rowHeight,
              width: screenWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Dual-Tone Luminous Serpentine Spline Path Segment
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(screenWidth, rowHeight),
                      painter: CategoryOverworldSegmentPainter(
                        currentPoint: point,
                        nextPoint: nextPoint,
                        prevPoint: prevPoint,
                        themeColor: themeColor,
                        isFirst: index == 0,
                        isLast: index == games.length - 1,
                        isDark: isDark,
                        isMidnight: isMidnight,
                      ),
                    ),
                  ),

                  // 2. Realm Island Node (Alternates Left and Right using maximum side space)
                  Positioned(
                    left: (point.dx - (islandWidth / 2)).clamp(
                      16.w,
                      math.max(16.w, screenWidth - islandWidth - 16.w),
                    ),
                    top: point.dy - (islandHeight / 2),
                    child: RepaintBoundary(
                      child: CategoryRealmIsland(
                        subtype: game,
                        isDark: isDark,
                        isMidnight: isMidnight,
                        isMastered: isMastered,
                        isAllThreeStars: isAllThreeStars,
                        completedLevels: completedCount,
                        currentLevel: currentLevel,
                        totalLevels: totalLevels,
                        gameplayStars: gameplayStars,
                        maxStars: maxStars,
                        progress: progress,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(
                            '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(categoryId)}&gameType=${Uri.encodeQueryComponent(game.name)}',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: games.length,
        ),
      ),
    );
  }
}
