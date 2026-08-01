import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SynonymInstructionHeader extends StatelessWidget {
  final Color color;
  final String instruction;

  const SynonymInstructionHeader({
    super.key,
    required this.color,
    this.instruction = "WARP THE SYNONYM SHARD",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cyclone_rounded, size: 16.r, color: color),
              SizedBox(width: 10.w),
              Text(
                instruction.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 3.seconds,
          color: Colors.white.withValues(alpha: 0.3),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
  }
}
