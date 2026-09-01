import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

class KidsZoneHomeHeader extends StatelessWidget {
  final String mascot;
  final String? childName;
  final bool isDark;
  
  const KidsZoneHomeHeader({
    super.key,
    required this.mascot,
    this.childName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greetingKey;
    String defaultGreeting;
    if (hour < 12) {
      greetingKey = 'kids_zone.good_morning';
      defaultGreeting = 'Good Morning! ☀️';
    } else if (hour < 17) {
      greetingKey = 'kids_zone.good_afternoon';
      defaultGreeting = 'Good Afternoon! 🌤️';
    } else {
      greetingKey = 'kids_zone.good_evening';
      defaultGreeting = 'Good Evening! 🌙';
    }

    final displayName = childName != null && childName!.isNotEmpty
        ? childName!
        : context.tr('kids_zone.little_explorer', fallback: 'Little Explorer 🌟');

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(greetingKey, fallback: defaultGreeting),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black45,
                          letterSpacing: 1,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildMascotButton(context, displayName),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotButton(BuildContext context, String displayName) {
    // Extract first name for shorter speech bubble
    final shortName = displayName.split(' ').first;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleButton(
          onTap: () => context.push(AppRouter.kidsMascotSelectionRoute),
          child: VowlMascot(
            size: 55.r,
            mascotId: mascot,
            isKidsMode: true,
            state: VowlMascotState.happy,
          ).animate().slideX(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutBack),
        ),
        Positioned(
          left: -40.w,
          top: -5.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Hi $shortName!",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
          .animate(delay: 600.ms)
          .fadeIn(duration: 400.ms)
          .scale(curve: Curves.easeOutBack)
          .then(delay: 3.seconds)
          .fadeOut(duration: 400.ms),
        ),
      ],
    );
  }
}
