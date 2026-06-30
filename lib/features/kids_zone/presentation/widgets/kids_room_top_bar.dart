import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';

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
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.grey.shade300, width: 3.w),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, offset: Offset(0, 4.h)),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.grey.shade600,
                    size: 20.sp,
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFBBF24), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706),
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            KidsAssets.mascotMap[user.kidsMascot] ?? "🦉", 
            style: TextStyle(fontSize: 18.sp)
          ),
          SizedBox(width: 8.w),
          Text(
            "BUDDY ROOM",
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFD97706),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF10B981), width: 3.w),
        boxShadow: [
          BoxShadow(color: const Color(0xFF047857), offset: Offset(0, 4.h)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_rounded, color: const Color(0xFF10B981), size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            "${user.kidsCoins}",
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoveMeter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFEC4899), width: 3.w),
        boxShadow: [
          BoxShadow(color: const Color(0xFFBE185D), offset: Offset(0, 4.h)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("❤️", style: TextStyle(fontSize: 18.sp))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          SizedBox(width: 12.w),
          Stack(
            children: [
              Container(
                width: 120.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300, width: 2.w),
                ),
              ),
              AnimatedContainer(
                duration: 500.ms,
                width: 120.w * happiness,
                height: 12.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Text("${(happiness * 100).toInt()}%", style: TextStyle(fontFamily: 'Outfit', fontSize: 12.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48))),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }
}
