import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:collection/collection.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// The single most important element on the home screen.
///
/// Resolves the user's next category to play and presents a prominent
/// "Continue" CTA that answers the #1 user question: "What should I do next?"
class ContinueLearningCard extends StatelessWidget {
  final UserEntity user;

  const ContinueLearningCard({super.key, required this.user});

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

  /// Implements a "Hybrid" algorithm for the absolute best UX:
  /// 1. "True Resume": First, checks `recentActivities` to find the exact
  ///    category the user was just playing. If it's not finished, it recommends it.
  /// 2. "Skill Balancing": If they have no recent activities, or they just 100%
  ///    completed their last category, it falls back to recommending the category
  ///    where they have the LOWEST progress, forcing a well-rounded skillset.
  QuestType _resolveNextCategory() {
    if (user.totalLevelsCompleted == 0) return QuestType.vocabulary;

    // 1. "True Resume": Check what they were literally just doing.
    for (final activity in user.recentActivities) {
      if (activity['type'] == 'quest') {
        final gameTypeStr = activity['gameType'] as String?;
        if (gameTypeStr != null) {
          final subtype = GameSubtype.values.firstWhereOrNull(
            (s) => s.name == gameTypeStr,
          );
          if (subtype != null) {
            final type = subtype.category;
            final cleared = user.getTotalCategoryLevelsCleared(type);
            final max = user.getMaxCategoryLevels(type);
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
      final cleared = user.getTotalCategoryLevelsCleared(type);
      final max = user.getMaxCategoryLevels(type);

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

  @override
  Widget build(BuildContext context) {
    final nextType = _resolveNextCategory();
    final color = GameHelper.getQuestTypeColor(nextType);
    final icon = GameHelper.getIconForCategory(nextType);
    final cleared = user.getTotalCategoryLevelsCleared(nextType);
    final max = user.getMaxCategoryLevels(nextType);
    final progress = max > 0 ? (cleared / max).clamp(0.0, 1.0) : 0.0;
    final isNewUser = user.totalLevelsCompleted == 0;

    final categoryLabel = nextType.name.toUpperCase().replaceAllMapped(
      RegExp('(?<=[a-z])(?=[A-Z])'),
      (m) => ' ',
    );

    final title = isNewUser
        ? context.tr('home.start_your_journey', fallback: 'Start Your Journey')
        : context.tr('home.continue_learning', fallback: 'Continue Learning');
    final subtitle = isNewUser
        ? context.tr(
            'home.first_lesson_prompt',
            fallback: 'Begin with Vocabulary basics',
          )
        : context.tr(
            'home.continue_category',
            fallback: categoryLabel,
            args: [categoryLabel, cleared.toString(), max.toString()],
          );

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ScaleButton(
        onTap: () => context.push(
          '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(nextType.name)}',
        ),
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)],
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
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category icon
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 18.r),
                    ),
                    // Category eyebrow
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Title given full horizontal width
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
                SizedBox(height: 4.h),
                if (isNewUser)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: isNewUser
                          ? Column(
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
                                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                                SizedBox(height: 8.h),
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
                                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.tr(
                                        'home.level_progress',
                                        fallback: 'Level Progress',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Text(
                                        '$cleared / $max',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                // Diamond standard glowing progress bar
                                Stack(
                                  children: [
                                    Container(
                                      height: 14.h,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child:
                                          Container(
                                            height: 14.h,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ).animate().scaleX(
                                            begin: 0,
                                            end: 1,
                                            duration: 800.ms,
                                            curve: Curves.easeOutQuart,
                                            alignment: Alignment.centerLeft,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    SizedBox(width: 20.w),
                    // Floating Action Play Button
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color:
                            color, // The icon takes the dynamic category color
                        size: 26.r,
                      ),
                    ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }
}
