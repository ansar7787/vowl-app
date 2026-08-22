import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class AiLabGrid extends StatelessWidget {
  const AiLabGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science_rounded, color: const Color(0xFF6366F1), size: 24.r),
            SizedBox(width: 8.w),
            Text(
              context.tr('home.ai_lab_title', fallback: 'AI Lab & Challenges'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 270.h, // Increased to prevent vertical overflow on larger text scalers
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildBentoCard(
                        context: context,
                        title: 'Photo Vocab',
                        icon: Icons.camera_alt_rounded,
                        color: const Color(0xFF10B981),
                        route: AppRouter.photoVocabularyRoute,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: _buildBentoCard(
                        context: context,
                        title: 'Word Snap',
                        icon: Icons.extension_rounded,
                        color: const Color(0xFFF59E0B),
                        route: '/word-snap',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildBentoCard(
                        context: context,
                        title: 'Scan & Learn',
                        icon: Icons.document_scanner_rounded,
                        color: const Color(0xFF3B82F6),
                        route: AppRouter.scanAndLearnRoute,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: _buildBentoCard(
                        context: context,
                        title: 'Word Mixer',
                        icon: Icons.sort_by_alpha_rounded,
                        color: const Color(0xFFA855F7),
                        route: '/word-mixer',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required BuildContext context,
    required String title,
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
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(12.r), // Reduced padding to allow more text room
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28.r),
              ),
              SizedBox(height: 12.h), // Replaced Spacer with fixed height
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center, // Center text box
                child: Text(
                  title,
                  textAlign: TextAlign.center, // Center text multiline
                  maxLines: 1, // Enforce single line
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
