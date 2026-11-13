import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Animated hero banner featuring the athletic Star Shield, glowing typography,
/// social proof ratings, and value proposition (Zero Crowns Policy compliant).
class PremiumHero extends StatelessWidget {
  const PremiumHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Athletic Star Shield Hero Icon with solid Indigo-to-Violet gradient
        Container(
              width: 76.r,
              height: 76.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: const LinearGradient(
                  colors: [AppColors.indigo500, AppColors.violet500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.violet500.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Builder(
                builder: (context) {
                  final reduceMotion = MediaQuery.disableAnimationsOf(context);
                  Widget shieldIcon = Icon(
                    LucideIcons.shieldCheck,
                    color: Colors.white,
                    size: 38.r,
                  );

                  if (!reduceMotion) {
                    shieldIcon = shieldIcon
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.94, 0.94),
                          end: const Offset(1.06, 1.06),
                          duration: 1.8.seconds,
                          curve: Curves.easeInOut,
                        );
                  }

                  return shieldIcon;
                },
              ),
            )
            .animate()
            .slideY(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 800.ms,
            )
            .fadeIn(),

        SizedBox(height: 20.h),

        // Gradient Shader Text for a 2026 athletic ultra-premium feel (1-Line Punchy Hero)
        Builder(
              builder: (context) {
                String title = context.tr(
                  'premium.hero_title',
                  fallback: 'Master English Faster',
                );
                if (title.endsWith('.') ||
                    title.endsWith('।') ||
                    title.endsWith('。')) {
                  title = title.substring(0, title.length - 1);
                }
                if (title == 'Unlimited Growth' ||
                    title == 'Unlimited Growth.' ||
                    title == 'Learn English Without Limits') {
                  title = 'Master English Faster';
                }

                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.violet500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      title,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white, // Required for ShaderMask to work
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                  ),
                );
              },
            )
            .animate()
            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 100.ms)
            .fadeIn(),

        SizedBox(height: 8.h),

        Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Builder(
                builder: (context) {
                  String subtitle = context.tr(
                    'premium.hero_subtitle',
                    fallback:
                        '20,000 ad-free levels with real US & UK voices\nEverything you need to speak with confidence',
                  );
                  if (subtitle.endsWith('.') ||
                      subtitle.endsWith('।') ||
                      subtitle.endsWith('。')) {
                    subtitle = subtitle.substring(0, subtitle.length - 1);
                  }
                  return Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark
                          ? const Color(0x99FFFFFF)
                          : const Color(0x8A000000),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      height: 1.35,
                    ),
                  );
                },
              ),
            )
            .animate()
            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 150.ms)
            .fadeIn(),

        SizedBox(height: 12.h),

        // Authentic Vowl Capability Badge (100% Real - Zero Ads & 20,000+ Levels across 100 Games)
        Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald500.withValues(alpha: 0.12)
                    : AppColors.emerald500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                  width: 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      color: AppColors.emerald500,
                      size: 13.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      context.tr(
                        'premium.hero_badge',
                        fallback: '100% AD-FREE • 20,000+ LEVELS',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.emerald400
                            : AppColors.emerald600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms)
            .fadeIn(),
      ],
    );
  }
}
