import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/kids_game_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';

class KidsCategoryShelf extends StatelessWidget {
  const KidsCategoryShelf({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final games = KidsGameHelper.allGames;
    
    return SizedBox(
      height: 215.h,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: RepaintBoundary(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: _KidsGameEntryCard(
                  metadata: games[index],
                  user: user,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KidsGameEntryCard extends StatelessWidget {
  const _KidsGameEntryCard({required this.metadata, required this.user});

  final KidsGameMetadata metadata;
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = metadata.color;
    final displayColor = isDark
        ? color
        : HSLColor.fromColor(color).withLightness(0.4).toColor();
    final title = metadata.fullTitle;
    final subtitle = metadata.subtitle;
    final icon = metadata.icon;

    return Semantics(
      button: true,
      label: '$title, Kids Game',
      child: ScaleButton(
        onTap: () {
          context.push(
            '/kids/map/${metadata.gameType}',
            extra: {
              'title': title,
              'primaryColor': color,
            },
          );
        },
        child: ExcludeSemantics(
          child: GlassTile(
            width: 150.w,
            borderRadius: BorderRadius.circular(30.r),
            padding: EdgeInsets.all(18.r),
            usePremiumStyle: true,
            showShadow: false,
            glassOpacity: 0.15,
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
                        icon,
                        color: displayColor,
                        size: 22.r,
                      ),
                    ),
                    _buildCardIndicator(context, displayColor),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      maxLines: 2,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w900,
                          color: displayColor.withValues(alpha: 0.7),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
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
    final currentLevel = user.unlockedLevels[metadata.gameType] ?? 1;
    final isNew = currentLevel == 1 &&
        (user.completedLevels[metadata.gameType]?.isEmpty ?? true);

    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('quest_archive.new_badge', fallback: 'New'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 8.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    final levelsCleared = currentLevel > 1 ? currentLevel - 1 : 0;
    final progress = (levelsCleared % 10) / 10.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
            value: progress == 0 ? 0.05 : progress,
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
