import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_feature_card.dart';

class ProfileStickersProgress extends StatelessWidget {
  final UserEntity user;

  const ProfileStickersProgress({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earnedStickers = user.kidsStickers;
    const totalPossible = 100;

    return ProfileFeatureCard(
      iconContent: Icon(
        Icons.stars_rounded,
        color: Colors.white,
        size: 24.r,
      ),
      color: Colors.orange.shade400,
      shadowColor: Colors.orange.shade700,
      title: context.tr(
        'profile.stickers_count',
        fallback: '{0}/{1} Stickers',
        args: ['${earnedStickers.length}', '$totalPossible'],
      ),
      subtitle: context.tr(
        'profile.collection_progress',
        fallback: 'Collection Progress',
      ),
      onTap: () => context.push(AppRouter.kidsStickerBookRoute),
      bottomContent: earnedStickers.isNotEmpty
          ? SizedBox(
              height: 50.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
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
            )
          : null,
    );
  }
}
