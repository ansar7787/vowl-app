
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:collection/collection.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// The single most important element on the home screen.
///
/// Resolves the user's next category to play and presents a prominent
/// "Continue" CTA that answers the #1 user question: "What should I do next?"
///
/// ## Design Philosophy (10/10 Production Standard)
/// 1. **Rich two-tone gradient** with depth — not a flat same-color block.
/// 2. **Large decorative background icon** — breaks the flat surface.
/// 3. **Dynamic motivational subtitle** — streak-aware, progress-aware, time-aware.
/// 4. **Milestone progress** — shows "next milestone" instead of raw total.
/// 5. **StatefulWidget** — caches computation, guards entrance animation.
/// 6. **Subtle background shimmer** — premium alive feel.
/// 7. **Next game preview** — creates anticipation for what's ahead.
/// 8. **Dark mode adaptive** — no hardcoded white assumptions.
/// 9. **Haptic feedback** — physical "click" on tap.
class ContinueLearningCard extends StatefulWidget {
  final UserEntity user;

  const ContinueLearningCard({super.key, required this.user});

  @override
  State<ContinueLearningCard> createState() => _ContinueLearningCardState();
}

class _ContinueLearningCardState extends State<ContinueLearningCard> {
  /// The canonical learning journey order (same as BentoArena).
  static const List<QuestType> _journeyOrder = [
    QuestType.vocabulary,
    QuestType.listening,
    QuestType.reading,
    QuestType.grammar,
    QuestType.writing,
    QuestType.speaking,
    QuestType.accent,
    QuestType.roleplay,
    QuestType.eliteMastery,
  ];


  // ── Cached state ────────────────────────────────────────────────────────
  late QuestType _nextType;
  late int _cleared;
  late int _max;

  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _computeState();
  }

  @override
  void didUpdateWidget(covariant ContinueLearningCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recompute if the user entity actually changed.
    if (oldWidget.user != widget.user) {
      _computeState();
    }
  }

  void _computeState() {
    _nextType = _resolveNextCategory();
    _cleared = widget.user.getTotalCategoryLevelsCleared(_nextType);
    _max = widget.user.getMaxCategoryLevels(_nextType);
  }

  /// Implements a "Hybrid" algorithm for the absolute best UX:
  /// 1. "True Resume": First, checks `recentActivities` to find the exact
  ///    category the user was just playing. If it's not finished, it recommends it.
  /// 2. "Skill Balancing": If they have no recent activities, or they just 100%
  ///    completed their last category, it falls back to recommending the category
  ///    where they have the LOWEST progress, forcing a well-rounded skillset.
  QuestType _resolveNextCategory() {
    if (widget.user.totalLevelsCompleted == 0) return QuestType.vocabulary;

    // 1. "True Resume": Check what they were literally just doing.
    for (final activity in widget.user.recentActivities) {
      if (activity['type'] == 'quest') {
        final gameTypeStr = activity['gameType'] as String?;
        if (gameTypeStr != null) {
          final subtype = GameSubtype.values.firstWhereOrNull(
            (s) => s.name == gameTypeStr,
          );
          if (subtype != null) {
            final type = subtype.category;
            final cleared = widget.user.getTotalCategoryLevelsCleared(type);
            final max = widget.user.getMaxCategoryLevels(type);
            if (max > 0 && cleared < max) {
              return type; // Perfect match: Pick up exactly where they left off.
            }
          }
        }
      }
    }

    // 2. "Skill Balancing": Fallback to the lowest progress category.
    QuestType recommendedType = _journeyOrder.first;
    int lowestCleared = 999999;

    for (final type in _journeyOrder) {
      final cleared = widget.user.getTotalCategoryLevelsCleared(type);
      final max = widget.user.getMaxCategoryLevels(type);

      // Only consider categories that actually have levels available
      if (max > 0) {
        if (cleared < lowestCleared) {
          lowestCleared = cleared;
          recommendedType = type;
        }
      }
    }

    return recommendedType;
  }




  /// Returns the (base, target) milestone dynamically to ensure tight, achievable gaps.
  ({int baseTarget, int target}) _getNextMilestone() {
    int baseTarget = 0;
    int target = 0;
    
    // Dynamic chunk sizes: Keep the gap small and achievable.
    if (_cleared < 50) {
      baseTarget = (_cleared ~/ 10) * 10;
      target = baseTarget + 10;
    } else if (_cleared < 200) {
      baseTarget = (_cleared ~/ 25) * 25;
      target = baseTarget + 25;
    } else if (_cleared < 1000) {
      baseTarget = (_cleared ~/ 50) * 50;
      target = baseTarget + 50;
    } else {
      baseTarget = (_cleared ~/ 100) * 100;
      target = baseTarget + 100;
    }

    if (target > _max && _max > 0) target = _max;

    return (baseTarget: baseTarget, target: target);
  }

  /// Generates a complementary darker shade for the gradient endpoint.
  Color _getDarkerShade(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.08, 0.85))
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final color = GameHelper.getQuestTypeColor(_nextType);
    final darkColor = _getDarkerShade(color);
    final icon = GameHelper.getIconForCategory(_nextType);
    final isNewUser = widget.user.totalLevelsCompleted == 0;

    final categoryLabel = _nextType.name.toUpperCase().replaceAllMapped(
      RegExp('(?<=[a-z])(?=[A-Z])'),
      (m) => ' ',
    );

    final title = isNewUser
        ? context.tr('home.start_your_journey', fallback: 'Start Your Journey')
        : context.tr('home.continue_learning', fallback: 'Continue Learning');



    final milestone = _getNextMilestone();


    final chunkSpan = milestone.target - milestone.baseTarget;
    final progressInChunk = _cleared - milestone.baseTarget;
    
    final milestoneProgress = chunkSpan > 0
        ? (progressInChunk / chunkSpan).clamp(0.0, 1.0)
        : (_cleared >= _max && _max > 0 ? 1.0 : 0.0);

    final semanticLabel = isNewUser
        ? '$title. $categoryLabel.'
        : '$title. $categoryLabel. $_cleared out of ${milestone.target} levels cleared.';

    final card = Semantics(
      button: true,
      label: semanticLabel,
      child: ScaleButton(
        onTap: () {
          try {
            di.sl<HapticService>().selection();
          } catch (_) {}
          context.push(
            '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(_nextType.name)}',
          );
        },
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(22.r),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, darkColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  // Inner glow for depth
                  BoxShadow(
                    color: darkColor.withValues(alpha: 0.2),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // ── Decorative background icon ─────────────────────
                  Positioned(
                    right: -15.r,
                    top: -10.r,
                    child: Icon(
                      icon,
                      size: 120.r,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  // ── Subtle radial glow overlay ─────────────────────
                  Positioned(
                    left: -40.r,
                    bottom: -40.r,
                    child: Container(
                      width: 160.r,
                      height: 160.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ── Main content ───────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Category icon + eyebrow label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category icon in frosted circle
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child:
                                Icon(icon, color: Colors.white, size: 20.r),
                          ),
                          // Category eyebrow pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              categoryLabel,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),


                      // ── Bottom section: Progress + Play button ─────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: isNewUser
                                ? _buildNewUserSection(context)
                                : _buildProgressSection(
                                    context,
                                    milestone.target,
                                    milestoneProgress,
                                  ),
                          ),
                          SizedBox(width: 16.w),
                          // ── Floating Play Button ───────────────────
                          _buildPlayButton(color),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Entrance animation: only fire once, not on every BLoC rebuild.
    if (!_hasAnimated) {
      _hasAnimated = true;
      return card
          .animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.08, end: 0);
    }
    return card;
  }

  /// New user CTA — encourages first interaction.
  Widget _buildNewUserSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 16.r,
            ),
            SizedBox(width: 8.w),
            Text(
              context.tr(
                'home.ready_to_start',
                fallback: 'Ready to launch!',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          context.tr(
            'home.zero_xp_hint',
            fallback: 'Earn your first XP today',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    int target,
    double milestoneProgress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        // Milestone progress header
        Text(
          context.tr(
            'home.cl_levels_target',
            fallback: '$_cleared → $target Levels 🎯',
            args: [
              _cleared.toString(),
              target.toString(),
            ],
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),

        // Milestone progress bar with glow
        RepaintBoundary(
          child: Stack(
            children: [
              // Track
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100.r),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: milestoneProgress.clamp(0.02, 1.0),
                child: Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                )
                    .animate()
                    .scaleX(
                      begin: 0,
                      end: 1,
                      duration: 800.ms,
                      curve: Curves.easeOutQuart,
                      alignment: Alignment.centerLeft,
                    )
                    .then()
                    .shimmer(
                      delay: 400.ms,
                      duration: 1800.ms,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The prominent floating play button with spring animation.
  Widget _buildPlayButton(Color color) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: color,
        size: 26.r,
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 800.ms,
      curve: Curves.easeOutBack,
    );
  }
}
