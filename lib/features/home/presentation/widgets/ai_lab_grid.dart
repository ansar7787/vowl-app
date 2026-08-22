import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class AiLabGrid extends StatelessWidget {
  const AiLabGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          _buildLabCard(
            context: context,
            title: 'Photo Vocab',
            subtitle: 'Learn from images',
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFF10B981),
            route: AppRouter.photoVocabularyRoute,
          ),
          SizedBox(width: 16.w),
          _buildLabCard(
            context: context,
            title: 'Scan & Learn',
            subtitle: 'Read text alive',
            icon: Icons.document_scanner_rounded,
            color: const Color(0xFF3B82F6),
            route: AppRouter.scanAndLearnRoute,
          ),
          SizedBox(width: 16.w),
          _buildLabCard(
            context: context,
            title: 'Word Snap',
            subtitle: 'Quick memory',
            icon: Icons.extension_rounded,
            color: const Color(0xFFF59E0B),
            route: '/word-snap',
          ),
          SizedBox(width: 16.w),
          _buildLabCard(
            context: context,
            title: 'Word Mixer',
            subtitle: 'Creative combos',
            icon: Icons.sort_by_alpha_rounded,
            color: const Color(0xFFA855F7),
            route: '/word-mixer',
          ),
        ],
      ),
    );
  }

  Widget _buildLabCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    bool requiresAd = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () {
        if (!requiresAd) {
          context.push(route);
          return;
        }

        final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
        if (isPremium) {
          context.push(route);
          return;
        }

        final adService = di.sl<AdService>();
        adService.showRewardedAd(
          context: context,
          isPremium: isPremium,
          childSafe: false,
          onUserEarnedReward: (_) {
            context.push(route);
          },
          onDismissed: () {},
        );
      },
      child: GlassTile(
        showShadow: false,
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.r),
        child: SizedBox(
          width: 200.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28.r),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
