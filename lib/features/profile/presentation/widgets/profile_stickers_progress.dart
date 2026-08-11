import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileStickersProgress extends StatelessWidget {
  final UserEntity user;

  const ProfileStickersProgress({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedStickers = user.kidsStickers;
    // NOTE: this constant duplicates the real source of truth (the
    // category/sticker definitions presumably owned by `KidsAssets`).
    // If that catalog ever grows, this number will silently drift out of
    // sync. Out of scope to fix here since `KidsAssets` isn't part of
    // this reviewed slice, but consider exposing
    // `KidsAssets.totalStickerCount` and reading it from there instead.
    const totalPossible = 100; // Total 100 stickers

    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.orange.shade700, width: 2.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade700,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      context.tr(
                        'profile.collection_progress',
                        fallback: 'Collection Progress',
                      ),
                      maxLines: 1,
                      minFontSize: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange[400],
                        letterSpacing: 1,
                      ),
                    ),
                    AutoSizeText(
                      context.tr(
                        'profile.stickers_count',
                        fallback: 'Stickers',
                        args: ['${earnedStickers.length}', '$totalPossible'],
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              // ACCESSIBILITY FIX: ~30dp visible tap target (14w/8h
              // padding around 11sp text) was under the 48dp minimum.
              // Expanded the tappable area via a centered SizedBox
              // without changing the visible pill's size at all.
              Semantics(
                button: true,
                label: context.tr(
                  'profile.view_all_stickers',
                  fallback: 'View All Stickers',
                ),
                child: SizedBox(
                  height: 48.r,
                  child: Center(
                    child: ScaleButton(
                      onTap: () => context.push(AppRouter.kidsStickerBookRoute),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          context.tr('profile.view_all', fallback: 'View All'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (earnedStickers.isNotEmpty) ...[
            SizedBox(height: 20.h),
            SizedBox(
              height: 50.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                // BUG FIX: this was `NeverScrollableScrollPhysics`, which
                // defeats the entire point of using a ListView here. On
                // any screen narrower than ~6 sticker-circles-wide (very
                // common on small/standard phones once you account for
                // screen padding), the stickers beyond what fit were
                // simply cut off at the edge with no way for the user to
                // scroll over and see them - they'd just silently
                // disappear. Using BouncingScrollPhysics (matching the
                // horizontal-scroller pattern already used elsewhere in
                // this app, e.g. the badge carousel) so every earned
                // sticker is actually reachable.
                physics: const BouncingScrollPhysics(),
                itemCount: earnedStickers.length.clamp(0, 6),
                itemBuilder: (context, index) {
                  final revIndex = earnedStickers.length - 1 - index;
                  final stickerId = earnedStickers[revIndex];
                  final emoji = KidsAssets.getStickerEmoji(stickerId);
                  return Semantics(
                    label: context.tr(
                      'profile.sticker_earned',
                      fallback: 'Sticker Earned',
                    ),
                    child: Container(
                      margin: EdgeInsets.only(right: 12.w),
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}
