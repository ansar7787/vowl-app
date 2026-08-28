import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
            addAutomaticKeepAlives: false,
            itemCount: subtypes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: _GameEntryCard(subtype: subtypes[index], user: user),
              )
                  .animate(delay: (50 * index).ms)
                  .fade(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                    duration: 500.ms,
                  )
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    duration: 400.ms,
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
            showShadow: false,
            blur: 0, // PERF: Disable BackdropFilter in scroll lists — 10 shelves × 4 visible cards = 40+ simultaneous blurs
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
                    AutoSizeText(
                      metadata.title,
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
                        metadata.categoryName.toUpperCase(),
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
    final levelsCleared = user.completedLevels[subtype.name]?.length ?? 0;
    final currentLevel = levelsCleared + 1;
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

    // Mastery completion state — level 200 reached
    if (levelsCleared >= 200) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: 16.r),
      );
    }

    // Progress tier ring colors: Bronze 25+, Silver 50+, Gold 100+
    Color ringColor = color;
    if (levelsCleared >= 100) {
      ringColor = const Color(0xFFFFD700); // Gold
    } else if (levelsCleared >= 50) {
      ringColor = const Color(0xFFC0C0C0); // Silver
    } else if (levelsCleared >= 25) {
      ringColor = const Color(0xFFCD7F32); // Bronze
    }

    final progress = (levelsCleared % 10) / 10.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 26.r,
          height: 26.r,
          child: CircularProgressIndicator(
            value: progress == 0 ? 0.05 : progress,
            backgroundColor: ringColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            strokeWidth: 2.5.r,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '$currentLevel',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: ringColor,
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
