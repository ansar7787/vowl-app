import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class DetailSpotlightPrompt extends StatelessWidget {
  final bool isAnswered;
  final String detail;
  final Color color;

  const DetailSpotlightPrompt({
    super.key,
    required this.isAnswered,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      borderRadius: BorderRadius.circular(30.r),
      child: Text(
        isAnswered
            ? "TARGET: ${detail.toUpperCase()}"
            : "SCAN FOR AUDITORY TARGET",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
