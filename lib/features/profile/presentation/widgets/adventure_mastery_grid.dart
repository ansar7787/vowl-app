import 'package:vowl/core/theme/illustration_colors.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/theme/app_colors.dart';

@immutable
class _MasteryCategory {
  final String id;
  final String name;
  final IconData icon;
  final int progress;
  final int levelsCompleted;
  final Color color;

  const _MasteryCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.progress,
    required this.levelsCompleted,
    required this.color,
  });
}

class AdventureMasteryGrid extends StatelessWidget {
  final UserEntity user;

  const AdventureMasteryGrid({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = QuestType.values.map((type) {
      final name = type.name;
      final displayTitle = name[0].toUpperCase() + name.substring(1);

      int levelsCompleted = 0;
      for (final subtype in type.subtypes) {
        final completed = user.completedLevels[subtype.name] ?? [];
        levelsCompleted += completed.length;
      }

      final maxLevels = type.subtypes.length * 200;
      // Sqrt-based progress for meaningful early feedback.
      // Raw 1% (20/2000) → displayed 10%. Raw 25% → 50%.
      final rawProg = maxLevels > 0 ? (levelsCompleted / maxLevels) : 0.0;
      final actualProg = (sqrt(rawProg) * 100).toInt().clamp(0, 100);

      IconData icon;
      Color color;
      switch (type) {
        case QuestType.speaking:
          icon = Icons.mic_rounded;
          color = AppColors.red500;
        case QuestType.listening:
          icon = Icons.headphones_rounded;
          color = const Color(0xFF06B6D4);
        case QuestType.reading:
          icon = Icons.menu_book_rounded;
          color = AppColors.blue500;
        case QuestType.writing:
          icon = Icons.edit_rounded;
          color = AppColors.emerald500;
        case QuestType.grammar:
          icon = Icons.book_rounded;
          color = AppColors.violet500;
        case QuestType.vocabulary:
          icon = Icons.psychology_rounded;
          color = AppColors.amber500;
        case QuestType.accent:
          icon = Icons.graphic_eq_rounded;
          color = AppColors.rose500;
        case QuestType.roleplay:
          icon = Icons.groups_rounded;
          color = AppColors.indigo500;
        case QuestType.eliteMastery:
          icon = Icons.workspace_premium_rounded;
          color = AppColors.gold;
      }

      return _MasteryCategory(
        id: type.serializedName,
        name: displayTitle,
        icon: icon,
        progress: actualProg,
        levelsCompleted: levelsCompleted,
        color: color,
      );
    }).toList();

    // ── Kids category ──
    final kidsMaxLevels = 12 * 200;
    final kidsRawProg = kidsMaxLevels > 0
        ? (user.kidsTotalLevelsCompleted / kidsMaxLevels)
        : 0.0;
    final kidsProg = (sqrt(kidsRawProg) * 100).toInt().clamp(0, 100);

    categories.add(
      _MasteryCategory(
        id: 'kids',
        name: 'Kids',
        icon: Icons.child_care_rounded,
        progress: kidsProg,
        levelsCompleted: user.kidsTotalLevelsCompleted,
        color: IllustrationColors.vibrantPink,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            'adventure.language_mastery',
            fallback: 'LANGUAGE MASTERY',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : AppColors.slate500,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 16.r),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.r,
            crossAxisSpacing: 12.r,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];

            String levelLabel;
            if (cat.progress >= 80) {
              levelLabel = context.tr(
                'adventure.tier_master',
                fallback: 'Master',
              );
            } else if (cat.progress >= 60) {
              levelLabel = context.tr(
                'adventure.tier_expert',
                fallback: 'Expert',
              );
            } else if (cat.progress >= 40) {
              levelLabel = context.tr(
                'adventure.tier_adept',
                fallback: 'Adept',
              );
            } else if (cat.progress >= 20) {
              levelLabel = context.tr(
                'adventure.tier_novice',
                fallback: 'Novice',
              );
            } else {
              levelLabel = context.tr(
                'adventure.tier_beginner',
                fallback: 'Beginner',
              );
            }

            return Semantics(
              label:
                  '${cat.name}, ${cat.progress}% ${context.tr('adventure.progress', fallback: 'progress')}, $levelLabel, ${cat.levelsCompleted} ${context.tr('adventure.levels', fallback: 'levels')}',
              child: ScaleButton(
                onTap: () {
                  if (cat.id == 'kids') {
                    context.push(AppRouter.kidsZoneRoute);
                  } else {
                    context.push(
                      '${AppRouter.categoryGamesRoute}?category=${cat.id}',
                    );
                  }
                },
                child: GlassTile(
                  blur: 0, // Performance: skip BackdropFilter in grid
                  padding: EdgeInsets.all(16.r),
                  borderRadius: BorderRadius.circular(24.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(cat.icon, size: 18.r, color: cat.color),
                          ),
                          const Spacer(),
                          Text(
                            '${cat.progress}%',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: cat.color,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate800,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${cat.levelsCompleted} ${context.tr('adventure.levels_dot', fallback: 'levels ·')} ',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          Text(
                            levelLabel,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: cat.color.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.r),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          value: cat.progress / 100,
                          backgroundColor: cat.color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                          minHeight: 6.r,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
