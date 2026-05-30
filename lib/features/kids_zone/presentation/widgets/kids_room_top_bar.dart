import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class KidsRoomTopBar extends StatelessWidget {
  final UserEntity user;
  final double happiness;
  final VoidCallback onBack;

  const KidsRoomTopBar({
    super.key,
    required this.user,
    required this.happiness,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            children: [
              ScaleButton(
                onTap: onBack,
                child: GlassTile(
                  padding: EdgeInsets.all(10.r),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    size: 18.sp,
                  ),
                ),
              ),
              const Spacer(),
              _buildTopStatusCapsule(context),
              const Spacer(),
              _buildCurrencyBadge(context),
            ],
          ),
          SizedBox(height: 12.h),
          _buildCompactLoveMeter(),
        ],
      ),
    );
  }

  Widget _buildTopStatusCapsule(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      borderRadius: BorderRadius.circular(20.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("🦉", style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 8.w),
          Text(
            "BUDDY ROOM",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      borderRadius: BorderRadius.circular(20.r),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            "${user.kidsCoins}",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoveMeter() {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      borderRadius: BorderRadius.circular(30.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("❤️", style: TextStyle(fontSize: 14.sp))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          SizedBox(width: 8.w),
          Stack(
            children: [
              Container(
                width: 100.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              AnimatedContainer(
                duration: 500.ms,
                width: 100.w * happiness,
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.3), blurRadius: 4)],
                ),
              ),
            ],
          ),
          SizedBox(width: 6.w),
          Text("${(happiness * 100).toInt()}%", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48))),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }
}
