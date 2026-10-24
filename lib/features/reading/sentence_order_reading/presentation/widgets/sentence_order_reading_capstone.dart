import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Capstone submission button allowing users to lock in their sentence order.
class SentenceOrderReadingCapstone extends StatelessWidget {
  /// Theme accent color applied to button background.
  final Color color;

  /// Callback invoked when the capstone button is tapped.
  final VoidCallback onTap;

  /// Button text label.
  final String label;

  /// Creates a [SentenceOrderReadingCapstone] widget.
  const SentenceOrderReadingCapstone({
    super.key,
    required this.color,
    required this.onTap,
    this.label = 'Check Order',
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 22.r),
              SizedBox(width: 10.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
