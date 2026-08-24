import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

class KidsZoneHomeHeader extends StatelessWidget {
  final String mascot;
  final bool isDark;
  const KidsZoneHomeHeader({
    super.key,
    required this.mascot,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
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
                        context.tr('kids_zone.welcome_back', fallback: 'Welcome Back!'),
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
                              context.tr('kids_zone.little_explorer', fallback: 'Little Explorer 🌟'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildMascotButton(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              context.tr('kids_zone.learning_adventures', fallback: 'LEARNING ADVENTURES'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF6366F1),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotButton(BuildContext context) {
    return ScaleButton(
      onTap: () => context.push(AppRouter.kidsMascotSelectionRoute),
      child: VowlMascot(size: 40.r, isKidsMode: true),
    );
  }
}
