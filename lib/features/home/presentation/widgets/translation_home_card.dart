import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class TranslationHomeCard extends StatelessWidget {
  final bool isDark;
  
  const TranslationHomeCard({super.key, required this.isDark});

  void _launchTranslate(BuildContext context) {
    di.sl<HapticService>().light();

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    if (isPremium) {
      context.push(AppRouter.translateRoute);
    } else {
      di.sl<AdService>().showRewardedAd(
        context: context,
        isPremium: false,
        onUserEarnedReward: (_) {},
        onDismissed: () {
          context.push(AppRouter.translateRoute);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryAccent = const Color(0xFF10B981);
    final Color secondaryAccent = const Color(0xFF059669);

    return GestureDetector(
      onTap: () => _launchTranslate(context),
      child: GlassTile(
        padding: EdgeInsets.zero,
        borderColor: primaryAccent.withValues(alpha: 0.3),
        borderWidth: 1.5,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      primaryAccent.withValues(alpha: 0.15),
                      secondaryAccent.withValues(alpha: 0.05),
                    ]
                  : [
                      primaryAccent.withValues(alpha: 0.1),
                      secondaryAccent.withValues(alpha: 0.02),
                    ],
            ),
          ),
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryAccent, secondaryAccent],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
              ),
              SizedBox(width: 16.w),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            context.tr('home.translation_title', fallback: 'Instant Translate'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    AutoSizeText(
                      context.tr('home.translation_subtitle', fallback: 'Translate words & phrases offline for free'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
