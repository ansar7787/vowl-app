import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class KidsRoomExitDialog extends StatelessWidget {
  final VoidCallback onExit;
  final UserEntity user;

  const KidsRoomExitDialog({
    super.key,
    required this.onExit,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 320.w,
          child:
              Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(
                        color: const Color(0xFFA855F7),
                        width: 4.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7E22CE),
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "LEAVING SO SOON?",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF7E22CE),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          _getMoodMessage(user.kidsBuddyMood),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            color: Colors.black54,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: ScaleButton(
                                onTap: onExit,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 3.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        offset: Offset(0, 4.h),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "EXIT",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ScaleButton(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: const Color(0xFF047857),
                                      width: 3.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF047857),
                                        offset: Offset(0, 4.h),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "STAY",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .scale(curve: Curves.easeOutBack, duration: 400.ms)
                  .fadeIn(),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required UserEntity user,
    required VoidCallback onExit,
  }) {
    showDialog(
      context: context,
      builder: (context) => KidsRoomExitDialog(user: user, onExit: onExit),
    );
  }

  String _getMoodMessage(String mood) {
    switch (mood) {
      case 'hungry':
        return "I'm still so hungry! Please don't leave yet! 🥺";
      case 'sleepy':
        return "I'm so sleepy... tuck me in before you go? 😴";
      case 'bored':
        return "But we haven't played yet! Stay a bit longer? 😒";
      case 'excited':
        return "Aww, I was having so much fun! See you soon! 🤩";
      case 'happy':
      default:
        return "Your buddy will miss you! Stay a bit longer to earn more coins? ❤️";
    }
  }
}
