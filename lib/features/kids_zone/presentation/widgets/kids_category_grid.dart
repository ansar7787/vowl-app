import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/domain/services/kids_game_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color0ea5e9 = Color(0xFF0EA5E9);
}

/// Themed section groupings for the category grid.
/// This transforms the flat wall of 25 cards into a scannable, grouped menu.
class _SectionDef {
  final String title;
  final String emoji;
  final Color color;
  final List<String> gameTypes;

  const _SectionDef(this.title, this.emoji, this.color, this.gameTypes);
}

const _kSections = [
  _SectionDef('Language', '📚', AppColors.rose500, [
    'alphabet',
    'phonics',
    'verbs',
    'opposites',
    'prepositions',
  ]),
  _SectionDef('World', '🌍', AppColors.emerald500, [
    'animals',
    'nature',
    'weather',
    'day_night',
    'transport',
  ]),
  _SectionDef('Life', '🏠', AppColors.violet500, [
    'family',
    'school',
    'routine',
    'emotions',
    'food',
    'home',
  ]),
  _SectionDef('Math & Logic', '🔢', _LocalPalette.color0ea5e9, [
    'numbers',
    'colors',
    'shapes',
    'time',
  ]),
  _SectionDef('Skills', '⭐', AppColors.amber500, [
    'fruits',
    'body_parts',
    'clothing',
    'professions',
  ]),
];

/// Categorized grid displaying all available Kids Zone games grouped by pedagogical domain.
class KidsCategoryGrid extends StatefulWidget {
  /// Whether dark theme styling is active.
  final bool isDark;

  /// Creates a [KidsCategoryGrid] widget.
  const KidsCategoryGrid({super.key, required this.isDark});

  @override
  State<KidsCategoryGrid> createState() => _KidsCategoryGridState();
}

class _KidsCategoryGridState extends State<KidsCategoryGrid> {
  @override
  Widget build(BuildContext context) {
    // Use context.select to only rebuild when completedLevels changes
    final completedLevels = context.select<AuthBloc, Map<String, List<int>>>(
      (bloc) => bloc.state.user?.completedLevels ?? {},
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, sectionIndex) {
        final section = _kSections[sectionIndex];
        final games = section.gameTypes
            .map((type) => KidsGameHelper.getMetadata(type))
            .where((g) => g.gameType != 'unknown')
            .toList();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: EdgeInsets.only(
                  top: sectionIndex == 0 ? 0 : 12.h,
                  bottom: 16.h,
                ),
                child: Row(
                  children: [
                    Text(section.emoji, style: TextStyle(fontSize: 20.sp)),
                    SizedBox(width: 10.w),
                    Text(
                      context.tr(
                        'kids_zone.section_${section.title.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_')}',
                        fallback: section.title,
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark
                            ? Colors.white70
                            : AppColors.slate600,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: 2.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              section.color.withValues(alpha: 0.5),
                              section.color.withValues(alpha: 0.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (sectionIndex * 80).ms),

              // Grid of cards for this section
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20.h,
                  crossAxisSpacing: 20.w,
                  childAspectRatio: 0.85,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final gameLevels = completedLevels[game.gameType] ?? [];
                  final totalLevels = CurriculumManifest.getKidsLevels(
                    game.gameType,
                  );
                  final completedCount = gameLevels.length;
                  final highestCompleted = gameLevels.isEmpty
                      ? 0
                      : gameLevels.reduce(math.max);
                  final isMastered = completedCount >= totalLevels;
                  final currentLevel = isMastered
                      ? totalLevels
                      : math.min(totalLevels, highestCompleted + 1);

                  return _buildCategoryCard(
                    context,
                    () => context.push(
                      '/kids/map/${game.gameType}',
                      extra: {
                        'title': game.fullTitle,
                        'primaryColor': game.color,
                      },
                    ),
                    game.gridTitle,
                    game.subtitle,
                    game.color,
                    game.icon,
                    currentLevel: currentLevel,
                    completedCount: completedCount,
                    totalLevels: totalLevels,
                    isMastered: isMastered,
                  );
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      }, childCount: _kSections.length),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    VoidCallback onTap,
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    required int currentLevel,
    required int completedCount,
    required int totalLevels,
    required bool isMastered,
    Widget? trailing,
  }) {
    return Semantics(
      button: true,
      label: isMastered
          ? '$title, ${context.tr('category_games.mastered', fallback: 'Mastered')}! $totalLevels of $totalLevels'
          : (completedCount == 0
                ? '$title, ${context.tr('quest_archive.new_badge', fallback: 'New')} adventure'
                : '$title, ${context.tr('quest_archive.level', fallback: 'Level $currentLevel', args: [currentLevel.toString()])}, $completedCount of $totalLevels completed'),
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color:
                (widget.isDark &&
                    Theme.of(context).scaffoldBackgroundColor == Colors.black)
                ? AppColors.midnightSurface
                : (widget.isDark ? AppColors.slate800 : Colors.white),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: color, width: 3.w),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(icon, color: color, size: 32.sp),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: _buildProgressBadge(
                      context: context,
                      color: color,
                      currentLevel: currentLevel,
                      completedCount: completedCount,
                      totalLevels: totalLevels,
                      isMastered: isMastered,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          title,
                          maxLines: 2,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: widget.isDark
                                ? Colors.white
                                : AppColors.slate800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[SizedBox(width: 4.w), trailing],
                    ],
                  ),
                  AutoSizeText(
                    subtitle,
                    maxLines: 1,
                    minFontSize: 8,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBadge({
    required BuildContext context,
    required Color color,
    required int currentLevel,
    required int completedCount,
    required int totalLevels,
    required bool isMastered,
  }) {
    if (isMastered) {
      return Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.amber400, AppColors.amber600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber500.withValues(alpha: 0.4),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(
          Icons.emoji_events_rounded,
          color: Colors.white,
          size: 20.r,
        ),
      );
    }

    if (completedCount == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5.w),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('quest_archive.new_badge', fallback: 'NEW'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    final progress = (completedCount / totalLevels).clamp(0.0, 1.0);
    return SizedBox(
      width: 38.r,
      height: 38.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 38.r,
            height: 38.r,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress,
                color: color,
                trackColor: color.withValues(alpha: 0.15),
                strokeWidth: 3.5.r,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LV',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.75),
                  height: 1.0,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$currentLevel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: currentLevel >= 100 ? 9.5.sp : 11.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lightweight progress ring painter for per-category completion indicators.
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}


