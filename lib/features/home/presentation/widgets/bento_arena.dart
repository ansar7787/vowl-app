import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class BentoArena extends StatelessWidget {
  const BentoArena({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final types = [
      QuestType.vocabulary, // Step 1: Words
      QuestType.listening, // Step 2: Input
      QuestType.reading, // Step 3: Literacy
      QuestType.grammar, // Step 4: Structure
      QuestType.writing, // Step 5: Output
      QuestType.speaking, // Step 6: Fluency
      QuestType.accent, // Step 7: Polish
      QuestType.roleplay, // Step 8: Mastery
      QuestType.eliteMastery, // Step 9: Legendary
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // The Journey Path Line
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: JourneyPathPainter(
                    isDark: isDark,
                    stepsCount: types.length,
                    types: types,
                  ),
                ),
              ),
            ),
            // The Step Cards
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: List.generate(types.length, (index) {
                  final isLeft = index % 2 == 0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: Align(
                      alignment: isLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.85,
                        child: _BentoCategoryTile(
                          type: types[index],
                          user: user,
                          step: index + 1,
                          isLeft: isLeft,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCategoryTile extends StatelessWidget {
  const _BentoCategoryTile({
    required this.type,
    required this.user,
    required this.step,
    required this.isLeft,
  });

  final QuestType type;
  final UserEntity user;
  final int step;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = GameHelper.getCategoryColor(type.name);
    final icon = GameHelper.getIconForCategory(type);
    final totalCleared = user.getTotalCategoryLevelsCleared(type);
    final maxLevels = user.getMaxCategoryLevels(type);

    // Progress matches the text exactly (total / max)
    final progress = maxLevels > 0 ? (totalCleared / maxLevels) : 0.0;

    return ScaleButton(
      onTap: () =>
          context.push('${AppRouter.categoryGamesRoute}?category=${type.name}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.r),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.05)
                      : color.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                if (!isLeft) const Spacer(),
                // Icon Container with Pulse
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 26.r),
                ),
                SizedBox(width: 20.w),
                // Content Section
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: isLeft
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      // Step Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                          border:
                              Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'STEP $step',
                          style: GoogleFonts.outfit(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Title
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          type.name.toUpperCase(),
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: 1.2,
                            height: 1,
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),
                      // Progress
                      _bentoProgressLine(context, progress, color),
                      SizedBox(height: 6.h),
                      Text(
                        '$totalCleared / $maxLevels LEVELS',
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLeft) const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bentoProgressLine(
    BuildContext context,
    double progress,
    Color color,
  ) {
    return Container(
      height: 4.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: FractionallySizedBox(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: progress.clamp(
          0.02,
          1.0,
        ), // Minimum 2% visibility so it's never completely invisible
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }
}

class JourneyPathPainter extends CustomPainter {
  final bool isDark;
  final int stepsCount;
  final List<QuestType> types;

  JourneyPathPainter({
    required this.isDark,
    required this.stepsCount,
    required this.types,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stepHeight = size.height / stepsCount;
    final List<Offset> points = [];

    // 1. Calculate Points
    for (int i = 0; i < stepsCount; i++) {
      final isLeft = i % 2 == 0;
      final x = isLeft ? size.width * 0.15 : size.width * 0.85;
      final y = (i * stepHeight) + (stepHeight / 2);
      points.add(Offset(x, y));
    }

    // 2. Draw the Triple Fiber-Optic Path
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final c1 = GameHelper.getCategoryColor(types[i].name);
      final c2 = GameHelper.getCategoryColor(types[i + 1].name);

      final segmentPath = Path();
      segmentPath.moveTo(p1.dx, p1.dy);
      final midY = (p1.dy + p2.dy) / 2;
      segmentPath.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);

      // We still use a slight fade for extra smoothness, but the "Solid Mask" will do the heavy lifting
      final List<Color> colors = [
        c1.withValues(alpha: 0.1),
        c1.withValues(alpha: 0.4),
        c2.withValues(alpha: 0.4),
        c2.withValues(alpha: 0.1),
      ];
      final stops = [0.0, 0.2, 0.8, 1.0];

      final basePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: colors,
          stops: stops,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(p1, p2));

      // --- Draw 3 Sharp Fiber Lines ---

      // 1. Center Core
      canvas.drawPath(segmentPath, basePaint..strokeWidth = 2.r);

      // 2. Left Fiber
      canvas.save();
      canvas.translate(-5.w, 0);
      canvas.drawPath(
        segmentPath,
        basePaint
          ..strokeWidth = 0.8.r
          ..shader = LinearGradient(
            colors: colors.map((c) => c.withValues(alpha: c.a * 0.5)).toList(),
            stops: stops,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromPoints(p1, p2)),
      );
      canvas.restore();

      // 3. Right Fiber
      canvas.save();
      canvas.translate(5.w, 0);
      canvas.drawPath(segmentPath, basePaint..strokeWidth = 0.8.r);
      canvas.restore();
    }

    // 3. Draw Nodes (Glow Dots)
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final c = GameHelper.getCategoryColor(types[i].name);

      canvas.drawCircle(
        p,
        12.r,
        Paint()
          ..color = c.withValues(alpha: 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.r),
      );

      canvas.drawCircle(p, 5.r, Paint()..color = c.withValues(alpha: 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant JourneyPathPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
