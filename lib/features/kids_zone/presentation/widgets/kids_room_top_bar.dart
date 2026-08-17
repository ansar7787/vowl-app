import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_mood_indicator.dart'
    as import_indicator;

class KidsRoomTopBar extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onBack;

  const KidsRoomTopBar({super.key, required this.user, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          ScaleButton(
            onTap: onBack,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white).withValues(
                      alpha: isDark ? 0.3 : 0.6,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
                      width: 2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    size: 20.sp,
                  ),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.3 : 0.6,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.8),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: Colors.amberAccent.shade400,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "${user.kidsCoins}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.amberAccent.shade100
                      : Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
