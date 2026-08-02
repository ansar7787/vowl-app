import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/pedagogical_blueprint.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class CategoryRadarChart extends StatelessWidget {
  const CategoryRadarChart({
    super.key,
    required this.user,
    required this.primaryColor,
    required this.isDark,
    required this.categoryId,
  });

  final UserEntity user;
  final Color primaryColor;
  final bool isDark;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final blueprint = PedagogicalBlueprintMap.getBlueprint(categoryId);
    if (blueprint == null) return const SizedBox.shrink();

    // Calculate stats using the blueprint
    // For a dynamic 4-axis chart without hardcoding 4 tiers of games, we can split the games
    // For a 4-point chart but only 3 tiers, we can use an average of all for the 4th axis,
    // OR since elite games might be in tier 4, wait, we mapped 3 tiers but 4 axes!
    // Ah, wait. Let's calculate based on the axes. The blueprint has tier1, tier2, tier3.
    // Let's divide the tier games roughly by the 4 axes, or just map them to 4 logical scores.
    // Actually, in Accent we did:
    // 1: T1
    // 2: T2
    // 3: Elite (T4)
    // 4: Flow (T3)
    
    // For a dynamic 4-axis chart without hardcoding 4 tiers of games, we can split the games
    // into 4 groups, or we can just divide the total games into 4 equal chunks to power the 4 axes.
    final allGames = [...blueprint.tier1, ...blueprint.tier2, ...blueprint.tier3];
    final chunkSize = (allGames.length / 4).ceil();
    
    final axisGames1 = allGames.take(chunkSize).toList();
    final axisGames2 = allGames.skip(chunkSize).take(chunkSize).toList();
    final axisGames3 = allGames.skip(chunkSize * 2).take(chunkSize).toList();
    final axisGames4 = allGames.skip(chunkSize * 3).toList();

    final score1 = _calculateCategoryProgress(axisGames1);
    final score2 = _calculateCategoryProgress(axisGames2);
    final score3 = _calculateCategoryProgress(axisGames3);
    final score4 = _calculateCategoryProgress(axisGames4);

    // Ensure minimum visibility for the chart
    final displayScores = [
      math.max(0.15, score1), // Top
      math.max(0.15, score2), // Right
      math.max(0.15, score3), // Bottom
      math.max(0.15, score4), // Left
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('category.skill_radar', fallback: 'SKILL RADAR'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 2,
                ),
              ),
              Icon(
                Icons.radar_rounded,
                color: primaryColor,
                size: 20.r,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 200.r,
            child: CustomPaint(
              size: Size(double.infinity, 200.r),
              painter: _RadarChartPainter(
                scores: displayScores,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Labels below
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(context, blueprint.radarAxes[0], primaryColor, score1),
              _buildLegend(context, blueprint.radarAxes[1], primaryColor, score2),
              _buildLegend(context, blueprint.radarAxes[2], primaryColor, score3),
              _buildLegend(context, blueprint.radarAxes[3], primaryColor, score4),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, String label, Color color, double score) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${(score * 100).toInt()}%',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateCategoryProgress(List<GameSubtype> games) {
    if (games.isEmpty) return 0.0;
    int totalLevels = games.length * 200;
    int completedLevels = 0;
    for (var game in games) {
      completedLevels += (user.completedLevels[game.name]?.length ?? 0).clamp(0, 200);
    }
    return totalLevels > 0 ? (completedLevels / totalLevels).clamp(0.0, 1.0) : 0.0;
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> scores;
  final Color primaryColor;
  final bool isDark;

  _RadarChartPainter({
    required this.scores,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 20;

    final paintBg = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final paintLine = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw background concentric polygons (diamonds since 4 points)
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      final path = Path();
      for (int j = 0; j < 4; j++) {
        final angle = (j * math.pi / 2) - (math.pi / 2); // Start at top
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, i % 2 == 0 ? paintBg : paintLine);
      canvas.drawPath(path, paintLine);
    }

    // Draw axes
    for (int j = 0; j < 4; j++) {
      final angle = (j * math.pi / 2) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paintLine);
    }

    // Draw data polygon
    final dataPath = Path();
    for (int j = 0; j < 4; j++) {
      final angle = (j * math.pi / 2) - (math.pi / 2);
      final r = radius * scores[j];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (j == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    final dataPaintFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final dataPaintStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(dataPath, dataPaintFill);
    canvas.drawPath(dataPath, dataPaintStroke);

    // Draw data points
    final pointPaint = Paint()
      ..color = isDark ? Colors.white : Colors.white
      ..style = PaintingStyle.fill;
      
    final pointStrokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int j = 0; j < 4; j++) {
      final angle = (j * math.pi / 2) - (math.pi / 2);
      final r = radius * scores[j];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.scores != scores ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.isDark != isDark;
  }
}
