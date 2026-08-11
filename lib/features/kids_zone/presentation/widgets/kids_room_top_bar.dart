import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_mood_indicator.dart' as import_indicator;

class KidsRoomTopBar extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onBack;

  const KidsRoomTopBar({
    super.key,
    required this.user,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
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
                      BoxShadow(
                        color: Colors.grey.shade300,
                        offset: Offset(0, 4.h),
                      ),
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
              import_indicator.KidsRoomMoodIndicator(user: user),
              const Spacer(),
              _buildCurrencyBadge(context),
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
        border: Border.all(color: Colors.amber, width: 3.w),
        boxShadow: [
          BoxShadow(color: Colors.amber.shade700, offset: Offset(0, 4.h)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 24.sp),
          SizedBox(width: 8.w),
          Text(
            "${user.kidsCoins}",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

}
