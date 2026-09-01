import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/pedagogical_blueprint.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class CategoryRadarChart extends StatefulWidget {
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
  State<CategoryRadarChart> createState() => _CategoryRadarChartState();
}

class _CategoryRadarChartState extends State<CategoryRadarChart> {
  final ValueNotifier<List<double>> _displayScores = ValueNotifier([0.15, 0.15, 0.15, 0.15]);
  PedagogicalBlueprint? _blueprint;

  @override
  void initState() {
    super.initState();
    
    _computeScores();
  }

  @override
  void didUpdateWidget(covariant CategoryRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user ||
        oldWidget.categoryId != widget.categoryId) {
      _computeScores();
    }
  }

  void _computeScores() {
    _blueprint = PedagogicalBlueprintMap.getBlueprint(widget.categoryId);
    if (_blueprint == null) return;

    final allGames = [
      ..._blueprint!.tier1,
      ..._blueprint!.tier2,
      ..._blueprint!.tier3,
    ];
    if (allGames.isEmpty) return;

    final chunkSize = (allGames.length / 4).ceil();

    final axisGames1 = allGames.take(chunkSize).toList();
    final axisGames2 = allGames.skip(chunkSize).take(chunkSize).toList();
    final axisGames3 = allGames.skip(chunkSize * 2).take(chunkSize).toList();
    final axisGames4 = allGames.skip(chunkSize * 3).toList();

    final score1 = _calculateCategoryProgress(axisGames1);
    final score2 = _calculateCategoryProgress(axisGames2);
    final score3 = _calculateCategoryProgress(axisGames3);
    final score4 = _calculateCategoryProgress(axisGames4);

    final newScores = [
      math.max(0.15, score1), // Top
      math.max(0.15, score2), // Right
      math.max(0.15, score3), // Bottom
      math.max(0.15, score4), // Left
    ];

    if (!listEquals(_displayScores.value, newScores)) {
      _displayScores.value = newScores;
    }
  }

  double _calculateCategoryProgress(List<GameSubtype> games) {
    if (games.isEmpty) return 0.0;
    int totalLevels = games.length * 200;
    int completedLevels = 0;
    for (var game in games) {
      completedLevels +=
          (widget.user.completedLevels[game.name]?.length ?? 0).clamp(0, 200);
    }
    return totalLevels > 0
        ? (completedLevels / totalLevels).clamp(0.0, 1.0)
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_blueprint == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
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
              AutoSizeText(
                context.tr('category.skill_radar', fallback: 'SKILL RADAR'),
                maxLines: 1,
                minFontSize: 10,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 2,
                ),
              ),
              Icon(Icons.radar_rounded, color: widget.primaryColor, size: 20.r),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 200.r,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, animValue, child) {
                return ValueListenableBuilder<List<double>>(
                  valueListenable: _displayScores,
                  builder: (context, scores, _) {
                    final animatedScores = scores.map((s) => s * animValue).toList();
                return CustomPaint(
                  size: Size(double.infinity, 200.r),
                  painter: _RadarChartPainter(
                    scores: animatedScores,
                    primaryColor: widget.primaryColor,
                    isDark: widget.isDark,
                    bgAnimValue: animValue.clamp(0.0, 1.0),
                  ),
                );
                  }
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ValueListenableBuilder<List<double>>(
                valueListenable: _displayScores,
                builder: (context, scores, _) => Expanded(child: _buildLegend(_blueprint!.radarAxes[0], widget.primaryColor, scores[0]))
              ),
              ValueListenableBuilder<List<double>>(
                valueListenable: _displayScores,
                builder: (context, scores, _) => Expanded(child: _buildLegend(_blueprint!.radarAxes[1], widget.primaryColor, scores[1]))
              ),
              ValueListenableBuilder<List<double>>(
                valueListenable: _displayScores,
                builder: (context, scores, _) => Expanded(child: _buildLegend(_blueprint!.radarAxes[2], widget.primaryColor, scores[2]))
              ),
              ValueListenableBuilder<List<double>>(
                valueListenable: _displayScores,
                builder: (context, scores, _) => Expanded(child: _buildLegend(_blueprint!.radarAxes[3], widget.primaryColor, scores[3]))
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, double score) {
    return Column(
      children: [
        AutoSizeText(
          label.toUpperCase(),
          maxLines: 1,
          minFontSize: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9.sp,
            fontWeight: FontWeight.w800,
            color: widget.isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4.h),
        AutoSizeText(
          '${(score * 100).toInt()}%',
          maxLines: 1,
          minFontSize: 8,
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
}

class _RadarChartPainter extends CustomPainter {
  final List<double> scores;
  final Color primaryColor;
  final bool isDark;
  final double bgAnimValue;

  _RadarChartPainter({
    required this.scores,
    required this.primaryColor,
    required this.isDark,
    required this.bgAnimValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width / 2, size.height / 2) - 20) * bgAnimValue;
    if (radius <= 0) return; // Prevent drawing when completely scaled down

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

    // Calculate max possible radius for actual data layer
    final maxRadius = math.min(size.width / 2, size.height / 2) - 20;

    // Draw data polygon
    final dataPath = Path();
    for (int j = 0; j < 4; j++) {
      final angle = (j * math.pi / 2) - (math.pi / 2);
      final r = maxRadius * scores[j];
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
      final r = maxRadius * scores[j];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return bgAnimValue != oldDelegate.bgAnimValue ||
           !listEquals(oldDelegate.scores, scores) ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.isDark != isDark;
  }
}
