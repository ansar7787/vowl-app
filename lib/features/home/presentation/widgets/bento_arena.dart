import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Bento arena curriculum hub showcasing the 9 sequential language disciplines.
///
/// Features:
/// 1. Top Spotlight Focus Hero Card (Active or Foundational Discipline).
/// 2. 2-Column Bento Subgrid with subtle authentic category-tinted borders.
/// 3. The Discipline Bubble Dock: interactive toggle displaying upcoming category
///    bubbles with harmonized colors, haptic feedback, and smooth expansion.
class BentoArena extends StatefulWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Whether the arena begins in compact/collapsed mode.
  final bool collapsed;

  /// Creates a [BentoArena] instance.
  const BentoArena({super.key, required this.user, this.collapsed = false});

  /// Canonical sequential learning journey order across all 9 disciplines.
  static const List<QuestType> journeySteps = [
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

  /// Returns the human-readable, title-cased display title for a [QuestType].
  static String formatCategoryTitle(QuestType type) {
    switch (type) {
      case QuestType.vocabulary:
        return 'Vocabulary';
      case QuestType.listening:
        return 'Listening';
      case QuestType.reading:
        return 'Reading';
      case QuestType.grammar:
        return 'Grammar';
      case QuestType.writing:
        return 'Writing';
      case QuestType.speaking:
        return 'Speaking';
      case QuestType.accent:
        return 'Accent';
      case QuestType.roleplay:
        return 'Roleplay';
      case QuestType.eliteMastery:
        return 'Elite Mastery';
    }
  }

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

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  /// Returns the index of the first uncompleted discipline in the curriculum.
  int _getFocusIndex() {
    final steps = BentoArena.journeySteps;
    for (int i = 0; i < steps.length; i++) {
      final cleared = widget.user.getTotalCategoryLevelsCleared(steps[i]);
      final max = widget.user.getMaxCategoryLevels(steps[i]);
      if (max > 0 && cleared < max) {
        return i;
      }
    }
    return 0;
  }

  void _triggerHaptic() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
  }

  void _navigateToCategory(BuildContext context, QuestType type) {
    _triggerHaptic();
    context.push(
      '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(type.name)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focusIndex = _getFocusIndex();
    final allSteps = BentoArena.journeySteps;

    // Step 1: Foundational / Hero Discipline
    final heroStep = allSteps[0];
    final isHeroFocus = focusIndex == 0;

    // Steps 2 to 5: Core 2x2 Bento Disciplines
    final coreSteps = allSteps.sublist(1, 5);

    // Steps 6 to 9: Advanced Disciplines (in dock when collapsed, in grid when expanded)
    final advancedSteps = allSteps.sublist(5);

    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, _) {
        return Padding(
          padding: EdgeInsets.only(top: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LEAD FOCUS HERO CARD (Step 1)
              _BentoHeroCard(
                type: heroStep,
                user: widget.user,
                step: 1,
                totalSteps: allSteps.length,
                isCurrentFocus: isHeroFocus,
                onTap: () => _navigateToCategory(context, heroStep),
              ),
              SizedBox(height: 10.h),

            // 2. 2-COLUMN BENTO SUBGRID (Steps 2 to 5, plus Steps 6 to 9 when expanded)
            _BentoSubgrid(
              steps: isExpanded ? allSteps.sublist(1) : coreSteps,
              user: widget.user,
              focusIndex: focusIndex,
              onCategoryTap: (type) => _navigateToCategory(context, type),
            ),

            // 3. THE DISCIPLINE BUBBLE DOCK (Expander Toggle & Teaser Bubbles)
            if (widget.collapsed) ...[
              SizedBox(height: 12.h),
              _DisciplineBubbleDock(
                isExpanded: isExpanded,
                advancedSteps: advancedSteps,
                isDark: isDark,
                onToggleExpand: () {
                  _triggerHaptic();
                  _isExpanded.value = !_isExpanded.value;
                },
                onCategoryTap: (type) => _navigateToCategory(context, type),
              ),
            ],
          ],
        ),
      );
    },
  );
  }
}

/// The prominent Hero Card for the foundational discipline (Step 1).
class _BentoHeroCard extends StatelessWidget {
  final QuestType type;
  final UserEntity user;
  final int step;
  final int totalSteps;
  final bool isCurrentFocus;
  final VoidCallback onTap;

  const _BentoHeroCard({
    required this.type,
    required this.user,
    required this.step,
    required this.totalSteps,
    required this.isCurrentFocus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = GameHelper.getCategoryColor(type.name);
    final icon = GameHelper.getIconForCategory(type);
    final totalCleared = user.getTotalCategoryLevelsCleared(type);
    final maxLevels = user.getMaxCategoryLevels(type);
    final progress =
        maxLevels > 0 ? (totalCleared / maxLevels).clamp(0.0, 1.0) : 0.0;
    final isCompleted = maxLevels > 0 && totalCleared >= maxLevels;
    final categoryName = BentoArena.formatCategoryTitle(type);

    final stepLabel = context.tr(
      'home.step',
      fallback: 'Step',
      args: [step.toString()],
    );
    final levelsLabel = context.tr(
      'home.levels_cleared_max',
      fallback: '$totalCleared of $maxLevels Levels Cleared',
      args: [totalCleared.toString(), maxLevels.toString()],
    );

    return Semantics(
      button: true,
      label: '$stepLabel $categoryName. $levelsLabel',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.30 : 0.22),
              width: 1.2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.10 : 0.05),
                blurRadius: 18.r,
                offset: Offset(0, 6.r),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Pill
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.emerald500.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              )
                            : color.withValues(alpha: isDark ? 0.14 : 0.08),
                        borderRadius: BorderRadius.circular(100.r),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.emerald500.withValues(
                                  alpha: isDark ? 0.35 : 0.25,
                                )
                              : color.withValues(alpha: isDark ? 0.32 : 0.22),
                          width: 1.r,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompleted) ...[
                            Icon(
                              Icons.check_circle_rounded,
                              size: 12.r,
                              color: AppColors.emerald500,
                            ),
                            SizedBox(width: 4.w),
                          ] else if (isCurrentFocus) ...[
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 4.r,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 5.w),
                          ],
                          Flexible(
                            child: Text(
                              isCompleted
                                  ? 'COMPLETED'
                                  : isCurrentFocus
                                  ? 'CURRENT FOCUS'
                                  : 'STEP $step',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isCompleted ? AppColors.emerald500 : color,
                                letterSpacing: 0.6,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Step Indicator
                  Text(
                    'Step $step of $totalSteps',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Middle Body Row (Icon + Titles)
              Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.30 : 0.20),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 24.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$categoryName Arena',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate900,
                            letterSpacing: -0.2,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          levelsLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Bottom Progress Bar Row (Solid Color - No Gradients)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Curriculum Progress',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.slate200,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color, // Authentic Solid Category Color
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2-Column Bento Subgrid rendering curriculum discipline tiles.
class _BentoSubgrid extends StatelessWidget {
  final List<QuestType> steps;
  final UserEntity user;
  final int focusIndex;
  final ValueChanged<QuestType> onCategoryTap;

  const _BentoSubgrid({
    required this.steps,
    required this.user,
    required this.focusIndex,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < steps.length; i += 2) {
      final leftType = steps[i];
      final rightType = (i + 1 < steps.length) ? steps[i + 1] : null;

      // Find real canonical step index (1-based)
      final leftCanonicalIndex = BentoArena.journeySteps.indexOf(leftType) + 1;
      final rightCanonicalIndex = rightType != null
          ? BentoArena.journeySteps.indexOf(rightType) + 1
          : null;

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Row(
            children: [
              Expanded(
                child: _BentoGridCell(
                  type: leftType,
                  user: user,
                  step: leftCanonicalIndex,
                  isCurrentFocus: (leftCanonicalIndex - 1) == focusIndex,
                  onTap: () => onCategoryTap(leftType),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: rightType != null
                    ? _BentoGridCell(
                        type: rightType,
                        user: user,
                        step: rightCanonicalIndex!,
                        isCurrentFocus: (rightCanonicalIndex - 1) == focusIndex,
                        onTap: () => onCategoryTap(rightType),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// Inset Bento Cell representing a single discipline in the 2-column grid.
class _BentoGridCell extends StatelessWidget {
  final QuestType type;
  final UserEntity user;
  final int step;
  final bool isCurrentFocus;
  final VoidCallback onTap;

  const _BentoGridCell({
    required this.type,
    required this.user,
    required this.step,
    required this.isCurrentFocus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = GameHelper.getCategoryColor(type.name);
    final icon = GameHelper.getIconForCategory(type);
    final totalCleared = user.getTotalCategoryLevelsCleared(type);
    final maxLevels = user.getMaxCategoryLevels(type);
    final progress =
        maxLevels > 0 ? (totalCleared / maxLevels).clamp(0.0, 1.0) : 0.0;
    final isCompleted = maxLevels > 0 && totalCleared >= maxLevels;
    final categoryName = BentoArena.formatCategoryTitle(type);

    final stepLabel = context.tr(
      'home.step',
      fallback: 'Step',
      args: [step.toString()],
    );
    final levelsLabel = context.tr(
      'home.levels_cleared_max',
      fallback: '$totalCleared / $maxLevels Cleared',
      args: [totalCleared.toString(), maxLevels.toString()],
    );

    return Semantics(
      button: true,
      label: '$stepLabel $categoryName. $levelsLabel',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 104.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.30 : 0.22),
              width: 1.2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 10.r,
                offset: Offset(0, 3.r),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Cell Header (Halo Icon + Step Pill)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.25 : 0.16),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 16.r),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.emerald500.withValues(
                                alpha: isDark ? 0.15 : 0.10,
                              )
                            : color.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        isCompleted
                            ? '✓ DONE'
                            : isCurrentFocus
                            ? 'FOCUS'
                            : 'STEP $step',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? AppColors.emerald500 : color,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Title & Levels Count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    levelsLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              SizedBox(height: 6.h),

              // Solid Progress Line
              Container(
                height: 4.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.slate200,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color, // Solid Category Color
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Discipline Bubble Dock: interactive expander shelf showing upcoming discipline bubbles.
class _DisciplineBubbleDock extends StatelessWidget {
  final bool isExpanded;
  final List<QuestType> advancedSteps;
  final bool isDark;
  final VoidCallback onToggleExpand;
  final ValueChanged<QuestType> onCategoryTap;

  const _DisciplineBubbleDock({
    required this.isExpanded,
    required this.advancedSteps,
    required this.isDark,
    required this.onToggleExpand,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.slate200,
          width: 1.r,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 3.r),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title & Subtitle on left, Pill Button on right
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8.h,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded ? 'All 9 Arenas Active' : 'More Arenas',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    isExpanded
                        ? 'Tap to collapse view'
                        : '${advancedSteps.length} arenas ready to explore',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              ScaleButton(
                onTap: onToggleExpand,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(
                        alpha: isDark ? 0.35 : 0.25,
                      ),
                      width: 1.r,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isExpanded
                              ? context.tr(
                                  'home.show_less',
                                  fallback: 'Show Less',
                                )
                              : context.tr(
                                  'home.see_all_categories',
                                  fallback: 'See All 9 Categories',
                                ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.indigo500,
                          size: 16.r,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Discipline Bubbles Row (Visible only in collapsed mode)
          if (!isExpanded) ...[
            SizedBox(height: 10.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: advancedSteps.map((type) {
                  final color = GameHelper.getCategoryColor(type.name);
                  final icon = GameHelper.getIconForCategory(type);
                  final categoryName =
                      BentoArena.formatCategoryTitle(type);

                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Semantics(
                      button: true,
                      label: '$categoryName discipline',
                      child: ScaleButton(
                        onTap: () => onCategoryTap(type),
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: isDark ? 0.14 : 0.10),
                            border: Border.all(
                              color: color.withValues(
                                alpha: isDark ? 0.30 : 0.22,
                              ),
                              width: 1.2.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: isDark ? 0.15 : 0.08,
                                ),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.r),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: color, // Category Color Matched
                              size: 18.r,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
