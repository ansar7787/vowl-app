import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

class TranslationHomeCard extends StatelessWidget {
  final bool isDark;

  const TranslationHomeCard({super.key, required this.isDark});

  void _launchTranslate(BuildContext context) {
    di.sl<HapticService>().light();
    context.push(AppRouter.translateRoute);
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
        borderRadius: BorderRadius.circular(20.r),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 44.r,
                height: 44.r,
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
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 14.w),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            context.tr(
                              'home.translation_title',
                              fallback: 'Instant Translate',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            minFontSize: 8,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    AutoSizeText(
                      context.tr(
                        'home.translation_subtitle',
                        fallback: 'Translate words & phrases offline for free',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      minFontSize: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right_rounded,
                color: primaryAccent.withValues(alpha: 0.5),
                size: 24.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
