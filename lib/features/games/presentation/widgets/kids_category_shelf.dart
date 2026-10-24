import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/kids_zone/domain/services/kids_game_helper.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorffa000 = Color(0xFFFFA000);
  static const Color colorc0c0c0 = Color(0xFFC0C0C0);
  static const Color colorcd7f32 = Color(0xFFCD7F32);
}

/// Horizontal carousel shelf widget displaying all available Kids Zone games
/// with user progression, star ratings, and direct routing.
class KidsCategoryShelf extends StatefulWidget {
  const KidsCategoryShelf({super.key, required this.user});

  /// The active authenticated user session whose progression is displayed.
  final UserEntity user;

  @override
  State<KidsCategoryShelf> createState() => _KidsCategoryShelfState();
}

class _KidsCategoryShelfState extends State<KidsCategoryShelf>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final games = KidsGameHelper.allGames;

    return SizedBox(
      height: 215.h,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: RepaintBoundary(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            addAutomaticKeepAlives: false,
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: _KidsGameEntryCard(
                  metadata: games[index],
                  user: widget.user,
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
    final color = metadata.color;
    final displayColor = color;
    final title = metadata.gridTitle; // e.g. "ABC"
    final subtitle = metadata.subtitle; // e.g. "Letters & Phonics"
    final icon = metadata.icon;

    return Semantics(
      button: true,
      label: '$title, Kids Game',
      child: ScaleButton(
        onTap: () {
          context.push(
            '/kids/map/${metadata.gameType}',
            extra: {'title': metadata.fullTitle, 'primaryColor': color},
          );
        },
        child: ExcludeSemantics(
          child: GlassTile(
            width: 150.w,
            borderRadius: BorderRadius.circular(30.r),
            padding: EdgeInsets.all(18.r),
            usePremiumStyle: true,
            showShadow: false,
            blur: 0, // PERF: Disable BackdropFilter in scroll lists
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
                      child: Icon(icon, color: displayColor, size: 22.r),
                    ),
                    _buildCardIndicator(context, displayColor),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
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
    final maxLevels = CurriculumManifest.getLevels(metadata.gameType);
    final levelsCleared = (user.completedLevels[metadata.gameType]?.length ?? 0)
        .clamp(0, maxLevels);
    final isMastered = levelsCleared >= maxLevels;
    final currentLevel = isMastered
        ? maxLevels
        : (user.unlockedLevels[metadata.gameType] ?? 1).clamp(1, maxLevels);
    final isNew =
        levelsCleared == 0 &&
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
            context.tr('quest_archive.new_badge', fallback: 'NEW'),
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

    // Mastery completion state
    if (isMastered) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [IllustrationColors.premiumGold, _LocalPalette.colorffa000],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: IllustrationColors.premiumGold.withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: 16.r),
      );
    }

    // Progress tier ring colors
    Color ringColor = color;
    if (levelsCleared >= 100) {
      ringColor = IllustrationColors.premiumGold;
    } else if (levelsCleared >= 50) {
      ringColor = _LocalPalette.colorc0c0c0;
    } else if (levelsCleared >= 25) {
      ringColor = _LocalPalette.colorcd7f32;
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
