import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/locale_service.dart';

class BentoArena extends StatefulWidget {
  const BentoArena({super.key, required this.user, this.collapsed = false});

  final UserEntity user;
  final bool collapsed;

  static const List<QuestType> _journeySteps = [
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

  @override
  State<BentoArena> createState() => _BentoArenaState();
}

class _BentoArenaState extends State<BentoArena> {
  late final ValueNotifier<bool> _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = ValueNotifier(!widget.collapsed);
  }

  /// Returns the indices of the 3 categories to show in collapsed mode:
  /// the first uncompleted category and its neighbors.
  List<int> _getCollapsedIndices() {
    final steps = BentoArena._journeySteps;
    // Find first uncompleted category
    int focusIndex = 0;
    for (int i = 0; i < steps.length; i++) {
      final cleared = widget.user.getTotalCategoryLevelsCleared(steps[i]);
      final max = widget.user.getMaxCategoryLevels(steps[i]);
      if (max > 0 && cleared < max) {
        focusIndex = i;
        break;
      }
    }
    // Show: previous, current, next (clamped to bounds)
    final start = (focusIndex - 1).clamp(0, steps.length - 3);
    return [start, start + 1, start + 2];
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final allSteps = BentoArena._journeySteps;

    // Determine which steps to render
    final collapsedIndices = _getCollapsedIndices();

    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, _) {
        final visibleSteps = isExpanded
            ? List.generate(allSteps.length, (i) => i)
            : collapsedIndices;

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
                    isRtl: isRtl,
                    stepsCount: visibleSteps.length,
                    types: visibleSteps.map((i) => allSteps[i]).toList(),
                  ),
                ),
              ),
            ),
            // The Step Cards
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: List.generate(visibleSteps.length, (vi) {
                  final actualIndex = visibleSteps[vi];
                  final isLeft = vi % 2 == 0;
                  final isLast = vi == visibleSteps.length - 1;
                  // Mirror the zig-zag so the journey still visually winds
                  // from the reading-start side in RTL locales.
                  final visualLeft = isRtl ? !isLeft : isLeft;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 40.h),
                    child: Align(
                      alignment: visualLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.85,
                        child: _BentoCategoryTile(
                          type: allSteps[actualIndex],
                          user: widget.user,
                          step: actualIndex + 1,
                          isLeft: visualLeft,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        // Expand / Collapse button
        if (widget.collapsed) ...[
          SizedBox(height: 16.h),
          Center(
            child: ScaleButton(
              onTap: () => _isExpanded.value = !_isExpanded.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded
                          ? context.tr('home.show_less', fallback: 'Show Less')
                          : context.tr(
                              'home.see_all_categories',
                              fallback: 'See All 9 Categories',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6366F1),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.7),
                        size: 20.r,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ],
      );
      },
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
    final stepLabel = context.tr(
      'home.step',
      fallback: 'Step',
      args: [step.toString()],
    );
    final levelsLabel = context.tr(
      'home.levels_cleared_max',
      fallback: 'Max Levels Cleared',
      args: [totalCleared.toString(), maxLevels.toString()],
    );

    return Semantics(
      button: true,
      label: '$stepLabel ${type.name}. $levelsLabel',
      child: ScaleButton(
        onTap: () => context.push(
          '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(type.name)}',
        ),
        child: ExcludeSemantics(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
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
                        : [Colors.white, Colors.white.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                    width: 1.5,
                  ),
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
                    if (isLeft) ...[
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
                    ],
                    // Content Section
                    Expanded(
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
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              stepLabel,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Title
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: isLeft
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Text(
                              type.name.toUpperCase(),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
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
                            levelsLabel,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isLeft) ...[
                      SizedBox(width: 20.w),
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
                    ],
                  ],
                ),
              ),
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
  final bool isRtl;
  final int stepsCount;
  final List<QuestType> types;

  JourneyPathPainter({
    required this.isDark,
    required this.isRtl,
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
      final visualLeft = isRtl ? !isLeft : isLeft;
      final x = visualLeft ? size.width * 0.15 : size.width * 0.85;
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
      oldDelegate.isDark != isDark ||
      oldDelegate.isRtl != isRtl ||
      oldDelegate.stepsCount != stepsCount ||
      !listEquals(oldDelegate.types, types);
}
