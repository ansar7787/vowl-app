import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class KidsRoomExitDialog extends StatelessWidget {
  final VoidCallback onExit;

  const KidsRoomExitDialog({
    super.key,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280.w,
          child: GlassTile(
            padding: EdgeInsets.all(20.r),
            borderRadius: BorderRadius.circular(25.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "LEAVING SO SOON?",
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Your buddy will miss you! Stay a bit longer to earn more coins? ❤️",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 11.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ScaleButton(
                        onTap: onExit,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Center(
                            child: Text(
                              "EXIT",
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ScaleButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "STAY",
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontSize: 12.sp,
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
          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn(),
        ),
      ),
    );
  }

  static void show(BuildContext context, {required VoidCallback onExit}) {
    showDialog(
      context: context,
      builder: (context) => KidsRoomExitDialog(onExit: onExit),
    );
  }
}
