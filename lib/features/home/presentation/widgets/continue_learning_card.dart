import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
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

  /// Finds the first category that isn't 100% completed, or falls back
  /// to vocabulary if everything is done.
  QuestType _resolveNextCategory() {
    for (final type in _journeyOrder) {
      final cleared = user.getTotalCategoryLevelsCleared(type);
      final max = user.getMaxCategoryLevels(type);
      if (max > 0 && cleared < max) return type;
    }
    // All complete — loop back to the beginning
    return QuestType.vocabulary;
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
            padding: EdgeInsets.all(16.r),
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
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 20.r),
                    ),
                    // Category eyebrow
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
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
                SizedBox(height: 12.h),
                // Title given full horizontal width
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 8.h),
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
                SizedBox(height: 16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: isNewUser
                          ? const SizedBox.shrink()
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
                                SizedBox(height: 12.h),
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
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
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
                    if (!isNewUser) SizedBox(width: 20.w),
                    // Floating Action Play Button
                    Container(
                      padding: EdgeInsets.all(12.r),
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
                        size: 28.r,
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
