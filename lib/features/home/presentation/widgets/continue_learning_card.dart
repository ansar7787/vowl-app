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
            padding: EdgeInsets.all(24.r),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category icon
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28.r),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Keep it as short as possible
                    children: [
                      // Category eyebrow
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isNewUser) ...[
                        SizedBox(height: 6.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        SizedBox(height: 12.h),
                        // Sleek minimalist progress bar
                        Stack(
                          children: [
                            Container(
                              height: 6.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child:
                                  Container(
                                    height: 6.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 1,
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
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                // Standard iOS Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 32.r,
                ).animate().slideX(
                  begin: -0.2,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }
}
