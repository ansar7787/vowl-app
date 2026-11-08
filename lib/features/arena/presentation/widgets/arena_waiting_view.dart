import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// SUSPENSE WAITING VIEW (Round 5 Complete)
class ArenaWaitingView extends StatelessWidget {
  final ArenaDuelState state;
  final UserEntity user;
  final String rivalName;
  final String? rivalPhoto;
  final bool isDark;
  final bool isMidnight;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  const ArenaWaitingView({
    super.key,
    required this.state,
    required this.user,
    required this.rivalName,
    this.rivalPhoto,
    required this.isDark,
    required this.isMidnight,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.compact,
        vertical: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.swords,
                    size: 13.sp,
                    color: AppColors.indigo500,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'PENTATHLON MATCH COMPLETE',
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.indigo500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'WAITING FOR RIVAL TO FINISH',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 19.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: textPrimary,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'All 5 rounds submitted. Rival is concluding their match.',
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),

          SizedBox(height: 24.h),

          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: isMidnight
                  ? AppColors.midnightSurface
                  : (isDark ? AppColors.slate800 : Colors.white),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // User Locked Side
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 50.r,
                            height: 50.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.indigo500,
                                width: 2,
                              ),
                              image: user.photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(user.photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: AppColors.indigo500.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: user.photoUrl == null
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      user.safeDisplayName.isNotEmpty
                                          ? user.safeDisplayName[0]
                                                .toUpperCase()
                                          : 'Y',
                                      softWrap: true,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.indigo500,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(height: 8.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              user.safeDisplayName,
                              softWrap: true,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald500.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'LOCKED: ${state.myScore} PTS',
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // VS Divider
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                              ? AppColors.slate700
                              : AppColors.slate200),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'VS',
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // Rival Side
                    Expanded(
                      child: Column(
                        children: [
                          if ((state.session?.isGhostRival == true) &&
                              (rivalPhoto == null || rivalPhoto!.isEmpty))
                            Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.teal500,
                                    AppColors.blue500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/vowly_head.webp',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.rose500,
                                  width: 2,
                                ),
                                image:
                                    rivalPhoto != null && rivalPhoto!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(rivalPhoto!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: AppColors.rose500.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: rivalPhoto == null || rivalPhoto!.isEmpty
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        rivalName.isNotEmpty
                                            ? rivalName[0].toUpperCase()
                                            : 'R',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.rose500,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          SizedBox(height: 8.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              rivalName,
                              softWrap: true,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'RIVAL: ${state.rivalScore} PTS',
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.amber500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // Modern Linear Indicator (Never 2019 Spinner)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    minHeight: 4.h,
                    backgroundColor: isDark
                        ? AppColors.slate700
                        : AppColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.indigo500,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Waiting for rival to finish...',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Speed Tiebreaker Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : AppColors.slate50,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.zap, size: 16.sp, color: AppColors.amber500),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speed Tiebreaker Active',
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'If points tie, the faster player wins. Every second counts!',
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 11.sp,
                          height: 1.35,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
