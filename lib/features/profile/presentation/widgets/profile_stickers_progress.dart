import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProfileStickersProgress extends StatelessWidget {
  final UserEntity user;

  const ProfileStickersProgress({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedStickers = user.kidsStickers;
    const totalPossible = 88; // 22 categories * 4 stickers

    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.orange,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTION PROGRESS',
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange[400],
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${earnedStickers.length} / $totalPossible Stickers',
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ScaleButton(
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
                    'VIEW ALL',
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: earnedStickers.length.clamp(0, 6),
                itemBuilder: (context, index) {
                  final revIndex = earnedStickers.length - 1 - index;
                  final stickerId = earnedStickers[revIndex];
                  final emoji = KidsAssets.getStickerEmoji(stickerId);
                  return Container(
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
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(height: 12.h),
            Text(
              'Start your collection in Kids Zone!',
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 12.sp,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
