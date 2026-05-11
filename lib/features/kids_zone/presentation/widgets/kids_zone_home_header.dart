import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

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
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black45,
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Little Explorer 🌟',
                          style: GoogleFonts.outfit(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        _buildMascotButton(context),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Text(
              'LEARNING ADVENTURES',
              style: GoogleFonts.outfit(
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
    return GestureDetector(
      onLongPress: () {
        di.sl<HapticService>().heavy();
        context.push(AppRouter.kidsAdminRoute);
      },
      child: ScaleButton(
        onTap: () => context.push(AppRouter.kidsMascotSelectionRoute),
        child: VowlMascot(
          size: 40.r,
          isKidsMode: true,
        ),
      ),
    );
  }
}
