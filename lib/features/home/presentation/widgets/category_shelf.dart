import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';

class CategoryShelf extends StatelessWidget {
  const CategoryShelf({super.key, required this.user, required this.subtypes});

  final UserEntity user;
  final List<GameSubtype> subtypes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 215.h,
      // This shelf uses a fixed card height by design (horizontal carousel).
      // Clamp only the *local* text scale so very large OS accessibility
      // settings (2.0x-3.0x) can't blow out these fixed-height cards, while
      // the rest of the app still scales freely with the system setting.
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: RepaintBoundary(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: subtypes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: _GameEntryCard(subtype: subtypes[index], user: user),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameEntryCard extends StatelessWidget {
  const _GameEntryCard({required this.subtype, required this.user});

  final GameSubtype subtype;
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = GameHelper.getGameMetadata(subtype, isDark: isDark);
    final displayColor = isDark
        ? metadata.color
        : HSLColor.fromColor(metadata.color).withLightness(0.4).toColor();
    final category = GameHelper.getCategoryForSubtype(subtype);

    return Semantics(
      button: true,
      label: '${metadata.title}, ${metadata.categoryName}',
      child: ScaleButton(
        onTap: () {
          context.push(
            '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
          );
        },
        child: ExcludeSemantics(
          child: GlassTile(
            width: 150.w,
            borderRadius: BorderRadius.circular(30.r),
            padding: EdgeInsets.all(18.r),
            usePremiumStyle: true,
            showShadow: false, // Remove unwanted glow/shadow between cards
            glassOpacity:
                0.15, // Slightly higher opacity to hide background 'splashes'
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: displayColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: displayColor.withValues(alpha: 0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        metadata.icon,
                        color: displayColor,
                        size: 22.r,
                      ),
                    ),
                    // Progress Indicator or New Badge
                    _buildCardIndicator(context, displayColor),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      metadata.categoryName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        color: displayColor.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Integrated Bottom Accent
                Container(
                  height: 2.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [displayColor, displayColor.withValues(alpha: 0)],
                    ),
                    borderRadius: BorderRadius.circular(1.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardIndicator(BuildContext context, Color color) {
    final currentLevel = user.unlockedLevels[subtype.name] ?? 10;
    final isNew =
        currentLevel == 1 && !user.categoryStats.containsKey(subtype.name);

    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          context.tr('quest_archive.new_badge', fallback: 'New'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Progress towards the next 10-level milestone
    final levelsCleared = currentLevel > 1 ? currentLevel - 1 : 0;
    final progress = (levelsCleared % 10) / 10.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
            value: progress == 0 ? 0.05 : progress, // 5% minimum visibility
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 2.5.r,
          ),
        ),
        Text(
          '$currentLevel',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
