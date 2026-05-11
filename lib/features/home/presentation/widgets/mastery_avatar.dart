import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class MasteryAvatar extends StatelessWidget {
  const MasteryAvatar({super.key, required this.user, required this.progress});

  final UserEntity user;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80.r,
          height: 80.r,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5.r,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            color: const Color(0xFF2563EB),
            strokeCap: StrokeCap.round,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        Container(
          width: 62.r,
          height: 62.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: user.photoUrl != null
                ? ShimmerImage(imageUrl: user.photoUrl!)
                : Icon(
                    Icons.face_retouching_natural_rounded,
                    color: const Color(0xFF2563EB),
                    size: 32.r,
                  ),
          ),
        ),
      ],
    );
  }
}
